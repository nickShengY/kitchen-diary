import { beforeEach, describe, expect, it, vi } from 'vitest';
import {
  analyzeMenuImageWithProvider,
  MENU_ANALYSIS_PROMPT,
  normalizeImageData,
  parseMenuItems,
  resolveProvider,
} from '../../server/menu-analysis';

describe('server menu analysis provider', () => {
  const fetchMock = vi.fn();

  beforeEach(() => {
    fetchMock.mockReset();
  });

  it('requires menu-grounded descriptions without inferred safety or price claims', () => {
    expect(MENU_ANALYSIS_PROMPT).toMatch(/only when the menu itself clearly states it/i);
    expect(MENU_ANALYSIS_PROMPT).toMatch(/allergens/i);
    expect(MENU_ANALYSIS_PROMPT).toMatch(/prices/i);
  });

  it('prefers OpenRouter and sends a multimodal JSON request', async () => {
    fetchMock.mockResolvedValue({
      ok: true,
      json: async () => ({
        choices: [{
          message: {
            content: '```json\n{"items":[{"name":"Pad Thai","description":"Rice noodles."}]}\n```',
          },
        }],
      }),
    });

    const result = await analyzeMenuImageWithProvider(
      { imageData: Buffer.from('menu').toString('base64'), mimeType: 'image/png' },
      {
        OPENROUTER_API_KEY: 'openrouter-test-key',
        OPENROUTER_MODEL: 'test/vision-model:free',
      },
      fetchMock as unknown as typeof fetch,
    );

    expect(result).toEqual({
      provider: 'openrouter',
      items: [{ name: 'Pad Thai', description: 'Rice noodles.' }],
    });
    expect(fetchMock).toHaveBeenCalledOnce();
    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(url).toBe('https://openrouter.ai/api/v1/chat/completions');
    expect(init.method).toBe('POST');
    const payload = JSON.parse(String(init.body)) as {
      model: string;
      messages: Array<{ content: Array<{ type: string; image_url?: { url: string } }> }>;
    };
    expect(payload.model).toBe('nex-agi/nex-n2-mini');
    expect(payload.messages[0].content[0].type).toBe('text');
    expect(payload.messages[0].content[1].image_url?.url).toBe('data:image/png;base64,bWVudQ==');
  });

  it('uses one fixed low-cost model regardless of stale provider configuration', () => {
    for (const model of ['google/gemini-2.5-flash', 'google/gemini-test:free', 'paid/vision']) {
      expect(resolveProvider({ OPENROUTER_API_KEY: 'test', KITCHEN_DIARY_AI_PROVIDER: 'gemini', OPENROUTER_MODEL: model })).toMatchObject({
        provider: 'openrouter', model: 'nex-agi/nex-n2-mini',
      });
    }
  });

  it('never falls back to Gemini credentials', () => {
    expect(resolveProvider({ GEMINI_API_KEY: 'gemini-test-key' })).toBeNull();
    expect(resolveProvider({
      KITCHEN_DIARY_AI_PROVIDER: 'openrouter',
      GEMINI_API_KEY: 'gemini-test-key',
    })).toBeNull();
  });

  it('reports an explicit provider without a key as unconfigured', async () => {
    await expect(
      analyzeMenuImageWithProvider(
        { imageData: Buffer.from('menu').toString('base64') },
        { KITCHEN_DIARY_AI_PROVIDER: 'gemini' },
        fetchMock as unknown as typeof fetch,
      ),
    ).rejects.toMatchObject({ code: 'provider_unconfigured', status: 503 });
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('normalizes data URLs, bounds items, and rejects unsupported images', () => {
    expect(normalizeImageData('data:image/webp;base64,bWVudQ==')).toEqual({
      data: 'bWVudQ==',
      mimeType: 'image/webp',
      sizeBytes: 4,
    });
    expect(parseMenuItems({
      items: [
        { name: 'Soup', desc: 'Warm bowl.' },
        { title: 'soup' },
        'Salad',
        { name: '' },
      ],
    })).toEqual([
      { name: 'Soup', description: 'Warm bowl.' },
      { name: 'Salad' },
    ]);
    expect(() => normalizeImageData('bWVudQ==', 'image/gif')).toThrow(/JPEG, PNG, or WebP/);
  });
});
