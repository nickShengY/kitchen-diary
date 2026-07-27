import { MatchMode } from './pantryMatch';

/**
 * The pantry is the one thing in this app that must survive a reload — nobody
 * wants to re-tap twenty ingredients because they switched tabs.
 */

const PANTRY_KEY = 'kitchendiary.pantry.v1';

export interface PantryState {
  ingredients: string[];
  cookware: string[];
  mode: MatchMode;
  favorites: string[];
  /** Recipe ids, most recently cooked first. */
  history: string[];
  dishCount: number;
}

export const EMPTY_PANTRY: PantryState = {
  ingredients: [],
  cookware: [],
  mode: 'flexible',
  favorites: [],
  history: [],
  dishCount: 3,
};

const HISTORY_LIMIT = 20;

const canUseStorage = (): boolean => {
  try {
    return typeof window !== 'undefined' && Boolean(window.localStorage);
  } catch {
    return false;
  }
};

const stringList = (value: unknown): string[] =>
  Array.isArray(value) ? value.filter((item): item is string => typeof item === 'string') : [];

const isMatchMode = (value: unknown): value is MatchMode =>
  value === 'flexible' || value === 'exact' || value === 'survival';

export const loadPantry = (): PantryState => {
  if (!canUseStorage()) return EMPTY_PANTRY;
  try {
    const raw = window.localStorage.getItem(PANTRY_KEY);
    if (!raw) return EMPTY_PANTRY;
    const parsed = JSON.parse(raw) as Partial<PantryState>;
    const dishCount = Number(parsed?.dishCount);
    return {
      ingredients: stringList(parsed?.ingredients),
      cookware: stringList(parsed?.cookware),
      mode: isMatchMode(parsed?.mode) ? parsed.mode : EMPTY_PANTRY.mode,
      favorites: stringList(parsed?.favorites),
      history: stringList(parsed?.history).slice(0, HISTORY_LIMIT),
      dishCount: Number.isFinite(dishCount) ? Math.min(Math.max(dishCount, 1), 5) : EMPTY_PANTRY.dishCount,
    };
  } catch {
    return EMPTY_PANTRY;
  }
};

export const savePantry = (state: PantryState) => {
  if (!canUseStorage()) return;
  try {
    window.localStorage.setItem(
      PANTRY_KEY,
      JSON.stringify({ ...state, history: state.history.slice(0, HISTORY_LIMIT) }),
    );
  } catch {
    // Storage can be blocked in private mode; the session still works.
  }
};

/**
 * Read-modify-write against storage rather than component state, so screens
 * that are not mounted together (Kitchen and Profile) can never drift apart.
 */
export const updatePantry = (mutate: (state: PantryState) => PantryState): PantryState => {
  const next = mutate(loadPantry());
  savePantry(next);
  return next;
};

/** Moves a dish to the front of the history without ever duplicating it. */
export const withCooked = (history: string[], recipeId: string): string[] =>
  [recipeId, ...history.filter((id) => id !== recipeId)].slice(0, HISTORY_LIMIT);

export const toggleId = (list: string[], id: string): string[] =>
  list.includes(id) ? list.filter((item) => item !== id) : [...list, id];
