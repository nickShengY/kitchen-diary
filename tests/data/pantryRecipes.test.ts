import { describe, it, expect } from 'vitest';
import { ACTIONS, INGREDIENTS, TOOLS } from '../../data/kitchenData';
import {
  COOKWARE_IDS,
  CORPUS_INGREDIENT_IDS,
  PANTRY_RECIPES,
  PANTRY_RECIPE_BY_ID,
  pantryRecipeToRecipe,
  pantryRecipeToRecipeSteps,
} from '../../data/pantryRecipes';

const ingredientIds = new Set(INGREDIENTS.map((item) => item.id));
const toolIds = new Set(TOOLS.map((item) => item.id));
const actionIds = new Set(ACTIONS.map((item) => item.id));

describe('pantry recipe corpus', () => {
  it('has a meaningful number of dishes', () => {
    expect(PANTRY_RECIPES.length).toBeGreaterThanOrEqual(40);
  });

  it('uses unique ids', () => {
    expect(PANTRY_RECIPE_BY_ID.size).toBe(PANTRY_RECIPES.length);
  });

  it('only references ingredients that exist in the catalogue', () => {
    const unknown: string[] = [];
    PANTRY_RECIPES.forEach((recipe) => {
      [...recipe.core, ...(recipe.extras ?? [])].forEach((id) => {
        if (!ingredientIds.has(id)) unknown.push(`${recipe.id}: ${id}`);
      });
      recipe.steps.forEach((step) =>
        (step.i ?? []).forEach((id) => {
          if (!ingredientIds.has(id)) unknown.push(`${recipe.id} step: ${id}`);
        }),
      );
    });
    expect(unknown).toEqual([]);
  });

  it('only references tools and actions that exist', () => {
    const unknown: string[] = [];
    PANTRY_RECIPES.forEach((recipe) => {
      recipe.tools.forEach((id) => {
        if (!toolIds.has(id)) unknown.push(`${recipe.id} tool: ${id}`);
      });
      recipe.steps.forEach((step) => {
        if (!actionIds.has(step.a)) unknown.push(`${recipe.id} action: ${step.a}`);
        if (step.t && !toolIds.has(step.t)) unknown.push(`${recipe.id} step tool: ${step.t}`);
      });
    });
    expect(unknown).toEqual([]);
  });

  it('offers cookware options that all exist as tools', () => {
    COOKWARE_IDS.forEach((id) => expect(toolIds.has(id)).toBe(true));
  });

  it('gives every dish at least one core ingredient and one step', () => {
    PANTRY_RECIPES.forEach((recipe) => {
      expect(recipe.core.length, recipe.id).toBeGreaterThan(0);
      expect(recipe.steps.length, recipe.id).toBeGreaterThan(0);
    });
  });

  it('exposes only matchable ingredients in the picker shortlist', () => {
    expect(CORPUS_INGREDIENT_IDS.length).toBeGreaterThan(50);
    CORPUS_INGREDIENT_IDS.forEach((id) => expect(ingredientIds.has(id)).toBe(true));
  });

  it('converts a dish into builder steps the player can render', () => {
    const recipe = PANTRY_RECIPE_BY_ID.get('tomato-scrambled-eggs')!;
    const steps = pantryRecipeToRecipeSteps(recipe);

    expect(steps).toHaveLength(recipe.steps.length);
    steps.forEach((step) => {
      expect(actionIds.has(step.actionId)).toBe(true);
      expect(toolIds.has(step.toolId)).toBe(true);
      expect(['prep', 'cook', 'finish']).toContain(step.station);
      step.ingredients.forEach((item) => expect(ingredientIds.has(item.id)).toBe(true));
    });
  });

  it('converts a dish into a shareable Recipe', () => {
    const recipe = pantryRecipeToRecipe(PANTRY_RECIPE_BY_ID.get('egg-fried-rice')!);
    expect(recipe.id).toBe('pantry-egg-fried-rice');
    expect(recipe.title).toBe('Leftover Egg Fried Rice');
    expect(recipe.steps.length).toBeGreaterThan(0);
  });

  it('plates finishing steps instead of falling back to a bowl', () => {
    const steps = pantryRecipeToRecipeSteps(PANTRY_RECIPE_BY_ID.get('tomato-scrambled-eggs')!);
    const garnish = steps.find((step) => step.actionId === 'garnish')!;

    expect(garnish.toolId).toBe('plate');
    expect(garnish.station).toBe('finish');
  });

  it('uses the cookware the dish declares rather than the generic pan', () => {
    const steps = pantryRecipeToRecipeSteps(PANTRY_RECIPE_BY_ID.get('tomato-scrambled-eggs')!);
    const stirFry = steps.find((step) => step.actionId === 'stir_fry')!;

    // The dish is written for a skillet, so the step should say skillet.
    expect(stirFry.toolId).toBe('skillet');
  });

  it('never assigns a step id twice within a dish', () => {
    PANTRY_RECIPES.forEach((recipe) => {
      const steps = pantryRecipeToRecipeSteps(recipe);
      expect(new Set(steps.map((step) => step.id)).size, recipe.id).toBe(steps.length);
    });
  });
});
