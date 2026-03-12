import React, { ReactElement } from 'react';
import { render, RenderOptions } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { vi } from 'vitest';
import { Ingredient, Tool, CookingAction, RecipeStep, Recipe, UserProfile, SocialPost, CuisineCategory } from '../../types';

// Custom render function with providers if needed
interface CustomRenderOptions extends Omit<RenderOptions, 'wrapper'> {
  // Add any provider props here if needed
}

export function renderWithProviders(
  ui: ReactElement,
  options?: CustomRenderOptions
) {
  const user = userEvent.setup();

  return {
    user,
    ...render(ui, { ...options }),
  };
}

// Re-export everything
export * from '@testing-library/react';
export { userEvent };

// Mock data factories
export const createMockIngredient = (overrides: Partial<Ingredient> = {}): Ingredient => ({
  id: 'test-ingredient',
  name: 'Test Ingredient',
  emoji: '🍅',
  category: 'vegetable',
  defaultUnit: 'pcs',
  physicalProperties: ['choppable', 'solid', 'cookable'],
  ...overrides,
});

export const createMockTool = (overrides: Partial<Tool> = {}): Tool => ({
  id: 'test-tool',
  name: 'Test Tool',
  icon: () => null,
  type: 'prep',
  ...overrides,
});

export const createMockAction = (overrides: Partial<CookingAction> = {}): CookingAction => ({
  id: 'test-action',
  name: 'Test Action',
  verb: 'Tested',
  icon: '🔪',
  validProperties: ['choppable'],
  ...overrides,
});

export const createMockRecipeStep = (overrides: Partial<RecipeStep> = {}): RecipeStep => ({
  id: 'step-1',
  station: 'prep',
  ingredients: [{ id: 'tomato', amount: '2', unit: 'pcs' }],
  toolId: 'knife',
  actionId: 'chop',
  settings: { duration: '5 mins' },
  ...overrides,
});

export const createMockRecipe = (overrides: Partial<Recipe> = {}): Recipe => ({
  id: 'recipe-1',
  title: 'Test Recipe',
  description: 'A test recipe description',
  authorId: 'author-1',
  authorName: 'Test Chef',
  authorAvatar: '👨‍🍳',
  steps: [createMockRecipeStep()],
  likes: 10,
  tags: ['test', 'breakfast'],
  createdAt: Date.now(),
  imageUrl: 'https://example.com/image.jpg',
  ...overrides,
});

export const createMockSocialPost = (overrides: Partial<SocialPost> = {}): SocialPost => ({
  ...createMockRecipe(),
  comments: 5,
  description: 'A social post description',
  ...overrides,
});

export const createMockUserProfile = (overrides: Partial<UserProfile> = {}): UserProfile => ({
  id: 'user-1',
  name: 'Test User',
  avatar: '👨‍🍳',
  bio: 'Test bio',
  favorites: [],
  myRecipes: [],
  ...overrides,
});

export const createMockCuisineCategory = (overrides: Partial<CuisineCategory> = {}): CuisineCategory => ({
  id: 'cuisine-1',
  name: 'Italian',
  emoji: '🍝',
  dishes: ['Pasta', 'Pizza', 'Risotto'],
  ...overrides,
});

// Mock functions
export const createMockGeminiResponse = (text: string) => ({
  text,
});

// Wait utilities
export const waitForAnimation = (ms: number = 300) =>
  new Promise(resolve => setTimeout(resolve, ms));

// Assert helpers
export const assertElementExists = (element: HTMLElement | null): asserts element is HTMLElement => {
  if (!element) {
    throw new Error('Element does not exist');
  }
};

// Event simulation helpers
export const createMockFile = (name: string = 'test.jpg', type: string = 'image/jpeg'): File => {
  return new File(['test content'], name, { type });
};

export const createMockChangeEvent = (file: File) => ({
  target: {
    files: [file],
  },
});
