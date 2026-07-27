import { describe, it, expect } from 'vitest';
import { PANTRY_RECIPES, PantryRecipe } from '../../data/pantryRecipes';
import {
  MATCH_MODES,
  buildMenu,
  matchRecipes,
  mealSlotFor,
  shoppingListFor,
  suggestStarterPantry,
} from '../../services/pantryMatch';

const EVENING = new Date('2026-03-04T19:00:00');

const recipe = (over: Partial<PantryRecipe> & Pick<PantryRecipe, 'id' | 'core'>): PantryRecipe => ({
  title: over.id,
  emoji: '🍽️',
  blurb: 'test dish',
  cuisine: 'Test',
  course: 'main',
  tags: ['Dinner'],
  minutes: 30,
  servings: 2,
  difficulty: 1,
  tools: [],
  steps: [{ a: 'mix', i: over.core, n: 'mix it' }],
  ...over,
});

const FIXTURE: PantryRecipe[] = [
  recipe({ id: 'egg-only', core: ['egg'] }),
  recipe({ id: 'egg-tomato', core: ['egg', 'tomato'], extras: ['scallion'] }),
  recipe({ id: 'beef-heavy', core: ['beef', 'wine', 'thyme'], difficulty: 3, minutes: 120 }),
  recipe({ id: 'oven-dish', core: ['potato'], tools: ['oven'] }),
  recipe({ id: 'side-salad', core: ['cucumber'], course: 'side' }),
  recipe({ id: 'soup-pot', core: ['tomato'], course: 'soup' }),
  recipe({ id: 'sweet-thing', core: ['banana'], course: 'dessert' }),
];

describe('matchRecipes', () => {
  it('offers three modes with distinct hints', () => {
    expect(MATCH_MODES.map((mode) => mode.id)).toEqual(['flexible', 'exact', 'survival']);
    expect(new Set(MATCH_MODES.map((mode) => mode.hint)).size).toBe(3);
  });

  it('shows the whole book before anything is selected', () => {
    const results = matchRecipes({ pantry: [], cookware: [], mode: 'flexible', now: EVENING }, FIXTURE);
    expect(results).toHaveLength(FIXTURE.length);
  });

  it('ranks by appeal, not coverage, while the kitchen is empty', () => {
    const quickDinner = recipe({ id: 'quick', core: ['egg'], minutes: 10, tags: ['Dinner'] });
    const slowProject = recipe({ id: 'slow', core: ['egg'], minutes: 120, difficulty: 3, tags: ['Dinner'] });
    const results = matchRecipes({ pantry: [], cookware: [], mode: 'flexible', now: EVENING }, [
      slowProject,
      quickDinner,
    ]);

    expect(results.map((match) => match.recipe.id)).toEqual(['quick', 'slow']);
    expect(results[0].ranking).toBe('discovery');
    // A "2 ingredients away" badge is noise when nothing has been picked yet.
    expect(results[0].reason).toBe(quickDinner.blurb);
  });

  it('switches to pantry ranking as soon as something is selected', () => {
    const [match] = matchRecipes({ pantry: ['egg'], cookware: [], mode: 'flexible', now: EVENING }, FIXTURE);
    expect(match.ranking).toBe('pantry');
  });

  it('flexible keeps dishes that share at least one ingredient', () => {
    const results = matchRecipes({ pantry: ['egg'], cookware: [], mode: 'flexible', now: EVENING }, FIXTURE);
    expect(results.map((match) => match.recipe.id).sort()).toEqual(['egg-only', 'egg-tomato']);
  });

  it('exact only keeps dishes with every core ingredient present', () => {
    const results = matchRecipes({ pantry: ['egg'], cookware: [], mode: 'exact', now: EVENING }, FIXTURE);
    expect(results.map((match) => match.recipe.id)).toEqual(['egg-only']);
  });

  it('survival ignores optional extras but rejects hard or slow dishes', () => {
    // egg-tomato is missing its extra (scallion) and still qualifies.
    const results = matchRecipes(
      { pantry: ['egg', 'tomato'], cookware: [], mode: 'survival', now: EVENING },
      FIXTURE,
    );
    expect(results.map((match) => match.recipe.id).sort()).toEqual([
      'egg-only',
      'egg-tomato',
      'soup-pot',
    ]);

    const slowAndHard = matchRecipes(
      { pantry: ['beef', 'wine', 'thyme'], cookware: [], mode: 'survival', now: EVENING },
      FIXTURE,
    );
    expect(slowAndHard).toEqual([]);
  });

  it('survival still turns up dishes for a normal starter pantry', () => {
    const results = matchRecipes(
      { pantry: suggestStarterPantry(), cookware: [], mode: 'survival', now: EVENING },
      PANTRY_RECIPES,
    );
    expect(results.length).toBeGreaterThan(0);
    results.forEach((match) => {
      expect(match.missingCore).toEqual([]);
      expect(match.recipe.minutes).toBeLessThanOrEqual(30);
    });
  });

  it('treats staples as always available', () => {
    const staple = recipe({ id: 'salted-egg', core: ['egg', 'salt', 'olive_oil'] });
    const results = matchRecipes({ pantry: ['egg'], cookware: [], mode: 'exact', now: EVENING }, [staple]);
    expect(results).toHaveLength(1);
    expect(results[0].missingCore).toEqual([]);
  });

  it('drops dishes needing cookware the cook did not select', () => {
    const results = matchRecipes(
      { pantry: ['potato'], cookware: ['skillet'], mode: 'flexible', now: EVENING },
      FIXTURE,
    );
    expect(results.map((match) => match.recipe.id)).not.toContain('oven-dish');
  });

  it('keeps oven dishes when no cookware filter is applied', () => {
    const results = matchRecipes({ pantry: ['potato'], cookware: [], mode: 'flexible', now: EVENING }, FIXTURE);
    expect(results.map((match) => match.recipe.id)).toContain('oven-dish');
  });

  it('ignores prep tools the cook is assumed to own', () => {
    const knifeDish = recipe({ id: 'knife-dish', core: ['egg'], tools: ['knife', 'cutting_board'] });
    const results = matchRecipes(
      { pantry: ['egg'], cookware: ['skillet'], mode: 'flexible', now: EVENING },
      [knifeDish],
    );
    expect(results).toHaveLength(1);
  });

  it('ranks fully-stocked dishes above partial ones', () => {
    const results = matchRecipes(
      { pantry: ['egg', 'tomato', 'scallion', 'beef'], cookware: [], mode: 'flexible', now: EVENING },
      FIXTURE,
    );
    expect(results[0].recipe.id).toBe('egg-tomato');
    expect(results[0].readyNow).toBe(true);
  });

  it('nudges favorites up and recently cooked dishes down', () => {
    const base = { pantry: ['egg'], cookware: [], mode: 'flexible' as const, now: EVENING };
    const plain = matchRecipes(base, FIXTURE);
    const favored = matchRecipes({ ...base, favorites: ['egg-tomato'] }, FIXTURE);
    const recent = matchRecipes({ ...base, recentlyCooked: ['egg-only'] }, FIXTURE);

    const scoreOf = (list: ReturnType<typeof matchRecipes>, id: string) =>
      list.find((match) => match.recipe.id === id)!.score;

    expect(scoreOf(favored, 'egg-tomato')).toBeGreaterThan(scoreOf(plain, 'egg-tomato'));
    expect(scoreOf(recent, 'egg-only')).toBeLessThan(scoreOf(plain, 'egg-only'));
  });

  it('reports what is missing in plain language', () => {
    const [match] = matchRecipes({ pantry: ['egg'], cookware: [], mode: 'flexible', now: EVENING }, [
      recipe({ id: 'one-away', core: ['egg', 'tomato'] }),
    ]);
    expect(match.missingCore).toEqual(['tomato']);
    expect(match.reason).toBe('One ingredient away');
    expect(match.readyNow).toBe(false);
  });

  it('produces a stable ordering for the same input', () => {
    const input = { pantry: ['egg', 'tomato'], cookware: [], mode: 'flexible' as const, now: EVENING };
    expect(matchRecipes(input, FIXTURE).map((m) => m.recipe.id)).toEqual(
      matchRecipes(input, FIXTURE).map((m) => m.recipe.id),
    );
  });
});

describe('mealSlotFor', () => {
  it('maps the clock onto a meal', () => {
    expect(mealSlotFor(new Date('2026-03-04T08:00:00'))).toBe('breakfast');
    expect(mealSlotFor(new Date('2026-03-04T12:30:00'))).toBe('lunch');
    expect(mealSlotFor(new Date('2026-03-04T19:00:00'))).toBe('dinner');
    expect(mealSlotFor(new Date('2026-03-04T23:30:00'))).toBe('late');
  });
});

describe('buildMenu', () => {
  const base = {
    pantry: ['egg', 'tomato', 'scallion', 'cucumber', 'banana', 'potato'],
    cookware: [],
    mode: 'flexible' as const,
    now: EVENING,
  };

  it('returns the requested number of dishes', () => {
    expect(buildMenu({ ...base, dishCount: 3 }, FIXTURE)).toHaveLength(3);
  });

  it('never repeats a dish', () => {
    const menu = buildMenu({ ...base, dishCount: 5 }, FIXTURE);
    expect(new Set(menu.map((match) => match.recipe.id)).size).toBe(menu.length);
  });

  it('mixes courses instead of stacking mains', () => {
    const menu = buildMenu({ ...base, dishCount: 3 }, FIXTURE);
    expect(new Set(menu.map((match) => match.recipe.course)).size).toBeGreaterThan(1);
  });

  it('keeps locked dishes across rolls', () => {
    const menu = buildMenu({ ...base, dishCount: 3, locked: ['soup-pot'], seed: 7 }, FIXTURE);
    expect(menu.map((match) => match.recipe.id)).toContain('soup-pot');
  });

  it('returns nothing when nothing matches', () => {
    expect(buildMenu({ ...base, pantry: ['egg'], mode: 'survival', dishCount: 3 }, [
      recipe({ id: 'impossible', core: ['lamb'] }),
    ])).toEqual([]);
  });

  it('does not exceed the corpus size', () => {
    const menu = buildMenu({ ...base, pantry: ['egg'], mode: 'exact', dishCount: 5 }, FIXTURE);
    expect(menu.length).toBeLessThanOrEqual(FIXTURE.length);
  });
});

describe('shoppingListFor', () => {
  it('collects missing core ingredients without duplicates', () => {
    const matches = matchRecipes({ pantry: ['egg'], cookware: [], mode: 'flexible', now: EVENING }, [
      recipe({ id: 'a', core: ['egg', 'tomato'] }),
      recipe({ id: 'b', core: ['egg', 'tomato', 'basil'] }),
    ]);
    expect(shoppingListFor(matches).sort()).toEqual(['basil', 'tomato']);
  });

  it('is empty when everything is in the kitchen', () => {
    const matches = matchRecipes({ pantry: ['egg'], cookware: [], mode: 'exact', now: EVENING }, [
      recipe({ id: 'a', core: ['egg'] }),
    ]);
    expect(shoppingListFor(matches)).toEqual([]);
  });
});

describe('suggestStarterPantry', () => {
  it('unlocks real dishes from the shipped corpus', () => {
    const results = matchRecipes(
      { pantry: suggestStarterPantry(), cookware: [], mode: 'exact', now: EVENING },
      PANTRY_RECIPES,
    );
    expect(results.length).toBeGreaterThan(3);
  });
});
