import { CuisineCategory, SocialPost, UserProfile } from '../types';
import { CUISINE_CATEGORIES } from '../data/kitchenData';

const MEAL_DB_BASE_URL = 'https://www.themealdb.com/api/json/v1/1';
const RANDOM_USER_URL = 'https://randomuser.me/api/?nat=us,ca,gb,au';
const API_TIMEOUT_MS = 3_000;
const FALLBACK_RECIPE_IMAGE =
  'data:image/svg+xml;utf8,' +
  encodeURIComponent(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 480"><rect width="640" height="480" rx="48" fill="#fff4ec"/><circle cx="320" cy="228" r="116" fill="#ffe1c7"/><text x="320" y="252" text-anchor="middle" font-size="112">🍽️</text><text x="320" y="374" text-anchor="middle" font-family="Arial,sans-serif" font-size="34" font-weight="700" fill="#4a403a">Kitchen Diary</text></svg>',
  );

const CUISINE_EMOJI_MAP: Record<string, string> = {
  American: '\u{1F354}',
  British: '\u{1F35F}',
  Canadian: '\u{1F369}',
  Chinese: '\u{1F95F}',
  Croatian: '\u{1F372}',
  Dutch: '\u{1F9C0}',
  Egyptian: '\u{1FAD3}',
  Filipino: '\u{1F357}',
  French: '\u{1F96A}',
  Greek: '\u{1F957}',
  Indian: '\u{1F35B}',
  Irish: '\u2618\uFE0F',
  Italian: '\u{1F35D}',
  Jamaican: '\u{1F336}\uFE0F',
  Japanese: '\u{1F371}',
  Kenyan: '\u{1F372}',
  Malaysian: '\u{1F35C}',
  Mexican: '\u{1F32E}',
  Moroccan: '\u{1F372}',
  Polish: '\u{1F95F}',
  Portuguese: '\u{1F41F}',
  Russian: '\u{1F372}',
  Spanish: '\u{1F958}',
  Thai: '\u{1F35C}',
  Tunisian: '\u{1FAD3}',
  Turkish: '\u{1F35E}',
  Ukrainian: '\u{1F35E}',
  Unknown: '\u{1F37D}\uFE0F',
  Vietnamese: '\u{1F35C}',
};

type MealDbMeal = {
  idMeal: string;
  strMeal: string;
  strMealThumb: string;
  strArea?: string;
  strCategory?: string;
  strInstructions?: string;
};

type MealDbSearchResponse = {
  meals: MealDbMeal[] | null;
};

type MealDbAreasResponse = {
  meals: Array<{ strArea: string }> | null;
};

export interface LiveUserProfile extends UserProfile {}

const fetchJson = async <T>(url: string, timeoutMs = API_TIMEOUT_MS): Promise<T> => {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch(url, { signal: controller.signal });
    if (!response.ok) {
      throw new Error(`API request failed with status ${response.status}`);
    }
    return (await response.json()) as T;
  } finally {
    clearTimeout(timeoutId);
  }
};

const normalizeCuisineId = (value: string): string =>
  value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');

const builtinCuisineMap = new Map(
  CUISINE_CATEGORIES.map((category) => [normalizeCuisineId(category.name), category]),
);

const mergeCuisineLists = (
  liveCategories: CuisineCategory[],
  fallbackCategories: CuisineCategory[],
  limit: number,
): CuisineCategory[] => {
  const merged = new Map<string, CuisineCategory>();

  for (const category of [...liveCategories, ...fallbackCategories]) {
    const existing = merged.get(category.id);
    if (!existing) {
      merged.set(category.id, {
        ...category,
        dishes: Array.from(new Set(category.dishes)),
      });
      continue;
    }

    merged.set(category.id, {
      id: existing.id,
      name: existing.name || category.name,
      emoji: existing.emoji || category.emoji,
      dishes: Array.from(new Set([...existing.dishes, ...category.dishes])),
    });
  }

  return Array.from(merged.values()).slice(0, limit);
};

const getCuisineEmoji = (area?: string): string => {
  if (!area) return CUISINE_EMOJI_MAP.Unknown;

  const builtin = builtinCuisineMap.get(normalizeCuisineId(area));
  if (builtin) return builtin.emoji;

  return CUISINE_EMOJI_MAP[area] ?? CUISINE_EMOJI_MAP.Unknown;
};

const normalizeTags = (meal: MealDbMeal): string[] => {
  const tags = new Set<string>();
  if (meal.strCategory) tags.add(meal.strCategory);
  if (meal.strArea) tags.add(meal.strArea);
  if (meal.strCategory?.toLowerCase().includes('breakfast')) tags.add('Breakfast');
  if (meal.strCategory?.toLowerCase().includes('dessert')) tags.add('Dessert');
  if (meal.strCategory?.toLowerCase().includes('seafood')) tags.add('Dinner');
  return Array.from(tags).slice(0, 4);
};

const toSocialPost = (meal: MealDbMeal, index: number): SocialPost => {
  const summary = (meal.strInstructions ?? '')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 140);

  return {
    id: meal.idMeal,
    title: meal.strMeal,
    authorId: `${meal.strArea ?? 'global'}-${meal.idMeal}`.toLowerCase(),
    authorName: `${meal.strArea ?? 'Global'} Kitchen`,
    authorAvatar: getCuisineEmoji(meal.strArea),
    imageUrl: meal.strMealThumb,
    description: summary || `${meal.strMeal} made with authentic ingredients.`,
    steps: [],
    tags: normalizeTags(meal),
    createdAt: Date.now() - index * 3_600_000,
  };
};

const fallbackPost = (
  id: string,
  title: string,
  description: string,
  tag: string,
  ingredientId: string,
  index: number,
): SocialPost => ({
  id: `fallback-${id}`,
  title,
  authorId: 'kitchendiary-studio',
  authorName: 'Kitchen Diary Studio',
  authorAvatar: '\u{1F9D1}\u200D\u{1F373}',
  imageUrl: FALLBACK_RECIPE_IMAGE,
  description,
  steps: [],
  tags: [tag, 'Quick'],
  likes: 80 - index * 7,
  comments: 10 - Math.min(index, 7),
  createdAt: Date.now() - index * 2_700_000,
});

const getFallbackCommunityFeed = (limit: number): SocialPost[] =>
  [
    fallbackPost(
      'tomato-rice-bowl',
      'Tomato Rice Bowl',
      'A bright weeknight bowl with tomato, rice, herbs, and a soft simmer.',
      'Dinner',
      'tomato',
      0,
    ),
    fallbackPost(
      'ginger-chicken',
      'Ginger Chicken Prep',
      'Chicken, ginger, and scallions staged into a builder-friendly cooking flow.',
      'Dinner',
      'ginger',
      1,
    ),
    fallbackPost(
      'herb-salad',
      'Fresh Herb Salad',
      'A light lunch idea using basil, mint, cucumber, and a quick dressing.',
      'Healthy',
      'basil',
      2,
    ),
    fallbackPost(
      'breakfast-egg',
      'Breakfast Egg Plate',
      'A simple breakfast plate that is ready to customize in the recipe builder.',
      'Breakfast',
      'egg',
      3,
    ),
    fallbackPost(
      'broth-noodles',
      'Cozy Broth Noodles',
      'Noodles, broth, greens, and seasoning arranged as a clear cooking sequence.',
      'Lunch',
      'broth',
      4,
    ),
    fallbackPost(
      'fruit-dessert',
      'Strawberry Banana Cup',
      'A cute dessert starter with fresh fruit and a creamy finish.',
      'Dessert',
      'strawberry',
      5,
    ),
  ].slice(0, limit);

export const fetchCommunityFeed = async (limit = 24): Promise<SocialPost[]> => {
  try {
    const url = `${MEAL_DB_BASE_URL}/search.php?s=`;
    const result = await fetchJson<MealDbSearchResponse>(url);
    const meals = result.meals ?? [];
    const livePosts = meals.slice(0, limit).map(toSocialPost);
    return livePosts.length > 0 ? livePosts : getFallbackCommunityFeed(limit);
  } catch {
    return getFallbackCommunityFeed(limit);
  }
};

export const fetchCuisineWheelData = async (limit = 18): Promise<CuisineCategory[]> => {
  try {
    const fallbackCategories = CUISINE_CATEGORIES.slice(0, limit);
    const fallbackByName = new Map(
      fallbackCategories.map((category) => [category.name, category]),
    );
    const areasResult = await fetchJson<MealDbAreasResponse>(
      `${MEAL_DB_BASE_URL}/list.php?a=list`,
    );
    const areas = (areasResult.meals ?? []).map((item) => item.strArea);
    const prioritizedAreas = fallbackCategories.map((category) => category.name);
    const orderedAreas = Array.from(
      new Set([...prioritizedAreas, ...areas]),
    ).slice(0, limit);

    const liveCategories = await Promise.all(
      orderedAreas.map(async (area) => {
        try {
          const dishesResult = await fetchJson<MealDbSearchResponse>(
            `${MEAL_DB_BASE_URL}/filter.php?a=${encodeURIComponent(area)}`,
          );
          const liveDishes = (dishesResult.meals ?? [])
            .slice(0, 10)
            .map((meal) => meal.strMeal);
          const fallbackDishes = fallbackByName.get(area)?.dishes ?? [];

          return {
            id: normalizeCuisineId(area),
            name: area,
            emoji: getCuisineEmoji(area),
            dishes: Array.from(new Set([...liveDishes, ...fallbackDishes])),
          } satisfies CuisineCategory;
        } catch {
          const fallbackCategory = fallbackByName.get(area);
          return (
            fallbackCategory ?? {
              id: normalizeCuisineId(area),
              name: area,
              emoji: getCuisineEmoji(area),
              dishes: [],
            }
          );
        }
      }),
    );

    return mergeCuisineLists(liveCategories, fallbackCategories, limit);
  } catch {
    return CUISINE_CATEGORIES.slice(0, limit);
  }
};

export const fetchRealProfile = async (): Promise<LiveUserProfile> => {
  const response = await fetchJson<{
    results: Array<{
      login: { uuid: string };
      name: { first: string; last: string };
      location: { city: string; country: string };
      picture: { large: string };
    }>;
  }>(RANDOM_USER_URL);

  const user = response.results[0];
  return {
    id: user.login.uuid,
    name: `${user.name.first} ${user.name.last}`,
    avatar: '\u{1F9D1}\u200D\u{1F373}',
    bio: `Cooking through ${user.location.city}, ${user.location.country}.`,
    favorites: [],
    myRecipes: [],
  };
};
