import { describe, expect, it } from 'vitest';
import { pantryStarters, findPantryStarter } from '../../content/pantry-starters.mjs';
import { PANTRY_RECIPES } from '../../data/pantryRecipes';
import { matchRecipes } from '../../services/pantryMatch';
describe('public pantry examples match the actual recipe engine', () => {
 for (const starter of pantryStarters) it(starter.id, () => {
  const recipe = PANTRY_RECIPES.find(item => item.id === starter.recipeId)!;
  expect(recipe.title).toBe(starter.dish);
  expect(recipe.minutes).toBe(starter.minutes);
  const match = matchRecipes({ pantry: starter.ingredients, cookware: starter.cookware, mode: 'flexible' }).find(item => item.recipe.id === starter.recipeId)!;
  expect(match).toBeDefined();
  expect([...match.missingCore].sort()).toEqual([...starter.missing].sort());
  expect(match.missingTools).toEqual([]);
 });
 it('does not invent a basket for unknown input', () => expect(findPantryStarter('nope')).toBeUndefined());
});
