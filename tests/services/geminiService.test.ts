import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { analyzeMenuImage, getFoodDescription, searchSmartRecipes } from '../../services/geminiService';

describe('recipe discovery service', () => {
  const mockFetch = vi.fn();

  beforeEach(() => {
    mockFetch.mockReset();
    vi.stubGlobal('fetch', mockFetch);
  });

  afterEach(() => vi.unstubAllGlobals());

  it('does not run AI image analysis in a browser client', async () => {
    await expect(analyzeMenuImage('base64data')).resolves.toEqual([]);
    expect(mockFetch).not.toHaveBeenCalled();
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
