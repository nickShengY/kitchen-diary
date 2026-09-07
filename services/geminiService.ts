import { MenuItem, Recipe } from '../types';
import { getFirebaseAuth, isFirebaseConfigured } from './firebase';

const MEAL_DB_BASE_URL = 'https://www.themealdb.com/api/json/v1/1';
const MENU_ANALYSIS_ENDPOINT = import.meta.env.VITE_MENU_ANALYSIS_ENDPOINT?.trim() || '/api/analyze-menu';

const API_TIMEOUT_MS = 5_000;
const MENU_ANALYSIS_TIMEOUT_MS = 25_000;
const MAX_MENU_ITEMS = 20;

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

// The browser only sends a Firebase ID token and image data to the same-origin
// Vercel function. Provider keys stay server-side. An unavailable endpoint,
// missing auth, or missing provider intentionally keeps the existing empty
// result path so the Decider remains usable without paid AI services.
export const analyzeMenuImage = async (
  base64Image: string,
  mimeType = 'image/jpeg',
): Promise<MenuItem[]> => {
  let timeoutId: ReturnType<typeof setTimeout> | undefined;
  try {
    if (!base64Image.trim() || !isFirebaseConfigured()) return [];
    const user = getFirebaseAuth().currentUser;
    if (!user) return [];

    const controller = new AbortController();
    timeoutId = setTimeout(() => controller.abort(), MENU_ANALYSIS_TIMEOUT_MS);
    const response = await fetch(MENU_ANALYSIS_ENDPOINT, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${await user.getIdToken()}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ imageData: base64Image, mimeType }),
      signal: controller.signal,
    });
    if (!response.ok) return [];

    const payload = (await response.json().catch(() => ({}))) as {
      items?: unknown;
    };
    if (!Array.isArray(payload.items)) return [];

    const seen = new Set<string>();
    return payload.items.flatMap((item): MenuItem[] => {
      if (seen.size >= MAX_MENU_ITEMS) return [];
      if (!item || typeof item !== 'object') return [];
      const record = item as { name?: unknown; title?: unknown; dish?: unknown; description?: unknown };
      const rawName = [record.name, record.title, record.dish].find(
        (value): value is string => typeof value === 'string' && Boolean(value.trim()),
      );
      if (!rawName) return [];
      const name = rawName.trim().slice(0, 120);
      const key = name.toLowerCase();
      if (!name || seen.has(key)) return [];
      seen.add(key);
      return [{
        name,
        ...(typeof record.description === 'string' && record.description.trim()
          ? { description: record.description.trim().slice(0, 240) }
          : {}),
      }];
    });
  } catch {
    return [];
  } finally {
    if (timeoutId !== undefined) clearTimeout(timeoutId);
  }
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
