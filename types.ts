export type Category =
  | 'vegetable'
  | 'meat'
  | 'dairy'
  | 'spice'
  | 'grain'
  | 'legume'
  | 'fruit'
  | 'liquid'
  | 'seafood'
  | 'condiment'
  | 'herb';

export type PhysicalProperty =
  | 'peelable'
  | 'choppable'
  | 'liquid'
  | 'solid'
  | 'mixable'
  | 'cookable'
  | 'grateable'
  | 'meat'
  | 'vegetable';

export interface Ingredient {
  id: string;
  name: string;
  emoji: string;
  category: Category;
  defaultUnit: string;
  physicalProperties: PhysicalProperty[];
}

export interface Tool {
  id: string;
  name: string;
  icon: any; // Lucide icon component
  type: 'prep' | 'cook' | 'appliance' | 'finish';
}

export interface CookingAction {
  id: string;
  name: string;
  verb: string;
  icon: string;
  requiresToolId?: string;
  requiresHeat?: boolean;
  validProperties?: PhysicalProperty[]; // What kind of ingredient can this be done to?
}

export interface RecipeStepSettings {
  temperature?: string;
  duration?: string;
  waterLevel?: string;
  speed?: string;
  cutShape?: string;
  cookMethod?: string;
  oil?: string;
  liquid?: string;
  garnish?: string;
  texture?: string;
}

export interface RecipeStep {
  id: string;
  station: 'prep' | 'cook' | 'finish';
  ingredients: { id: string; amount: string; unit: string }[];
  toolId: string;
  actionId: string;
  settings?: RecipeStepSettings;
  notes?: string;
}

export interface Recipe {
  id: string;
  title: string;
  description?: string;
  authorId: string;
  authorName: string;
  authorAvatar: string;
  steps: RecipeStep[];
  likes?: number;
  tags: string[];
  createdAt: number;
  imageUrl?: string;
}

export interface SocialPost extends Recipe {
  comments?: number;
  description: string;
}

export enum AppView {
  COMMUNITY = 'COMMUNITY',
  KITCHEN = 'KITCHEN',
  BUILDER = 'BUILDER',
  DECIDER = 'DECIDER',
  PROFILE = 'PROFILE',
}

export interface UserProfile {
  id: string;
  name: string;
  avatar: string; // Image URL or emoji fallback
  bio: string;
  /** Server-authoritative subscription status, when the account is signed in. */
  isVip?: boolean;
  vipExpiresAt?: number;
  favorites: string[];
  myRecipes: Recipe[];
  recipesCount?: number;
  followersCount?: number;
  likesReceived?: number;
}

export interface CuisineCategory {
  id: string;
  name: string;
  emoji: string;
  dishes: string[];
}

export interface MenuItem {
  name: string;
  description?: string;
}
