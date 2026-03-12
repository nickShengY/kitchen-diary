import { describe, it, expect } from 'vitest';
import {
  createMockIngredient,
  createMockTool,
  createMockAction,
  createMockRecipeStep,
  createMockRecipe,
  createMockSocialPost,
  createMockUserProfile,
  createMockCuisineCategory,
} from '../utils/test-utils';
import { AppView } from '../../types';

describe('types', () => {
  describe('Ingredient type', () => {
    it('should create valid ingredient with required fields', () => {
      const ingredient = createMockIngredient();

      expect(ingredient.id).toBeDefined();
      expect(ingredient.name).toBeDefined();
      expect(ingredient.emoji).toBeDefined();
      expect(ingredient.category).toBeDefined();
      expect(ingredient.defaultUnit).toBeDefined();
      expect(ingredient.physicalProperties).toBeDefined();
    });

    it('should accept category overrides', () => {
      const ingredient = createMockIngredient({ category: 'meat' });
      expect(ingredient.category).toBe('meat');
    });

    it('should accept all valid categories', () => {
      const categories = [
        'vegetable',
        'meat',
        'dairy',
        'spice',
        'grain',
        'fruit',
        'liquid',
        'seafood',
        'condiment',
        'herb',
      ] as const;

      categories.forEach((category) => {
        const ingredient = createMockIngredient({ category });
        expect(ingredient.category).toBe(category);
      });
    });

    it('should accept physical properties array', () => {
      const ingredient = createMockIngredient({
        physicalProperties: ['peelable', 'choppable', 'solid'],
      });

      expect(ingredient.physicalProperties).toContain('peelable');
      expect(ingredient.physicalProperties).toContain('choppable');
      expect(ingredient.physicalProperties).toContain('solid');
    });

    it('should accept all valid physical properties', () => {
      const properties = [
        'peelable',
        'choppable',
        'liquid',
        'solid',
        'mixable',
        'cookable',
        'grateable',
        'meat',
        'vegetable',
      ] as const;

      const ingredient = createMockIngredient({
        physicalProperties: [...properties],
      });

      properties.forEach((prop) => {
        expect(ingredient.physicalProperties).toContain(prop);
      });
    });
  });

  describe('Tool type', () => {
    it('should create valid tool with required fields', () => {
      const tool = createMockTool();

      expect(tool.id).toBeDefined();
      expect(tool.name).toBeDefined();
      expect(tool.icon).toBeDefined();
      expect(tool.type).toBeDefined();
    });

    it('should accept type overrides', () => {
      const tool = createMockTool({ type: 'cook' });
      expect(tool.type).toBe('cook');
    });

    it('should accept all valid tool types', () => {
      const types = ['prep', 'cook', 'appliance'] as const;

      types.forEach((type) => {
        const tool = createMockTool({ type });
        expect(tool.type).toBe(type);
      });
    });
  });

  describe('CookingAction type', () => {
    it('should create valid action with required fields', () => {
      const action = createMockAction();

      expect(action.id).toBeDefined();
      expect(action.name).toBeDefined();
      expect(action.verb).toBeDefined();
      expect(action.icon).toBeDefined();
    });

    it('should accept optional requiresToolId', () => {
      const action = createMockAction({ requiresToolId: 'knife' });
      expect(action.requiresToolId).toBe('knife');
    });

    it('should accept optional requiresHeat', () => {
      const action = createMockAction({ requiresHeat: true });
      expect(action.requiresHeat).toBe(true);
    });

    it('should accept optional validProperties', () => {
      const action = createMockAction({
        validProperties: ['choppable', 'solid'],
      });
      expect(action.validProperties).toContain('choppable');
      expect(action.validProperties).toContain('solid');
    });

    it('should allow action without optional fields', () => {
      const action = createMockAction({
        requiresToolId: undefined,
        requiresHeat: undefined,
        validProperties: undefined,
      });

      expect(action.requiresToolId).toBeUndefined();
      expect(action.requiresHeat).toBeUndefined();
      expect(action.validProperties).toBeUndefined();
    });
  });

  describe('RecipeStep type', () => {
    it('should create valid step with required fields', () => {
      const step = createMockRecipeStep();

      expect(step.id).toBeDefined();
      expect(step.station).toBeDefined();
      expect(step.ingredients).toBeDefined();
      expect(step.toolId).toBeDefined();
      expect(step.actionId).toBeDefined();
    });

    it('should accept all valid station types', () => {
      const stations = ['prep', 'cook', 'finish'] as const;

      stations.forEach((station) => {
        const step = createMockRecipeStep({ station });
        expect(step.station).toBe(station);
      });
    });

    it('should accept ingredient list', () => {
      const step = createMockRecipeStep({
        ingredients: [
          { id: 'tomato', amount: '2', unit: 'pcs' },
          { id: 'onion', amount: '1', unit: 'pcs' },
        ],
      });

      expect(step.ingredients).toHaveLength(2);
      expect(step.ingredients[0].id).toBe('tomato');
      expect(step.ingredients[1].id).toBe('onion');
    });

    it('should accept optional settings', () => {
      const step = createMockRecipeStep({
        settings: {
          temperature: '350°F',
          duration: '30 mins',
          waterLevel: '1 cup',
          speed: 'High',
        },
      });

      expect(step.settings?.temperature).toBe('350°F');
      expect(step.settings?.duration).toBe('30 mins');
      expect(step.settings?.waterLevel).toBe('1 cup');
      expect(step.settings?.speed).toBe('High');
    });

    it('should accept optional notes', () => {
      const step = createMockRecipeStep({ notes: 'Stir frequently' });
      expect(step.notes).toBe('Stir frequently');
    });

    it('should allow step without optional fields', () => {
      const step = createMockRecipeStep({
        settings: undefined,
        notes: undefined,
      });

      expect(step.settings).toBeUndefined();
      expect(step.notes).toBeUndefined();
    });
  });

  describe('Recipe type', () => {
    it('should create valid recipe with required fields', () => {
      const recipe = createMockRecipe();

      expect(recipe.id).toBeDefined();
      expect(recipe.title).toBeDefined();
      expect(recipe.authorId).toBeDefined();
      expect(recipe.authorName).toBeDefined();
      expect(recipe.authorAvatar).toBeDefined();
      expect(recipe.steps).toBeDefined();
      expect(recipe.likes).toBeDefined();
      expect(recipe.tags).toBeDefined();
      expect(recipe.createdAt).toBeDefined();
    });

    it('should accept optional description', () => {
      const recipe = createMockRecipe({
        description: 'A delicious test recipe',
      });
      expect(recipe.description).toBe('A delicious test recipe');
    });

    it('should accept optional imageUrl', () => {
      const recipe = createMockRecipe({
        imageUrl: 'https://example.com/image.jpg',
      });
      expect(recipe.imageUrl).toBe('https://example.com/image.jpg');
    });

    it('should accept steps array', () => {
      const steps = [
        createMockRecipeStep({ id: 'step-1' }),
        createMockRecipeStep({ id: 'step-2' }),
      ];
      const recipe = createMockRecipe({ steps });

      expect(recipe.steps).toHaveLength(2);
    });

    it('should accept tags array', () => {
      const recipe = createMockRecipe({
        tags: ['breakfast', 'quick', 'healthy'],
      });

      expect(recipe.tags).toContain('breakfast');
      expect(recipe.tags).toContain('quick');
      expect(recipe.tags).toContain('healthy');
    });

    it('should accept numeric likes', () => {
      const recipe = createMockRecipe({ likes: 100 });
      expect(recipe.likes).toBe(100);
    });

    it('should accept numeric createdAt timestamp', () => {
      const timestamp = Date.now();
      const recipe = createMockRecipe({ createdAt: timestamp });
      expect(recipe.createdAt).toBe(timestamp);
    });
  });

  describe('SocialPost type', () => {
    it('should extend Recipe with additional fields', () => {
      const post = createMockSocialPost();

      // Recipe fields
      expect(post.id).toBeDefined();
      expect(post.title).toBeDefined();
      expect(post.steps).toBeDefined();

      // SocialPost specific fields
      expect(post.comments).toBeDefined();
      expect(post.description).toBeDefined();
    });

    it('should accept comments count', () => {
      const post = createMockSocialPost({ comments: 25 });
      expect(post.comments).toBe(25);
    });

    it('should require description', () => {
      const post = createMockSocialPost({
        description: 'Amazing recipe everyone loved!',
      });
      expect(post.description).toBe('Amazing recipe everyone loved!');
    });
  });

  describe('UserProfile type', () => {
    it('should create valid user profile with required fields', () => {
      const user = createMockUserProfile();

      expect(user.id).toBeDefined();
      expect(user.name).toBeDefined();
      expect(user.avatar).toBeDefined();
      expect(user.bio).toBeDefined();
      expect(user.favorites).toBeDefined();
      expect(user.myRecipes).toBeDefined();
    });

    it('should accept favorites array', () => {
      const user = createMockUserProfile({
        favorites: ['recipe-1', 'recipe-2', 'recipe-3'],
      });

      expect(user.favorites).toHaveLength(3);
      expect(user.favorites).toContain('recipe-1');
    });

    it('should accept myRecipes array', () => {
      const recipes = [
        createMockRecipe({ id: 'my-recipe-1' }),
        createMockRecipe({ id: 'my-recipe-2' }),
      ];
      const user = createMockUserProfile({ myRecipes: recipes });

      expect(user.myRecipes).toHaveLength(2);
    });

    it('should accept avatar emoji', () => {
      const user = createMockUserProfile({ avatar: '👩‍🍳' });
      expect(user.avatar).toBe('👩‍🍳');
    });
  });

  describe('CuisineCategory type', () => {
    it('should create valid cuisine category with required fields', () => {
      const cuisine = createMockCuisineCategory();

      expect(cuisine.id).toBeDefined();
      expect(cuisine.name).toBeDefined();
      expect(cuisine.emoji).toBeDefined();
      expect(cuisine.dishes).toBeDefined();
    });

    it('should accept dishes array', () => {
      const cuisine = createMockCuisineCategory({
        dishes: ['Pizza', 'Pasta', 'Risotto', 'Lasagna'],
      });

      expect(cuisine.dishes).toHaveLength(4);
      expect(cuisine.dishes).toContain('Pizza');
    });

    it('should accept emoji', () => {
      const cuisine = createMockCuisineCategory({ emoji: '🍕' });
      expect(cuisine.emoji).toBe('🍕');
    });
  });

  describe('AppView enum', () => {
    it('should have COMMUNITY view', () => {
      expect(AppView.COMMUNITY).toBe('COMMUNITY');
    });

    it('should have BUILDER view', () => {
      expect(AppView.BUILDER).toBe('BUILDER');
    });

    it('should have DECIDER view', () => {
      expect(AppView.DECIDER).toBe('DECIDER');
    });

    it('should have PROFILE view', () => {
      expect(AppView.PROFILE).toBe('PROFILE');
    });

    it('should have exactly 4 views', () => {
      const views = Object.values(AppView);
      expect(views).toHaveLength(4);
    });
  });

  describe('type relationships', () => {
    it('RecipeStep ingredients should reference Ingredient ids', () => {
      const step = createMockRecipeStep({
        ingredients: [
          { id: 'tomato', amount: '2', unit: 'pcs' },
          { id: 'onion', amount: '1', unit: 'pcs' },
        ],
      });

      step.ingredients.forEach((ing) => {
        expect(typeof ing.id).toBe('string');
        expect(typeof ing.amount).toBe('string');
        expect(typeof ing.unit).toBe('string');
      });
    });

    it('RecipeStep toolId should reference Tool id', () => {
      const step = createMockRecipeStep({ toolId: 'knife' });
      expect(typeof step.toolId).toBe('string');
    });

    it('RecipeStep actionId should reference CookingAction id', () => {
      const step = createMockRecipeStep({ actionId: 'chop' });
      expect(typeof step.actionId).toBe('string');
    });

    it('Recipe should contain RecipeSteps', () => {
      const steps = [
        createMockRecipeStep(),
        createMockRecipeStep(),
      ];
      const recipe = createMockRecipe({ steps });

      expect(recipe.steps).toHaveLength(2);
      recipe.steps.forEach((step) => {
        expect(step).toHaveProperty('station');
        expect(step).toHaveProperty('ingredients');
        expect(step).toHaveProperty('toolId');
        expect(step).toHaveProperty('actionId');
      });
    });

    it('UserProfile myRecipes should contain Recipes', () => {
      const recipes = [createMockRecipe(), createMockRecipe()];
      const user = createMockUserProfile({ myRecipes: recipes });

      expect(user.myRecipes).toHaveLength(2);
      user.myRecipes.forEach((recipe) => {
        expect(recipe).toHaveProperty('title');
        expect(recipe).toHaveProperty('steps');
      });
    });
  });
});
