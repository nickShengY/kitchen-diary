import { GoogleGenAI, Type } from '@google/genai';
import { MenuItem, Recipe } from '../types';

const MEAL_DB_BASE_URL = 'https://www.themealdb.com/api/json/v1/1';

const getApiKey = (): string => {
  const env = (import.meta as any).env ?? {};
  return env.VITE_GEMINI_API_KEY || env.GEMINI_API_KEY || process.env.API_KEY || '';
};

const getAi = (): GoogleGenAI | null => {
  const apiKey = getApiKey();
  if (!apiKey) return null;
  return new GoogleGenAI({ apiKey });
};

const fetchJson = async <T>(url: string): Promise<T> => {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`API request failed with status ${response.status}`);
  }
  return (await response.json()) as T;
};

// Analyze a menu image to extract dishes.
export const analyzeMenuImage = async (base64Image: string): Promise<MenuItem[]> => {
  try {
    const ai = getAi();
    if (!ai) return [];

    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: {
        parts: [
          {
            inlineData: {
              mimeType: 'image/jpeg',
              data: base64Image,
            },
          },
          {
            text: 'Analyze this menu image and return dish names as JSON.',
          },
        ],
      },
      config: {
        responseMimeType: 'application/json',
        responseSchema: {
          type: Type.ARRAY,
          items: {
            type: Type.OBJECT,
            properties: {
              name: { type: Type.STRING },
              description: { type: Type.STRING },
            },
            required: ['name'],
          },
        },
      },
    });

    return response.text ? (JSON.parse(response.text) as MenuItem[]) : [];
  } catch (error) {
    console.error('Gemini Error:', error);
    return [];
  }
};

// Get a short description for a dish.
export const getFoodDescription = async (dishName: string): Promise<string> => {
  try {
    const searchResponse = await fetchJson<{ meals: Array<{ strInstructions?: string }> | null }>(
      `${MEAL_DB_BASE_URL}/search.php?s=${encodeURIComponent(dishName)}`,
    );
    const instructions = searchResponse.meals?.[0]?.strInstructions?.trim();
    if (instructions) {
      return instructions.replace(/\s+/g, ' ').slice(0, 120);
    }
  } catch {
    // Fall through to AI path below.
  }

  try {
    const ai = getAi();
    if (!ai) return 'A flavorful option picked from today\'s menu.';
    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: `Describe the taste and texture of ${dishName} in one short sentence.`,
    });
    return response.text || 'A flavorful option picked from today\'s menu.';
  } catch {
    return 'A flavorful option picked from today\'s menu.';
  }
};

const mapMealToRecipe = (meal: any): Recipe => ({
  id: meal.idMeal,
  title: meal.strMeal,
  description: (meal.strInstructions || '').replace(/\s+/g, ' ').slice(0, 160),
  tags: [meal.strCategory, meal.strArea].filter(Boolean),
  authorName: `${meal.strArea || 'Global'} Kitchen`,
  authorAvatar: '👩‍🍳',
  authorId: `${meal.strArea || 'global'}-${meal.idMeal}`.toLowerCase(),
  likes: 0,
  createdAt: Date.now(),
  steps: [],
  imageUrl: meal.strMealThumb,
});

// Smart search backed by live recipe APIs.
export const searchSmartRecipes = async (query: string): Promise<Recipe[]> => {
  const normalized = query.trim();
  if (!normalized) return [];

  try {
    const mealDbResponse = await fetchJson<{ meals: any[] | null }>(
      `${MEAL_DB_BASE_URL}/search.php?s=${encodeURIComponent(normalized)}`,
    );
    const meals = mealDbResponse.meals ?? [];
    if (meals.length > 0) {
      return meals.slice(0, 6).map(mapMealToRecipe);
    }
  } catch (error) {
    console.error('MealDB Search Error:', error);
  }

  try {
    const ai = getAi();
    if (!ai) return [];

    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: `Suggest up to 3 real-world dishes for "${normalized}" and return JSON.`,
      config: {
        responseMimeType: 'application/json',
        responseSchema: {
          type: Type.ARRAY,
          items: {
            type: Type.OBJECT,
            properties: {
              title: { type: Type.STRING },
              description: { type: Type.STRING },
              tags: { type: Type.ARRAY, items: { type: Type.STRING } },
            },
          },
        },
      },
    });

    if (!response.text) return [];

    const items = JSON.parse(response.text) as Array<{
      title?: string;
      description?: string;
      tags?: string[];
    }>;

    return items
      .filter((item) => item.title)
      .map((item, index) => ({
        id: `ai-live-${Date.now()}-${index}`,
        title: item.title as string,
        description: item.description,
        tags: item.tags ?? [],
        authorName: 'AI Assistant',
        authorAvatar: '🤖',
        authorId: 'ai',
        likes: 0,
        createdAt: Date.now(),
        steps: [],
      }));
  } catch (error) {
    console.error('Search Error', error);
    return [];
  }
};
