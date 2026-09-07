import {
  deleteDoc,
  doc,
  getDoc,
  setDoc,
  serverTimestamp,
  type DocumentData,
} from 'firebase/firestore';
import type { RecipeStep } from '../types';
import { EMPTY_PANTRY } from './pantryStore';
import type { PantryState } from './pantryStore';
import type { RecipeDraft } from './recipeDraftStore';
import { getFirebaseFirestore } from './firebase';

const PANTRY_PATH = ['pantry', 'state'];
const RECIPE_DRAFT_PATH = ['recipeDrafts', 'current'];
const HISTORY_LIMIT = 20;

export type UserDataKind = 'pantry' | 'recipeDraft';

const LOCAL_OWNER_KEYS: Record<UserDataKind, string> = {
  pantry: 'kitchendiary.pantryOwner.v1',
  recipeDraft: 'kitchendiary.recipeDraftOwner.v1',
};

const canUseStorage = (): boolean => {
  try {
    return typeof window !== 'undefined' && Boolean(window.localStorage);
  } catch {
    return false;
  }
};

/**
 * localStorage predates account sync and is intentionally shared with the
 * offline UI. These small owner markers stop one Google account's local
 * fallback from being uploaded into another account on the same device.
 */
export const getLocalDataOwner = (kind: UserDataKind): string | null => {
  if (!canUseStorage()) return null;
  try {
    return window.localStorage.getItem(LOCAL_OWNER_KEYS[kind]);
  } catch {
    return null;
  }
};

export const markLocalDataOwner = (kind: UserDataKind, userId: string): void => {
  if (!canUseStorage()) return;
  try {
    window.localStorage.setItem(LOCAL_OWNER_KEYS[kind], userId);
  } catch {
    // The local fallback remains usable when storage is unavailable.
  }
};

const userDocument = (userId: string, path: string[]) =>
  doc(getFirebaseFirestore(), 'users', userId, ...path);

const stringList = (value: unknown): string[] =>
  Array.isArray(value) ? value.filter((item): item is string => typeof item === 'string') : [];

const isMatchMode = (value: unknown): value is PantryState['mode'] =>
  value === 'flexible' || value === 'exact' || value === 'survival';

const normalizePantry = (data: DocumentData): PantryState => {
  const dishCount = Number(data.dishCount);

  return {
    ingredients: stringList(data.ingredients),
    cookware: stringList(data.cookware),
    mode: isMatchMode(data.mode) ? data.mode : EMPTY_PANTRY.mode,
    favorites: stringList(data.favorites),
    history: stringList(data.history).slice(0, HISTORY_LIMIT),
    dishCount: Number.isFinite(dishCount)
      ? Math.min(Math.max(dishCount, 1), 5)
      : EMPTY_PANTRY.dishCount,
  };
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

const normalizeRecipeDraft = (data: DocumentData): RecipeDraft | null => {
  if (typeof data.title !== 'string' || !Array.isArray(data.steps)) return null;

  const steps = data.steps.filter(isRecipeStep);
  return steps.length > 0 ? { title: data.title, steps } : null;
};

export const loadUserPantry = async (userId: string): Promise<PantryState | null> => {
  const snapshot = await getDoc(userDocument(userId, PANTRY_PATH));
  return snapshot.exists() ? normalizePantry(snapshot.data()) : null;
};

export const saveUserPantry = async (userId: string, pantry: PantryState): Promise<void> => {
  await setDoc(
    userDocument(userId, PANTRY_PATH),
    {
      ingredients: pantry.ingredients,
      cookware: pantry.cookware,
      mode: pantry.mode,
      favorites: pantry.favorites,
      history: pantry.history.slice(0, HISTORY_LIMIT),
      dishCount: pantry.dishCount,
      updatedAt: serverTimestamp(),
    },
  );
};

export const loadUserRecipeDraft = async (userId: string): Promise<RecipeDraft | null> => {
  const snapshot = await getDoc(userDocument(userId, RECIPE_DRAFT_PATH));
  return snapshot.exists() ? normalizeRecipeDraft(snapshot.data()) : null;
};

export const saveUserRecipeDraft = async (
  userId: string,
  draft: RecipeDraft,
): Promise<void> => {
  await setDoc(userDocument(userId, RECIPE_DRAFT_PATH), {
    title: draft.title,
    steps: draft.steps,
    updatedAt: serverTimestamp(),
  });
};

export const deleteUserRecipeDraft = async (userId: string): Promise<void> => {
  await deleteDoc(userDocument(userId, RECIPE_DRAFT_PATH));
};
