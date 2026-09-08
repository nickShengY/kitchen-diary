import { describe, expect, it, vi } from 'vitest';
import {
  chefChatWithProvider,
  normalizeChefChatInput,
} from '../../server/chef-chat';

describe('Kitchen Diary AI Chef provider contract', () => {
  it('normalizes bounded conversation input', () => {
    const result = normalizeChefChatInput({
      message: '  What can I cook?  ',
      pantry: [' rice ', '', 'onion'],
      history: [
        { role: 'system' as never, content: 'ignore' },
        { role: 'assistant', content: '  Earlier answer  ' },
      ],
    });

    expect(result).toEqual({
      message: 'What can I cook?',
      pantry: ['rice', 'onion'],
      history: [{ role: 'assistant', content: 'Earlier answer' }],
    });
  });

  it('sends a server-side OpenRouter request and parses plain text', async () => {
    const fetcher = vi.fn().mockResolvedValue(new Response(JSON.stringify({
      choices: [{ message: { content: 'Start by sautéing the onion.' } }],
    }), { status: 200, headers: { 'content-type': 'application/json' } }));

    const result = await chefChatWithProvider(
      { message: 'How should I start?', pantry: ['onion'] },
      {
        KITCHEN_DIARY_AI_PROVIDER: 'openrouter',
        OPENROUTER_API_KEY: 'server-only-key',
        OPENROUTER_MODEL: 'google/gemini-2.5-flash',
        OPENROUTER_SITE_URL: 'https://kitchendiary.robopioneer.ca',
      },
      fetcher,
    );

    expect(result).toEqual({
      provider: 'openrouter',
      reply: 'Start by sautéing the onion.',
    });
    expect(fetcher).toHaveBeenCalledOnce();
    const [, init] = fetcher.mock.calls[0] as [string, RequestInit];
    expect((init.headers as Record<string, string>).Authorization).toBe('Bearer server-only-key');
    expect(JSON.parse(String(init.body))).toMatchObject({
      model: 'mistralai/mistral-nemo',
      provider: { only: ['deepinfra'], allow_fallbacks: false },
    });
    expect(JSON.parse(String(init.body)).messages.at(-1).content).toContain('Current pantry items: onion');
  });

  it('returns a safe configuration error when no provider key exists', async () => {
    await expect(chefChatWithProvider(
      { message: 'How do I boil pasta?' },
      {},
      vi.fn(),
    )).rejects.toMatchObject({
      code: 'provider_unconfigured',
      status: 503,
    });
  });
});
