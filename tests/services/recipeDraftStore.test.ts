import { beforeEach, describe, expect, it } from 'vitest';
import { clearRecipeDraft, loadRecipeDraft, saveRecipeDraft } from '../../services/recipeDraftStore';
import { RecipeStep } from '../../types';

const DRAFT_KEY = 'kitchendiary.recipeDraft.v1';

const sampleSteps: RecipeStep[] = [
  {
    id: 'step-1',
    station: 'cook',
    ingredients: [{ id: 'egg', amount: '2', unit: 'pcs' }],
    toolId: 'pan',
    actionId: 'fry',
    settings: { temperature: 'Medium' },
  },
];

describe('recipeDraftStore', () => {
  beforeEach(() => {
    window.localStorage.clear();
  });

  it('round-trips a draft', () => {
    saveRecipeDraft({ title: 'Breakfast Eggs', steps: sampleSteps });
    const draft = loadRecipeDraft();
    expect(draft?.title).toBe('Breakfast Eggs');
    expect(draft?.steps).toHaveLength(1);
    expect(draft?.steps[0].actionId).toBe('fry');
  });

  it('returns null when no draft exists', () => {
    expect(loadRecipeDraft()).toBeNull();
  });

  it('clears the draft', () => {
    saveRecipeDraft({ title: 'Soup', steps: sampleSteps });
    clearRecipeDraft();
    expect(loadRecipeDraft()).toBeNull();
  });

  it('rejects corrupted drafts', () => {
    window.localStorage.setItem(DRAFT_KEY, 'not json {');
    expect(loadRecipeDraft()).toBeNull();

    window.localStorage.setItem(DRAFT_KEY, JSON.stringify({ title: 5, steps: 'nope' }));
    expect(loadRecipeDraft()).toBeNull();
  });

  it('filters out malformed steps and treats an all-invalid draft as empty', () => {
    window.localStorage.setItem(
      DRAFT_KEY,
      JSON.stringify({ title: 'Mixed', steps: [sampleSteps[0], { bogus: true }, null] }),
    );
    const draft = loadRecipeDraft();
    expect(draft?.steps).toHaveLength(1);

    window.localStorage.setItem(
      DRAFT_KEY,
      JSON.stringify({ title: 'Empty', steps: [{ bogus: true }] }),
    );
    expect(loadRecipeDraft()).toBeNull();
  });
});
