import {
  ASSUMED_TOOL_IDS,
  Course,
  PANTRY_RECIPES,
  PantryRecipe,
  STAPLE_INGREDIENT_IDS,
} from '../data/pantryRecipes';

/**
 * Turns "here is what is in my kitchen" into a ranked list of things to cook.
 *
 * Three modes, mirroring how people actually shop:
 *  - flexible: I will pick up one or two things on the way home.
 *  - exact:    everything the dish needs is already here.
 *  - survival: nothing at all is missing, and I can cook it with what I own.
 */
export type MatchMode = 'flexible' | 'exact' | 'survival';

export interface MatchModeInfo {
  id: MatchMode;
  label: string;
  emoji: string;
  hint: string;
}

export const MATCH_MODES: MatchModeInfo[] = [
  {
    id: 'flexible',
    label: 'Flexible',
    emoji: '🌤️',
    hint: 'Dishes that use what you have. A short shopping list is fine.',
  },
  {
    id: 'exact',
    label: 'Exact',
    emoji: '🎯',
    hint: 'Every main ingredient is already in your kitchen.',
  },
  {
    id: 'survival',
    label: 'Survival',
    emoji: '🏕️',
    hint: 'Nothing to buy, nothing tricky, on the table in half an hour.',
  },
];

const STAPLES = new Set<string>(STAPLE_INGREDIENT_IDS);
const ASSUMED_TOOLS = new Set<string>(ASSUMED_TOOL_IDS);

export interface MatchInput {
  pantry: string[];
  cookware: string[];
  mode: MatchMode;
  /** Ids the cook has hearted; nudged up the list. */
  favorites?: string[];
  /** Recipe ids cooked recently, newest first; nudged down for variety. */
  recentlyCooked?: string[];
  /** Injectable so tests and menu rolls stay deterministic. */
  now?: Date;
}

export interface RecipeMatch {
  recipe: PantryRecipe;
  score: number;
  /** 0–1 share of the dish's defining ingredients you already have. */
  coverage: number;
  haveCore: string[];
  missingCore: string[];
  haveExtras: string[];
  missingExtras: string[];
  missingTools: string[];
  /** True when the cook could start this dish without buying anything. */
  readyNow: boolean;
  reason: string;
  /**
   * 'pantry' when the ranking reflects what the cook owns, 'discovery' when the
   * kitchen is still empty and we are simply suggesting good places to start.
   */
  ranking: 'pantry' | 'discovery';
}

const has = (set: Set<string>, id: string): boolean => set.has(id) || STAPLES.has(id);

/** Stable per-recipe jitter so the ordering feels alive but never reshuffles mid-session. */
const stableJitter = (id: string): number => {
  let hash = 0;
  for (let index = 0; index < id.length; index += 1) {
    hash = (hash * 31 + id.charCodeAt(index)) % 1000;
  }
  return (hash / 1000) * 4;
};

export type MealSlot = 'breakfast' | 'lunch' | 'dinner' | 'late';

export const mealSlotFor = (now: Date): MealSlot => {
  const hour = now.getHours();
  if (hour < 10) return 'breakfast';
  if (hour < 15) return 'lunch';
  if (hour < 21) return 'dinner';
  return 'late';
};

const SLOT_TAGS: Record<MealSlot, string[]> = {
  breakfast: ['Breakfast'],
  lunch: ['Lunch', 'Quick'],
  dinner: ['Dinner'],
  late: ['Quick', 'Dessert'],
};

const describe = (match: Omit<RecipeMatch, 'reason' | 'score' | 'ranking'>): string => {
  if (match.missingTools.length > 0) {
    return `Needs cookware you have not selected`;
  }
  if (match.missingCore.length === 0 && match.missingExtras.length === 0) {
    return 'You have absolutely everything';
  }
  if (match.missingCore.length === 0) {
    return 'All the essentials are in your kitchen';
  }
  if (match.missingCore.length === 1) {
    return 'One ingredient away';
  }
  return `${match.missingCore.length} ingredients away`;
};

const evaluate = (
  recipe: PantryRecipe,
  pantrySet: Set<string>,
  cookwareSet: Set<string>,
  hasCookwareFilter: boolean,
): Omit<RecipeMatch, 'score' | 'reason' | 'ranking'> => {
  const haveCore = recipe.core.filter((id) => has(pantrySet, id));
  const missingCore = recipe.core.filter((id) => !has(pantrySet, id));
  const extras = recipe.extras ?? [];
  const haveExtras = extras.filter((id) => has(pantrySet, id));
  const missingExtras = extras.filter((id) => !has(pantrySet, id));

  // With no cookware selected we assume a normal kitchen rather than punishing
  // every oven dish; once the cook picks anything, we respect the selection.
  const missingTools = hasCookwareFilter
    ? recipe.tools.filter((id) => !cookwareSet.has(id) && !ASSUMED_TOOLS.has(id))
    : [];

  return {
    recipe,
    coverage: recipe.core.length === 0 ? 1 : haveCore.length / recipe.core.length,
    haveCore,
    missingCore,
    haveExtras,
    missingExtras,
    missingTools,
    readyNow: missingCore.length === 0 && missingTools.length === 0,
  };
};

const passesMode = (
  match: Omit<RecipeMatch, 'score' | 'reason' | 'ranking'>,
  mode: MatchMode,
  pantryIsEmpty: boolean,
): boolean => {
  if (mode === 'exact') {
    return match.missingCore.length === 0 && match.missingTools.length === 0;
  }
  if (mode === 'survival') {
    // Extras are optional by definition, so they never block survival mode —
    // what blocks it is a shopping trip, a missing appliance, or a long cook.
    return (
      match.missingCore.length === 0 &&
      match.missingTools.length === 0 &&
      match.recipe.difficulty === 1 &&
      match.recipe.minutes <= 30
    );
  }
  // Flexible: before anything is selected, show the whole book.
  if (pantryIsEmpty) return match.missingTools.length === 0;
  return match.haveCore.length > 0 && match.missingTools.length === 0;
};

export const matchRecipes = (input: MatchInput, corpus: PantryRecipe[] = PANTRY_RECIPES): RecipeMatch[] => {
  const pantrySet = new Set(input.pantry);
  const cookwareSet = new Set(input.cookware);
  const favorites = new Set(input.favorites ?? []);
  const recent = input.recentlyCooked ?? [];
  const now = input.now ?? new Date();
  const slotTags = SLOT_TAGS[mealSlotFor(now)];
  const pantryIsEmpty = pantrySet.size === 0;

  return corpus
    .map((recipe) => evaluate(recipe, pantrySet, cookwareSet, cookwareSet.size > 0))
    .filter((match) => passesMode(match, input.mode, pantryIsEmpty))
    .map((match) => {
      const extras = match.recipe.extras ?? [];
      const extrasRatio = extras.length === 0 ? 1 : match.haveExtras.length / extras.length;
      const recentIndex = recent.indexOf(match.recipe.id);

      // With an empty kitchen, coverage is meaningless (it only measures
      // staples), so rank on "would this be a good thing to cook right now".
      if (pantryIsEmpty) {
        let discovery = 40;
        if (match.recipe.tags.some((tag) => slotTags.includes(tag))) discovery += 25;
        if (match.recipe.minutes <= 20) discovery += 12;
        else if (match.recipe.minutes >= 75) discovery -= 10;
        discovery += (4 - match.recipe.difficulty) * 5;
        if (favorites.has(match.recipe.id)) discovery += 14;
        if (recentIndex >= 0) discovery -= 18 - Math.min(recentIndex, 5) * 3;
        discovery += stableJitter(match.recipe.id);

        return {
          ...match,
          score: Math.round(discovery * 10) / 10,
          reason: match.recipe.blurb,
          ranking: 'discovery' as const,
        };
      }

      let score = match.coverage * 100;
      score += extrasRatio * 18;
      score -= match.missingCore.length * 9;
      score -= match.missingExtras.length * 1.5;
      if (match.readyNow) score += 12;
      if (match.recipe.minutes <= 20) score += 6;
      else if (match.recipe.minutes >= 75) score -= 4;
      if (match.recipe.tags.some((tag) => slotTags.includes(tag))) score += 10;
      if (favorites.has(match.recipe.id)) score += 14;
      // Cooked yesterday? Show it, but not at the top.
      if (recentIndex >= 0) score -= 18 - Math.min(recentIndex, 5) * 3;
      score += stableJitter(match.recipe.id);

      return {
        ...match,
        score: Math.round(score * 10) / 10,
        reason: describe(match),
        ranking: 'pantry' as const,
      };
    })
    .sort((a, b) => b.score - a.score || a.recipe.title.localeCompare(b.recipe.title));
};

// -------------------------------------------------------------- tonight's menu

export interface MenuOptions extends MatchInput {
  /** How many dishes the menu should contain. */
  dishCount: number;
  /** Recipe ids the cook pinned; these are always kept. */
  locked?: string[];
  /** Changes on every roll so the same pantry can produce a different menu. */
  seed?: number;
}

/** Courses we try to fill, in priority order, as the menu grows. */
const MENU_SHAPE: Course[] = ['main', 'side', 'soup', 'side', 'dessert', 'main', 'snack'];

const primaryProtein = (recipe: PantryRecipe): string =>
  recipe.core.find((id) =>
    [
      'chicken', 'chicken_breast', 'chicken_thigh', 'beef', 'ground_beef', 'beef_slices', 'steak',
      'pork', 'pork_belly', 'bacon', 'sausage', 'lamb', 'fish', 'white_fish', 'salmon', 'shrimp',
      'tofu', 'egg', 'chickpeas', 'lentils', 'kidney_beans',
    ].includes(id),
  ) ?? 'none';

/**
 * Builds a balanced menu instead of just taking the top N matches: one strong
 * main, then courses that do not repeat a protein, so the table looks varied.
 */
export const buildMenu = (
  options: MenuOptions,
  corpus: PantryRecipe[] = PANTRY_RECIPES,
): RecipeMatch[] => {
  const ranked = matchRecipes(options, corpus);
  if (ranked.length === 0) return [];

  const byId = new Map(ranked.map((match) => [match.recipe.id, match]));
  const locked = (options.locked ?? [])
    .map((id) => byId.get(id))
    .filter((match): match is RecipeMatch => Boolean(match));

  const chosen: RecipeMatch[] = [...locked];
  const usedIds = new Set(chosen.map((match) => match.recipe.id));
  const usedProteins = new Set(chosen.map((match) => primaryProtein(match.recipe)));
  const seed = options.seed ?? 0;

  const pick = (predicate: (match: RecipeMatch) => boolean): RecipeMatch | undefined => {
    const pool = ranked.filter((match) => !usedIds.has(match.recipe.id) && predicate(match));
    if (pool.length === 0) return undefined;
    // Rolling picks from a small head keeps quality high while still varying.
    const window = pool.slice(0, Math.min(pool.length, 5));
    return window[(seed + chosen.length * 7) % window.length];
  };

  const target = Math.max(options.dishCount, chosen.length);
  let shapeIndex = 0;

  while (chosen.length < target) {
    const course = MENU_SHAPE[shapeIndex % MENU_SHAPE.length];
    shapeIndex += 1;

    const next =
      pick(
        (match) =>
          match.recipe.course === course && !usedProteins.has(primaryProtein(match.recipe)),
      ) ??
      pick((match) => match.recipe.course === course) ??
      (shapeIndex > MENU_SHAPE.length ? pick(() => true) : undefined);

    if (!next) {
      if (shapeIndex > MENU_SHAPE.length * 2) break;
      continue;
    }

    chosen.push(next);
    usedIds.add(next.recipe.id);
    usedProteins.add(primaryProtein(next.recipe));
  }

  return chosen.slice(0, target);
};

/** Everything the chosen menu still needs, de-duplicated across dishes. */
export const shoppingListFor = (matches: RecipeMatch[]): string[] => {
  const ids = new Set<string>();
  matches.forEach((match) => {
    match.missingCore.forEach((id) => ids.add(id));
  });
  return Array.from(ids);
};

/** A plausible starter pantry for cooks who would rather not tap 20 tiles. */
export const suggestStarterPantry = (): string[] => [
  'egg',
  'onion',
  'garlic',
  'tomato',
  'potato',
  'carrot',
  'rice',
  'pasta',
  'chicken',
  'soy_sauce',
  'butter',
  'milk',
];
