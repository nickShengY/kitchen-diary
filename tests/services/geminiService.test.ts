import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { analyzeMenuImage, getFoodDescription, searchSmartRecipes } from '../../services/geminiService';
import { getFirebaseAuth, isFirebaseConfigured } from '../../services/firebase';

vi.mock('../../services/firebase', () => ({
  getFirebaseAuth: vi.fn(),
  isFirebaseConfigured: vi.fn(() => false),
}));

describe('recipe discovery service', () => {
  const mockFetch = vi.fn();

  beforeEach(() => {
    mockFetch.mockReset();
    vi.stubGlobal('fetch', mockFetch);
    vi.mocked(isFirebaseConfigured).mockReset();
    vi.mocked(isFirebaseConfigured).mockReturnValue(false);
    vi.mocked(getFirebaseAuth).mockReset();
  });

  afterEach(() => vi.unstubAllGlobals());

  it('does not run AI image analysis in a browser client', async () => {
    await expect(analyzeMenuImage('base64data')).resolves.toEqual([]);
    expect(mockFetch).not.toHaveBeenCalled();
  });

  it('sends menu images to the authenticated same-origin endpoint', async () => {
    const getIdToken = vi.fn().mockResolvedValue('firebase-id-token');
    vi.mocked(isFirebaseConfigured).mockReturnValue(true);
    vi.mocked(getFirebaseAuth).mockReturnValue({
      currentUser: { getIdToken },
    } as never);
    mockFetch.mockResolvedValue({
      ok: true,
      json: async () => ({ items: [{ name: 'Pad Thai', description: 'Rice noodles.' }] }),
    });

    await expect(analyzeMenuImage('base64data', 'image/png')).resolves.toEqual([
      { name: 'Pad Thai', description: 'Rice noodles.' },
    ]);
    expect(getIdToken).toHaveBeenCalledOnce();
    expect(mockFetch).toHaveBeenCalledWith('/api/analyze-menu', expect.objectContaining({
      method: 'POST',
      headers: {
        Authorization: 'Bearer firebase-id-token',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ imageData: 'base64data', mimeType: 'image/png' }),
      signal: expect.any(AbortSignal),
    }));
  });

  it('filters malformed menu items before exposing them to the UI', async () => {
    const getIdToken = vi.fn().mockResolvedValue('firebase-id-token');
    vi.mocked(isFirebaseConfigured).mockReturnValue(true);
    vi.mocked(getFirebaseAuth).mockReturnValue({ currentUser: { getIdToken } } as never);
    mockFetch.mockResolvedValue({
      ok: true,
      json: async () => ({
        items: [
          null,
          { name: '  Pad Thai  ', description: '  Rice noodles.  ' },
          { name: 'pad thai', description: 'Duplicate result.' },
          { name: '   ' },
          { title: 'Soup' },
        ],
      }),
    });

    await expect(analyzeMenuImage('base64data')).resolves.toEqual([
      { name: 'Pad Thai', description: 'Rice noodles.' },
      { name: 'Soup' },
    ]);
  });

  it('aborts an authenticated menu request that exceeds the client deadline', async () => {
    vi.useFakeTimers();
    try {
      const getIdToken = vi.fn().mockResolvedValue('firebase-id-token');
      vi.mocked(isFirebaseConfigured).mockReturnValue(true);
      vi.mocked(getFirebaseAuth).mockReturnValue({ currentUser: { getIdToken } } as never);
      mockFetch.mockImplementation((_url: string, init: RequestInit) => new Promise((_resolve, reject) => {
        init.signal?.addEventListener('abort', () => reject(new Error('request aborted')));
      }));

      const result = analyzeMenuImage('base64data');
      await Promise.resolve();
      await Promise.resolve();
      expect(mockFetch).toHaveBeenCalledOnce();

      await vi.advanceTimersByTimeAsync(25_000);
      await expect(result).resolves.toEqual([]);
    } finally {
      vi.useRealTimers();
    }
  });

  it('keeps the no-AI fallback when the server endpoint is unavailable', async () => {
    const getIdToken = vi.fn().mockResolvedValue('firebase-id-token');
    vi.mocked(isFirebaseConfigured).mockReturnValue(true);
    vi.mocked(getFirebaseAuth).mockReturnValue({ currentUser: { getIdToken } } as never);
    mockFetch.mockResolvedValue({ ok: false, status: 503 });

    await expect(analyzeMenuImage('base64data')).resolves.toEqual([]);
  });

  it('gets food descriptions from TheMealDB when available', async () => {
    mockFetch.mockResolvedValue({
      ok: true,
      json: async () => ({ meals: [{ strInstructions: 'Step one. Step two.' }] }),
    });

    await expect(getFoodDescription('Pasta')).resolves.toContain('Step one');
  });

  it('returns a static description when the public catalog is unavailable', async () => {
    mockFetch.mockRejectedValue(new Error('offline'));
    await expect(getFoodDescription('Pasta')).resolves.toContain('flavorful option');
  });

  it('maps public catalog search results', async () => {
    mockFetch.mockResolvedValue({
      ok: true,
      json: async () => ({
        meals: [{
          idMeal: '123', strMeal: 'Pad Thai', strInstructions: 'Cook noodles.',
          strCategory: 'Dinner', strArea: 'Thai', strMealThumb: 'https://example.com/padthai.jpg',
        }],
      }),
    });

    const recipes = await searchSmartRecipes('thai');
    expect(recipes).toHaveLength(1);
    expect(recipes[0].title).toBe('Pad Thai');
  });

  it('does not fall back to a browser-held AI key', async () => {
    mockFetch.mockResolvedValue({ ok: true, json: async () => ({ meals: null }) });
    await expect(searchSmartRecipes('fusion')).resolves.toEqual([]);
  });
});
