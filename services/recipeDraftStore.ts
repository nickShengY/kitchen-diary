import { RecipeStep } from '../types';

const DRAFT_KEY = 'kitchendiary.recipeDraft.v1';

export interface RecipeDraft {
  title: string;
  steps: RecipeStep[];
}

const canUseStorage = (): boolean => {
  try {
    return typeof window !== 'undefined' && Boolean(window.localStorage);
  } catch {
    return false;
  }
};

const isRecipeStep = (value: unknown): value is RecipeStep => {
  if (!value || typeof value !== 'object') return false;
  const step = value as Partial<RecipeStep>;
  return (
    typeof step.id === 'string' &&
    typeof step.actionId === 'string' &&
    Array.isArray(step.ingredients)
  );
};

/** Restores the in-progress recipe so navigating away never loses work. */
export const loadRecipeDraft = (): RecipeDraft | null => {
  if (!canUseStorage()) return null;
  try {
    const raw = window.localStorage.getItem(DRAFT_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as Partial<RecipeDraft>;
    if (typeof parsed?.title !== 'string' || !Array.isArray(parsed.steps)) return null;
    const steps = parsed.steps.filter(isRecipeStep);
    if (steps.length === 0) return null;
    return { title: parsed.title, steps };
  } catch {
    return null;
  }
};

export const saveRecipeDraft = (draft: RecipeDraft) => {
  if (!canUseStorage()) return;
  try {
    window.localStorage.setItem(DRAFT_KEY, JSON.stringify(draft));
  } catch {
    // Storage may be full or blocked; the draft simply stays in-memory.
  }
};

export const clearRecipeDraft = () => {
  if (!canUseStorage()) return;
  try {
    window.localStorage.removeItem(DRAFT_KEY);
  } catch {
    // Ignore storage failures.
  }
};
