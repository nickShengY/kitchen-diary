import { beforeEach, describe, expect, it, vi } from 'vitest';

const firestoreMocks = vi.hoisted(() => ({
  db: { name: 'test-firestore' },
  doc: vi.fn(),
  getDoc: vi.fn(),
  setDoc: vi.fn(),
  deleteDoc: vi.fn(),
  serverTimestamp: vi.fn(),
}));

vi.mock('firebase/firestore', () => ({
  doc: firestoreMocks.doc,
  getDoc: firestoreMocks.getDoc,
  setDoc: firestoreMocks.setDoc,
  deleteDoc: firestoreMocks.deleteDoc,
  serverTimestamp: firestoreMocks.serverTimestamp,
}));

vi.mock('../../services/firebase', () => ({
  getFirebaseFirestore: vi.fn(() => firestoreMocks.db),
}));

import {
  deleteUserRecipeDraft,
  getLocalDataOwner,
  loadUserPantry,
  loadUserRecipeDraft,
  markLocalDataOwner,
  saveUserPantry,
  saveUserRecipeDraft,
} from '../../services/userDataSync';
import type { PantryState } from '../../services/pantryStore';
import type { RecipeDraft } from '../../services/recipeDraftStore';

const snapshot = (data: Record<string, unknown> | undefined) => ({
  exists: () => Boolean(data),
  data: () => data,
});

const validStep = {
  id: 'step-1',
  actionId: 'chop',
  station: 'prep' as const,
  ingredients: [{ id: 'egg', amount: '1', unit: 'piece' }],
  toolId: 'knife',
};

describe('userDataSync', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    firestoreMocks.doc.mockImplementation((...args: unknown[]) => ({
      path: args.slice(1).join('/'),
    }));
    firestoreMocks.setDoc.mockResolvedValue(undefined);
    firestoreMocks.deleteDoc.mockResolvedValue(undefined);
    firestoreMocks.serverTimestamp.mockReturnValue('SERVER_TIMESTAMP');
  });

  it('loads and normalizes a user-owned pantry document', async () => {
    firestoreMocks.getDoc.mockResolvedValue(
      snapshot({
        ingredients: ['egg', 42],
        cookware: ['pan'],
        mode: 'not-a-mode',
        favorites: ['pantry-egg'],
        history: Array.from({ length: 25 }, (_, index) => `recipe-${index}`),
        dishCount: 99,
      }),
    );

    await expect(loadUserPantry('user-1')).resolves.toEqual({
      ingredients: ['egg'],
      cookware: ['pan'],
      mode: 'flexible',
      favorites: ['pantry-egg'],
      history: Array.from({ length: 20 }, (_, index) => `recipe-${index}`),
      dishCount: 5,
    });
    expect(firestoreMocks.doc).toHaveBeenCalledWith(
      firestoreMocks.db,
      'users',
      'user-1',
      'pantry',
      'state',
    );
  });

  it('returns null when the account has no pantry document', async () => {
    firestoreMocks.getDoc.mockResolvedValue(snapshot(undefined));

    await expect(loadUserPantry('user-1')).resolves.toBeNull();
  });

  it('tracks pantry and recipe-draft ownership separately in local fallback storage', () => {
    expect(getLocalDataOwner('pantry')).toBeNull();
    expect(getLocalDataOwner('recipeDraft')).toBeNull();

    markLocalDataOwner('pantry', 'user-1');
    markLocalDataOwner('recipeDraft', 'user-2');

    expect(getLocalDataOwner('pantry')).toBe('user-1');
    expect(getLocalDataOwner('recipeDraft')).toBe('user-2');
  });

  it('saves pantry state with a bounded history and server timestamp', async () => {
    const pantry: PantryState = {
      ingredients: ['egg'],
      cookware: ['pan'],
      mode: 'survival',
      favorites: ['pantry-egg'],
      history: Array.from({ length: 25 }, (_, index) => `recipe-${index}`),
      dishCount: 3,
    };

    await saveUserPantry('user-1', pantry);

    expect(firestoreMocks.setDoc).toHaveBeenCalledWith(
      { path: 'users/user-1/pantry/state' },
      expect.objectContaining({
        ingredients: ['egg'],
        cookware: ['pan'],
        mode: 'survival',
        favorites: ['pantry-egg'],
        history: Array.from({ length: 20 }, (_, index) => `recipe-${index}`),
        dishCount: 3,
        updatedAt: 'SERVER_TIMESTAMP',
      }),
    );
  });

  it('loads only a valid recipe draft from the account document', async () => {
    firestoreMocks.getDoc.mockResolvedValue(
      snapshot({
        title: 'Weeknight eggs',
        steps: [validStep, { id: 'missing-action' }],
      }),
    );

    await expect(loadUserRecipeDraft('user-1')).resolves.toEqual({
      title: 'Weeknight eggs',
      steps: [validStep],
    });
    expect(firestoreMocks.doc).toHaveBeenCalledWith(
      firestoreMocks.db,
      'users',
      'user-1',
      'recipeDrafts',
      'current',
    );
  });

  it('saves and deletes the current recipe draft in the account namespace', async () => {
    const draft: RecipeDraft = { title: 'Weeknight eggs', steps: [validStep] };

    await saveUserRecipeDraft('user-1', draft);
    expect(firestoreMocks.setDoc).toHaveBeenCalledWith(
      { path: 'users/user-1/recipeDrafts/current' },
      expect.objectContaining({ ...draft, updatedAt: 'SERVER_TIMESTAMP' }),
    );

    await deleteUserRecipeDraft('user-1');
    expect(firestoreMocks.deleteDoc).toHaveBeenCalledWith({
      path: 'users/user-1/recipeDrafts/current',
    });
  });
});
