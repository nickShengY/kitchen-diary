import { Recipe, SocialPost } from '../types';
import { INGREDIENTS } from '../data/kitchenData';

const STORAGE_KEY = 'kitchendiary.sharedPosts.v1';
const MAX_SHARED_POSTS = 50;

const canUseStorage = (): boolean => {
  try {
    return typeof window !== 'undefined' && Boolean(window.localStorage);
  } catch {
    return false;
  }
};

/** Only image sources that cannot carry script are allowed back into the app. */
const isSafeImageUrl = (value: unknown): value is string =>
  typeof value === 'string' &&
  (/^https:\/\//i.test(value) || /^data:image\//i.test(value));

// localStorage is user-editable and schemas drift between versions, so every
// field the UI dereferences gets validated or defaulted before rendering.
const normalizePost = (post: unknown): SocialPost | null => {
  if (!post || typeof post !== 'object') return null;
  const raw = post as Record<string, unknown>;
  if (typeof raw.id !== 'string' || typeof raw.title !== 'string') return null;

  return {
    id: raw.id,
    title: raw.title,
    description: typeof raw.description === 'string' ? raw.description : '',
    authorId: typeof raw.authorId === 'string' ? raw.authorId : 'local-chef',
    authorName: typeof raw.authorName === 'string' ? raw.authorName : 'You',
    authorAvatar: typeof raw.authorAvatar === 'string' ? raw.authorAvatar : '\u{1F9D1}‍\u{1F373}',
    steps: Array.isArray(raw.steps)
      ? raw.steps.filter(
          (step): step is Recipe['steps'][number] =>
            Boolean(step && typeof step === 'object' && Array.isArray((step as { ingredients?: unknown }).ingredients)),
        )
      : [],
    tags: Array.isArray(raw.tags) ? raw.tags.filter((tag): tag is string => typeof tag === 'string') : [],
    likes: typeof raw.likes === 'number' ? raw.likes : 0,
    comments: typeof raw.comments === 'number' ? raw.comments : 0,
    createdAt: typeof raw.createdAt === 'number' ? raw.createdAt : 0,
    imageUrl: isSafeImageUrl(raw.imageUrl) ? raw.imageUrl : undefined,
  };
};

const readStore = (): SocialPost[] => {
  if (!canUseStorage()) return [];
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return parsed
      .map(normalizePost)
      .filter((post): post is SocialPost => post !== null);
  } catch {
    return [];
  }
};

const writeStore = (posts: SocialPost[]) => {
  if (!canUseStorage()) return;
  try {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(posts.slice(0, MAX_SHARED_POSTS)));
  } catch {
    // Storage may be full or blocked; sharing still succeeds in-session.
  }
};

const heroEmojiForRecipe = (recipe: Recipe): string => {
  const firstIngredientId = recipe.steps[0]?.ingredients[0]?.id;
  const ingredient = INGREDIENTS.find((item) => item.id === firstIngredientId);
  return ingredient?.emoji ?? '\u{1F37D}️';
};

const escapeXml = (value: string): string =>
  value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');

/** A warm cover image so home-made recipes look at home next to live feed photos. */
const buildCoverImage = (recipe: Recipe): string => {
  const emoji = heroEmojiForRecipe(recipe);
  const title = escapeXml(recipe.title.slice(0, 26));
  const svg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 480">' +
    '<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">' +
    '<stop offset="0" stop-color="#ffe8d6"/><stop offset="1" stop-color="#ffd2bd"/>' +
    '</linearGradient></defs>' +
    '<rect width="640" height="480" rx="48" fill="url(#g)"/>' +
    '<circle cx="320" cy="210" r="118" fill="#fffaf4"/>' +
    '<circle cx="320" cy="210" r="118" fill="none" stroke="#ffb388" stroke-width="6" stroke-dasharray="4 14" stroke-linecap="round"/>' +
    `<text x="320" y="248" text-anchor="middle" font-size="116">${emoji}</text>` +
    `<text x="320" y="392" text-anchor="middle" font-family="Arial,sans-serif" font-size="36" font-weight="700" fill="#4a403a">${title}</text>` +
    '<text x="320" y="432" text-anchor="middle" font-family="Arial,sans-serif" font-size="22" font-weight="600" fill="#f2704f">Made in Kitchen Diary</text>' +
    '</svg>';
  return `data:image/svg+xml;utf8,${encodeURIComponent(svg)}`;
};

export const getSharedPosts = (): SocialPost[] =>
  [...readStore()].sort((a, b) => b.createdAt - a.createdAt);

export interface ShareRecipeInput {
  title: string;
  description: string;
  tags: string[];
  steps: Recipe['steps'];
}

export const shareRecipeToCommunity = (input: ShareRecipeInput): SocialPost => {
  const recipeBase: Recipe = {
    id: `shared-${Date.now()}-${Math.random().toString(16).slice(2, 8)}`,
    title: input.title.trim() || 'My Kitchen Diary Recipe',
    authorId: 'local-chef',
    authorName: 'You',
    authorAvatar: '\u{1F9D1}‍\u{1F373}',
    steps: input.steps,
    tags: input.tags.length > 0 ? input.tags : ['Quick'],
    likes: 0,
    createdAt: Date.now(),
  };

  const post: SocialPost = {
    ...recipeBase,
    imageUrl: buildCoverImage(recipeBase),
    description:
      input.description.trim() ||
      `A ${input.steps.length}-step recipe built step by step in Kitchen Diary.`,
    comments: 0,
  };

  writeStore([post, ...readStore()]);
  return post;
};

export const removeSharedPost = (id: string) => {
  writeStore(readStore().filter((post) => post.id !== id));
};
