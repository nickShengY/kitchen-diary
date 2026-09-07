import { beforeEach, describe, expect, it, vi } from 'vitest';
import { render, waitFor } from '@testing-library/react';
import { PantryKitchen } from '../../components/PantryKitchen';
import { RecipeBuilder } from '../../components/RecipeBuilder';
import { EMPTY_PANTRY, loadPantry, savePantry } from '../../services/pantryStore';
import { loadRecipeDraft, saveRecipeDraft } from '../../services/recipeDraftStore';
import type { RecipeDraft } from '../../services/recipeDraftStore';

const cloudMocks = vi.hoisted(() => ({
  loadUserPantry: vi.fn(),
  saveUserPantry: vi.fn(),
  loadUserRecipeDraft: vi.fn(),
  saveUserRecipeDraft: vi.fn(),
  deleteUserRecipeDraft: vi.fn(),
  getLocalDataOwner: vi.fn(),
  markLocalDataOwner: vi.fn(),
}));

vi.mock('../../services/userDataSync', () => cloudMocks);

const validDraft: RecipeDraft = {
  title: 'Shared kitchen draft',
  steps: [
    {
      id: 'step-1',
      station: 'prep',
      ingredients: [{ id: 'egg', amount: '1', unit: 'piece' }],
      toolId: 'knife',
      actionId: 'chop',
    },
  ],
};

describe('account-scoped local fallback', () => {
  const owners = new Map<string, string>();

  beforeEach(() => {
    vi.clearAllMocks();
    owners.clear();
    cloudMocks.loadUserPantry.mockResolvedValue(null);
    cloudMocks.saveUserPantry.mockResolvedValue(undefined);
    cloudMocks.loadUserRecipeDraft.mockResolvedValue(null);
    cloudMocks.saveUserRecipeDraft.mockResolvedValue(undefined);
    cloudMocks.deleteUserRecipeDraft.mockResolvedValue(undefined);
    cloudMocks.getLocalDataOwner.mockImplementation((kind: string) => owners.get(kind) ?? null);
    cloudMocks.markLocalDataOwner.mockImplementation((kind: string, userId: string) => {
      owners.set(kind, userId);
    });
    window.localStorage.clear();
  });

  it('adopts anonymous pantry state for the first signed-in account', async () => {
    savePantry({ ...EMPTY_PANTRY, ingredients: ['egg'] });

    render(<PantryKitchen userId="user-a" onCookThis={vi.fn()} />);

    await waitFor(() =>
      expect(cloudMocks.saveUserPantry).toHaveBeenCalledWith(
        'user-a',
        expect.objectContaining({ ingredients: ['egg'] }),
      ),
    );
    expect(owners.get('pantry')).toBe('user-a');
  });

  it('does not upload account A pantry state to account B when B has no document', async () => {
    savePantry({ ...EMPTY_PANTRY, ingredients: ['egg'] });
    owners.set('pantry', 'user-a');

    const view = render(<PantryKitchen userId="user-a" onCookThis={vi.fn()} />);
    await waitFor(() => expect(cloudMocks.loadUserPantry).toHaveBeenCalledWith('user-a'));

    view.rerender(<PantryKitchen userId="user-b" onCookThis={vi.fn()} />);
    await waitFor(() => expect(cloudMocks.loadUserPantry).toHaveBeenCalledWith('user-b'));
    await waitFor(() => expect(loadPantry()).toEqual(EMPTY_PANTRY));

    expect(cloudMocks.saveUserPantry.mock.calls.some(([id]) => id === 'user-b')).toBe(false);
    expect(owners.get('pantry')).toBe('user-b');
  });

  it('does not upload account A recipe draft to account B when B has no document', async () => {
    saveRecipeDraft(validDraft);
    owners.set('recipeDraft', 'user-a');

    const view = render(<RecipeBuilder userId="user-a" />);
    await waitFor(() => expect(cloudMocks.loadUserRecipeDraft).toHaveBeenCalledWith('user-a'));

    view.rerender(<RecipeBuilder userId="user-b" />);
    await waitFor(() => expect(cloudMocks.loadUserRecipeDraft).toHaveBeenCalledWith('user-b'));
    await waitFor(() => expect(loadRecipeDraft()).toBeNull());

    expect(cloudMocks.saveUserRecipeDraft.mock.calls.some(([id]) => id === 'user-b')).toBe(false);
    expect(owners.get('recipeDraft')).toBe('user-b');
  });
});
