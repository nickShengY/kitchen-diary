import { describe, it, expect, vi, beforeEach, afterEach, Mock } from 'vitest';
import { analyzeMenuImage, getFoodDescription, searchSmartRecipes } from '../../services/geminiService';

vi.mock('@google/genai', () => ({
  GoogleGenAI: vi.fn().mockImplementation(() => ({
    models: { generateContent: vi.fn() },
  })),
  Type: {
    ARRAY: 'array',
    OBJECT: 'object',
    STRING: 'string',
  },
}));

import { GoogleGenAI } from '@google/genai';

describe('geminiService', () => {
  const mockGenerateContent = vi.fn();
  const mockFetch = vi.fn();

  beforeEach(() => {
    vi.unstubAllEnvs();
    vi.stubEnv('API_KEY', 'test-key');
    (GoogleGenAI as Mock).mockImplementation(() => ({
      models: { generateContent: mockGenerateContent },
    }));
    mockGenerateContent.mockReset();
    mockFetch.mockReset();
    vi.stubGlobal('fetch', mockFetch);
  });

  afterEach(() => {
    vi.unstubAllEnvs();
    vi.unstubAllGlobals();
  });

  it('analyzeMenuImage returns parsed JSON from Gemini', async () => {
    mockGenerateContent.mockResolvedValue({
      text: JSON.stringify([{ name: 'Ramen' }]),
    });

    const result = await analyzeMenuImage('base64data');
    expect(result).toEqual([{ name: 'Ramen' }]);
  });

  it('analyzeMenuImage returns empty array when no API key', async () => {
    vi.stubEnv('API_KEY', '');
    const result = await analyzeMenuImage('base64data');
    expect(result).toEqual([]);
  });

  it('getFoodDescription prefers live MealDB instructions', async () => {
    mockFetch.mockResolvedValue({
      ok: true,
      json: async () => ({
        meals: [{ strInstructions: 'Step one. Step two.' }],
      }),
    });

    const result = await getFoodDescription('Pasta');
    expect(result).toContain('Step one');
  });

  it('searchSmartRecipes returns mapped MealDB recipes', async () => {
    mockFetch.mockResolvedValue({
      ok: true,
      json: async () => ({
        meals: [
          {
            idMeal: '123',
            strMeal: 'Pad Thai',
            strInstructions: 'Cook noodles.',
            strCategory: 'Dinner',
            strArea: 'Thai',
            strMealThumb: 'https://example.com/padthai.jpg',
          },
        ],
      }),
    });

    const recipes = await searchSmartRecipes('thai');
    expect(recipes).toHaveLength(1);
    expect(recipes[0].title).toBe('Pad Thai');
    expect(recipes[0].imageUrl).toBe('https://example.com/padthai.jpg');
  });

  it('searchSmartRecipes falls back to Gemini suggestions when MealDB empty', async () => {
    mockFetch.mockResolvedValue({
      ok: true,
      json: async () => ({ meals: null }),
    });
    mockGenerateContent.mockResolvedValue({
      text: JSON.stringify([{ title: 'Fusion Bowl', description: 'Tasty', tags: ['Fusion'] }]),
    });

    const recipes = await searchSmartRecipes('fusion');
    expect(recipes).toHaveLength(1);
    expect(recipes[0].title).toBe('Fusion Bowl');
  });
});
