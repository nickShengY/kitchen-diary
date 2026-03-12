

export type Category = 'vegetable' | 'meat' | 'dairy' | 'spice' | 'grain' | 'fruit' | 'liquid' | 'seafood' | 'condiment' | 'herb';

export type PhysicalProperty = 'peelable' | 'choppable' | 'liquid' | 'solid' | 'mixable' | 'cookable' | 'grateable' | 'meat' | 'vegetable';

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
  type: 'prep' | 'cook' | 'appliance';
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

export interface RecipeStep {
  id: string;
  station: 'prep' | 'cook' | 'finish';
  ingredients: { id: string; amount: string; unit: string }[];
  toolId: string;
  actionId: string;
  settings?: {
    temperature?: string; // e.g., "350°F" or "High"
    duration?: string;    // e.g., "10 mins"
    waterLevel?: string;  // e.g., "1 cup"
    speed?: string;       // e.g., "Low"
  };
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
  BUILDER = 'BUILDER',
  DECIDER = 'DECIDER',
  PROFILE = 'PROFILE',
}

export interface UserProfile {
  id: string;
  name: string;
  avatar: string; // Emoji
  bio: string;
  favorites: string[];
  myRecipes: Recipe[];
  recipesCount?: number;
  followersCount?: number;
  likesReceived?: number;
}

// Decider Wheel Types
export interface CuisineCategory {
  id: string;
  name: string;
  emoji: string;
  dishes: string[]; // List of dish names
}

export interface MenuItem {
  name: string;
  description?: string;
}
