import {
  MenuAnalysisError,
  resolveProvider,
  type MenuAnalysisEnvironment,
} from './menu-analysis.js';

export type ChefChatRole = 'user' | 'assistant';

export type ChefChatMessage = {
  role: ChefChatRole;
  content: string;
};

export type ChefChatInput = {
  message: string;
  pantry?: string[];
  history?: ChefChatMessage[];
};

export type ChefChatResult = {
  provider: 'openrouter' | 'gemini';
  reply: string;
};

const OPENROUTER_URL = 'https://openrouter.ai/api/v1/chat/completions';
const MAX_MESSAGE_CHARS = 2_000;
const MAX_HISTORY_MESSAGES = 12;
const MAX_HISTORY_CHARS = 1_000;
const MAX_PANTRY_ITEMS = 24;
const MAX_PANTRY_ITEM_CHARS = 80;

export const CHEF_SYSTEM_PROMPT = [
  'You are Kitchen Diary\'s AI Chef, a practical and encouraging cooking companion.',
  'Answer the user\'s cooking question directly with useful steps, realistic timings, and substitutions when requested.',
  'Use only pantry items supplied in the context; never claim the user owns an ingredient that was not supplied.',
  'Do not give medical diagnoses or guarantee allergen safety. For serious allergies or medical diets, recommend checking labels and a qualified professional.',
  'Keep replies under 500 words. Use plain text with short headings or numbered steps; do not wrap the response in JSON or code fences.',
].join(' ');

const asRecord = (value: unknown): Record<string, unknown> | null =>
  value !== null && typeof value === 'object' && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;

const text = (value: unknown): string =>
  typeof value === 'string' ? value.trim() : '';

const providerText = (payload: unknown): string => {
  const root = asRecord(payload);
  const choices = Array.isArray(root?.choices) ? root.choices : [];
  const message = asRecord(asRecord(choices[0])?.message);
  const content = message?.content;
  if (typeof content === 'string') return content.trim();
  if (Array.isArray(content)) {
    return content
      .map((part) => text(asRecord(part)?.text))
      .filter(Boolean)
      .join('\n')
      .trim();
  }

  const candidates = Array.isArray(root?.candidates) ? root.candidates : [];
  const candidateContent = asRecord(asRecord(candidates[0])?.content);
  const parts = Array.isArray(candidateContent?.parts) ? candidateContent.parts : [];
  return parts
    .map((part) => text(asRecord(part)?.text))
    .filter(Boolean)
    .join('\n')
    .trim();
};

export const normalizeChefChatInput = (input: ChefChatInput): ChefChatInput => {
  const message = text(input.message).slice(0, MAX_MESSAGE_CHARS);
  if (!message) {
    throw new MenuAnalysisError('invalid_request', 400, 'A cooking question is required.');
  }

  const pantry = (Array.isArray(input.pantry) ? input.pantry : [])
    .map((item) => text(item).slice(0, MAX_PANTRY_ITEM_CHARS))
    .filter(Boolean)
    .slice(0, MAX_PANTRY_ITEMS);
  const history = (Array.isArray(input.history) ? input.history : [])
    .filter((item) => item?.role === 'user' || item?.role === 'assistant')
    .map((item) => ({ role: item.role, content: text(item.content).slice(0, MAX_HISTORY_CHARS) }))
    .filter((item) => item.content)
    .slice(-MAX_HISTORY_MESSAGES);

  return { message, pantry, history };
};

export const chefChatWithProvider = async (
  input: ChefChatInput,
  environment: MenuAnalysisEnvironment = process.env,
  fetcher: typeof fetch = fetch,
): Promise<ChefChatResult> => {
  const normalized = normalizeChefChatInput(input);
  const config = resolveProvider(environment);
  if (!config) {
    throw new MenuAnalysisError(
      'provider_unconfigured',
      503,
      'AI Chef is not configured. Try the built-in recipe catalog instead.',
    );
  }

  const pantryContext = normalized.pantry?.length
    ? `\nCurrent pantry items: ${normalized.pantry.join(', ')}`
    : '';
  const messages = [
    { role: 'system', content: CHEF_SYSTEM_PROMPT },
    ...(normalized.history ?? []),
    { role: 'user' as const, content: `${normalized.message}${pantryContext}` },
  ];

  let url: string;
  let init: RequestInit;
  if (config.provider === 'openrouter') {
    const siteUrl = environment.OPENROUTER_SITE_URL?.trim();
    url = OPENROUTER_URL;
    init = {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${config.apiKey}`,
        'Content-Type': 'application/json',
        ...(siteUrl ? { 'HTTP-Referer': siteUrl } : {}),
        'X-Title': 'Kitchen Diary AI Chef',
      },
      body: JSON.stringify({
        model: config.model,
        messages,
        temperature: 0.35,
        max_tokens: 900,
      }),
    };
  } else {
    url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(config.model)}:generateContent?key=${encodeURIComponent(config.apiKey)}`;
    init = {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: messages
          .filter((item) => item.role !== 'system')
          .map((item) => ({
            role: item.role === 'assistant' ? 'model' : 'user',
            parts: [{ text: item.content }],
          })),
        systemInstruction: { parts: [{ text: CHEF_SYSTEM_PROMPT }] },
        generationConfig: { temperature: 0.35, maxOutputTokens: 900 },
      }),
    };
  }

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 20_000);
  let response: Response;
  try {
    response = await fetcher(url, { ...init, signal: controller.signal });
  } catch (error) {
    if (error instanceof Error && error.name === 'AbortError') {
      throw new MenuAnalysisError('provider_timeout', 504, 'AI Chef took too long to respond. Try again.');
    }
    throw new MenuAnalysisError('provider_request_failed', 502, 'AI Chef is temporarily unavailable.');
  } finally {
    clearTimeout(timeoutId);
  }

  if (!response.ok) {
    throw new MenuAnalysisError('provider_request_failed', 502, 'AI Chef is temporarily unavailable.');
  }

  let payload: unknown;
  try {
    payload = await response.json();
  } catch {
    throw new MenuAnalysisError('provider_invalid_response', 502, 'AI Chef returned an unreadable response.');
  }
  const reply = providerText(payload).slice(0, 4_000);
  if (!reply) {
    throw new MenuAnalysisError('provider_invalid_response', 502, 'AI Chef returned an empty response.');
  }
  return { provider: config.provider, reply };
};
