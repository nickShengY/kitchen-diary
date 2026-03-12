import { CuisineCategory, SocialPost, UserProfile } from '../types';

const MEAL_DB_BASE_URL = 'https://www.themealdb.com/api/json/v1/1';
const RANDOM_USER_URL = 'https://randomuser.me/api/?nat=us,ca,gb,au';

const CUISINE_EMOJI_MAP: Record<string, string> = {
  American: '🍔',
  British: '🥧',
  Canadian: '🍁',
  Chinese: '🥡',
  Croatian: '🍲',
  Dutch: '🧀',
  Egyptian: '🥙',
  Filipino: '🍛',
  French: '🥐',
  Greek: '🫒',
  Indian: '🍛',
  Irish: '☘️',
  Italian: '🍝',
  Jamaican: '🌶️',
  Japanese: '🍣',
  Kenyan: '🥘',
  Malaysian: '🍜',
  Mexican: '🌮',
  Moroccan: '🥘',
  Polish: '🥟',
  Portuguese: '🐟',
  Russian: '🥟',
  Spanish: '🥘',
  Thai: '🍜',
  Tunisian: '🥗',
  Turkish: '🍢',
  Ukrainian: '🥟',
  Unknown: '🍽️',
  Vietnamese: '🍜',
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

const fetchJson = async <T>(url: string): Promise<T> => {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`API request failed with status ${response.status}`);
  }
  return (await response.json()) as T;
};

const getCuisineEmoji = (area?: string): string => {
  if (!area) return CUISINE_EMOJI_MAP.Unknown;
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

export const fetchCommunityFeed = async (limit = 24): Promise<SocialPost[]> => {
  const url = `${MEAL_DB_BASE_URL}/search.php?s=`;
  const result = await fetchJson<MealDbSearchResponse>(url);
  const meals = result.meals ?? [];
  return meals.slice(0, limit).map(toSocialPost);
};

export const fetchCuisineWheelData = async (limit = 8): Promise<CuisineCategory[]> => {
  const areasResult = await fetchJson<MealDbAreasResponse>(`${MEAL_DB_BASE_URL}/list.php?a=list`);
  const areas = (areasResult.meals ?? []).map((item) => item.strArea);
  const prioritized = ['Italian', 'Chinese', 'Mexican', 'French', 'Japanese', 'American'];
  const orderedAreas = [...prioritized, ...areas.filter((area) => !prioritized.includes(area))]
    .slice(0, limit);

  const categories = await Promise.all(
    orderedAreas.map(async (area) => {
      try {
        const dishesResult = await fetchJson<MealDbSearchResponse>(
          `${MEAL_DB_BASE_URL}/filter.php?a=${encodeURIComponent(area)}`,
        );
        const dishes = (dishesResult.meals ?? []).slice(0, 12).map((meal) => meal.strMeal);
        return {
          id: area.toLowerCase().replace(/\s+/g, '-'),
          name: area,
          emoji: getCuisineEmoji(area),
          dishes,
        } satisfies CuisineCategory;
      } catch {
        return {
          id: area.toLowerCase().replace(/\s+/g, '-'),
          name: area,
          emoji: getCuisineEmoji(area),
          dishes: [],
        } satisfies CuisineCategory;
      }
    }),
  );

  return categories;
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
    avatar: '👩‍🍳',
    bio: `Cooking through ${user.location.city}, ${user.location.country}.`,
    favorites: [],
    myRecipes: [],
  };
};
