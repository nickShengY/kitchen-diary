import { MenuItem, Recipe } from '../types';

const MEAL_DB_BASE_URL = 'https://www.themealdb.com/api/json/v1/1';

const API_TIMEOUT_MS = 5_000;

const fetchJson = async <T>(url: string): Promise<T> => {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), API_TIMEOUT_MS);
  try {
    const response = await fetch(url, { signal: controller.signal });
    if (!response.ok) throw new Error(`API request failed with status ${response.status}`);
    return (await response.json()) as T;
  } finally {
    clearTimeout(timeoutId);
  }
};

// AI image analysis is deliberately unavailable in the public client. It can
// only be added through an authenticated, rate-limited server endpoint.
export const analyzeMenuImage = async (base64Image: string): Promise<MenuItem[]> => {
  void base64Image;
  return [];
};

export const getFoodDescription = async (dishName: string): Promise<string> => {
  try {
    const result = await fetchJson<{ meals: Array<{ strInstructions?: string }> | null }>(
      `${MEAL_DB_BASE_URL}/search.php?s=${encodeURIComponent(dishName)}`,
    );
    const instructions = result.meals?.[0]?.strInstructions?.trim();
    if (instructions) return instructions.replace(/\s+/g, ' ').slice(0, 120);
  } catch {
    // The static fallback keeps the feature usable without a paid AI service.
  }
  return 'A flavorful option picked from today\'s menu.';
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

// Search uses the public recipe catalog only. We intentionally do not fall
// back to a browser-held Gemini key, which could create unbounded spend.
export const searchSmartRecipes = async (query: string): Promise<Recipe[]> => {
  const normalized = query.trim();
  if (!normalized) return [];

  try {
    const result = await fetchJson<{ meals: any[] | null }>(
      `${MEAL_DB_BASE_URL}/search.php?s=${encodeURIComponent(normalized)}`,
    );
    return (result.meals ?? []).slice(0, 6).map(mapMealToRecipe);
  } catch {
    return [];
  }
};
