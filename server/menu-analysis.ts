import type { MenuItem } from '../types';

export type MenuAnalysisProvider = 'openrouter';

export type MenuAnalysisEnvironment = Readonly<Record<string, string | undefined>>;

export type NormalizedImage = {
  data: string;
  mimeType: string;
  sizeBytes: number;
};

export type MenuAnalysisInput = {
  imageData: string;
  mimeType?: string;
};

export type MenuAnalysisResult = {
  provider: MenuAnalysisProvider;
  items: MenuItem[];
};

export type MenuAnalysisErrorCode =
  | 'invalid_request'
  | 'invalid_image'
  | 'invalid_provider'
  | 'auth_unconfigured'
  | 'unauthorized'
  | 'provider_unconfigured'
  | 'provider_request_failed'
  | 'provider_timeout'
  | 'provider_invalid_response';

export class MenuAnalysisError extends Error {
  constructor(
    public readonly code: MenuAnalysisErrorCode,
    public readonly status: number,
    message: string,
  ) {
    super(message);
    this.name = 'MenuAnalysisError';
  }
}

const DEFAULT_OPENROUTER_MODEL = 'nex-agi/nex-n2-mini';
const OPENROUTER_URL = 'https://openrouter.ai/api/v1/chat/completions';
const MAX_IMAGE_BYTES = 6 * 1024 * 1024;
const MAX_IMAGE_BASE64_CHARS = Math.ceil(MAX_IMAGE_BYTES / 3) * 4;
const SUPPORTED_IMAGE_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp']);

export const MENU_ANALYSIS_PROMPT = [
  'You are the menu-reading assistant for Kitchen Diary.',
  'Read the supplied restaurant menu or recipe image and identify every legible dish name.',
  'Do not invent or complete names that are not visible. Ignore prices, ingredients, and non-food text.',
  'Descriptions are optional: include one only when the menu itself clearly states it. Never infer ingredients, allergens, dietary labels, nutrition, preparation, or prices.',
  'Return only valid JSON in this shape: {"items":[{"name":"Dish name","description":"Short neutral description if clear from the menu, otherwise empty"}]}',
  'Keep at most 20 items and keep each description under 240 characters.',
].join(' ');

type ProviderConfig = {
  provider: MenuAnalysisProvider;
  apiKey: string;
  model: string;
};

const envValue = (environment: MenuAnalysisEnvironment, key: string): string =>
  environment[key]?.trim() ?? '';

export const resolveProvider = (
  environment: MenuAnalysisEnvironment = process.env,
): ProviderConfig | null => {
  const openRouterKey = envValue(environment, 'OPENROUTER_API_KEY');
  if (openRouterKey) {
    return {
      provider: 'openrouter',
      apiKey: openRouterKey,
      model: DEFAULT_OPENROUTER_MODEL,
    };
  }

  return null;
};

export const normalizeImageData = (
  imageData: string,
  mimeType = 'image/jpeg',
): NormalizedImage => {
  if (typeof imageData !== 'string' || !imageData.trim()) {
    throw new MenuAnalysisError('invalid_image', 400, 'A base64 menu image is required.');
  }

  const trimmed = imageData.trim();
  const dataUrlMatch = /^data:([^;,]+);base64,(.*)$/s.exec(trimmed);
  const data = (dataUrlMatch?.[2] ?? trimmed).trim();
  const resolvedMimeType = (dataUrlMatch?.[1] ?? mimeType).trim().toLowerCase();

  if (!SUPPORTED_IMAGE_TYPES.has(resolvedMimeType)) {
    throw new MenuAnalysisError(
      'invalid_image',
      400,
      'Use a JPEG, PNG, or WebP menu image.',
    );
  }

  if (
    !data ||
    data.length > MAX_IMAGE_BASE64_CHARS ||
    data.length % 4 === 1 ||
    !/^[A-Za-z0-9+/]*={0,2}$/.test(data)
  ) {
    throw new MenuAnalysisError('invalid_image', 400, 'The menu image is not valid base64 data.');
  }

  const sizeBytes = Buffer.from(data, 'base64').byteLength;
  if (sizeBytes === 0 || sizeBytes > MAX_IMAGE_BYTES) {
    throw new MenuAnalysisError('invalid_image', 400, 'The menu image is too large or empty.');
  }

  return { data, mimeType: resolvedMimeType, sizeBytes };
};

const asRecord = (value: unknown): Record<string, unknown> | null =>
  value !== null && typeof value === 'object' && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;

const asText = (value: unknown): string => (typeof value === 'string' ? value.trim() : '');

const candidateJsonValues = (text: string): string[] => {
  const normalized = text
    .trim()
    .replace(/^```(?:json)?\s*/i, '')
    .replace(/\s*```$/i, '')
    .trim();
  const candidates = [normalized];
  const objectStart = normalized.indexOf('{');
  const objectEnd = normalized.lastIndexOf('}');
  if (objectStart >= 0 && objectEnd > objectStart) {
    candidates.push(normalized.slice(objectStart, objectEnd + 1));
  }
  const arrayStart = normalized.indexOf('[');
  const arrayEnd = normalized.lastIndexOf(']');
  if (arrayStart >= 0 && arrayEnd > arrayStart) {
    candidates.push(normalized.slice(arrayStart, arrayEnd + 1));
  }
  return [...new Set(candidates.filter(Boolean))];
};

const menuArrayFromValue = (value: unknown): unknown[] => {
  if (Array.isArray(value)) return value;
  const record = asRecord(value);
  if (!record) return [];
  for (const key of ['items', 'menuItems', 'dishes']) {
    if (Array.isArray(record[key])) return record[key] as unknown[];
  }
  return [];
};

export const parseMenuItems = (raw: unknown): MenuItem[] => {
  const parsedValues: unknown[] = [];
  if (typeof raw === 'string') {
    for (const candidate of candidateJsonValues(raw)) {
      try {
        parsedValues.push(JSON.parse(candidate) as unknown);
      } catch {
        // Try the next bounded JSON candidate.
      }
    }
  } else {
    parsedValues.push(raw);
  }

  const seen = new Set<string>();
  const items: MenuItem[] = [];
  for (const parsed of parsedValues) {
    for (const value of menuArrayFromValue(parsed)) {
      const record = asRecord(value);
      const name = asText(
        typeof value === 'string'
          ? value
          : record?.name ?? record?.title ?? record?.dish,
      ).slice(0, 120);
      if (!name) continue;

      const key = name.toLowerCase();
      if (seen.has(key)) continue;
      seen.add(key);

      const description = asText(
        record?.description ?? record?.desc ?? record?.details,
      ).slice(0, 240);
      items.push(description ? { name, description } : { name });
      if (items.length === 20) return items;
    }
  }
  return items;
};

const openRouterText = (payload: unknown): string => {
  const root = asRecord(payload);
  const choices = Array.isArray(root?.choices) ? root.choices : [];
  const message = asRecord(asRecord(choices[0])?.message);
  const content = message?.content;
  if (typeof content === 'string') return content;
  if (Array.isArray(content)) {
    return content
      .map((part) => asText(asRecord(part)?.text))
      .filter(Boolean)
      .join('\n');
  }
  return '';
};

const providerRequest = (
  config: ProviderConfig,
  image: NormalizedImage,
  environment: MenuAnalysisEnvironment,
): { url: string; init: RequestInit } => {
    const siteUrl = envValue(environment, 'OPENROUTER_SITE_URL');
    return {
      url: OPENROUTER_URL,
      init: {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${config.apiKey}`,
          'Content-Type': 'application/json',
          ...(siteUrl ? { 'HTTP-Referer': siteUrl } : {}),
          'X-Title': 'Kitchen Diary',
        },
        body: JSON.stringify({
          model: config.model,
          provider: { sort: 'price', allow_fallbacks: false },
          messages: [
            {
              role: 'user',
              content: [
                { type: 'text', text: MENU_ANALYSIS_PROMPT },
                {
                  type: 'image_url',
                  image_url: { url: `data:${image.mimeType};base64,${image.data}` },
                },
              ],
            },
          ],
          temperature: 0.1,
          max_tokens: 900,
        }),
      },
    };
};

export const analyzeMenuImageWithProvider = async (
  input: MenuAnalysisInput,
  environment: MenuAnalysisEnvironment = process.env,
  fetcher: typeof fetch = fetch,
): Promise<MenuAnalysisResult> => {
  const config = resolveProvider(environment);
  if (!config) {
    throw new MenuAnalysisError(
      'provider_unconfigured',
      503,
      'AI menu analysis is not configured. The built-in recipe catalog remains available.',
    );
  }

  const image = normalizeImageData(input.imageData, input.mimeType);
  const request = providerRequest(config, image, environment);
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 20_000);

  let response: Response;
  try {
    response = await fetcher(request.url, { ...request.init, signal: controller.signal });
  } catch (error) {
    if (error instanceof MenuAnalysisError) throw error;
    if (error instanceof Error && error.name === 'AbortError') {
      throw new MenuAnalysisError(
        'provider_timeout',
        504,
        'Menu image analysis timed out. Try again with a smaller image.',
      );
    }
    throw new MenuAnalysisError(
      'provider_request_failed',
      502,
      'Menu image analysis is temporarily unavailable.',
    );
  } finally {
    clearTimeout(timeoutId);
  }

  if (!response.ok) {
    throw new MenuAnalysisError(
      'provider_request_failed',
      502,
      'Menu image analysis is temporarily unavailable.',
    );
  }

  let payload: unknown;
  try {
    payload = await response.json();
  } catch {
    throw new MenuAnalysisError(
      'provider_invalid_response',
      502,
      'The menu analysis provider returned an unreadable response.',
    );
  }

  const text = openRouterText(payload);
  const items = parseMenuItems(text);
  return { provider: config.provider, items };
};
