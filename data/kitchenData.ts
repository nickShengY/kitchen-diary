
import { Ingredient, Tool, CookingAction } from '../types';
import { Utensils, Flame, Box, Droplets, Waves, RotateCcw, Ban, ChefHat, Scissors, Anchor } from 'lucide-react';

export const INGREDIENTS: Ingredient[] = [
  // Vegetables
  { id: 'tomato', name: 'Tomato', emoji: '🍅', category: 'vegetable', defaultUnit: 'pcs', physicalProperties: ['peelable', 'choppable', 'solid', 'cookable'] },
  { id: 'carrot', name: 'Carrot', emoji: '🥕', category: 'vegetable', defaultUnit: 'pcs', physicalProperties: ['peelable', 'choppable', 'solid', 'cookable', 'grateable'] },
  { id: 'potato', name: 'Potato', emoji: '🥔', category: 'vegetable', defaultUnit: 'pcs', physicalProperties: ['peelable', 'choppable', 'solid', 'cookable'] },
  { id: 'onion', name: 'Onion', emoji: '🧅', category: 'vegetable', defaultUnit: 'pcs', physicalProperties: ['peelable', 'choppable', 'solid', 'cookable'] },
  { id: 'garlic', name: 'Garlic', emoji: '🧄', category: 'vegetable', defaultUnit: 'cloves', physicalProperties: ['peelable', 'choppable', 'solid', 'cookable'] },
  { id: 'broccoli', name: 'Broccoli', emoji: '🥦', category: 'vegetable', defaultUnit: 'head', physicalProperties: ['choppable', 'solid', 'cookable'] },
  { id: 'spinach', name: 'Spinach', emoji: '🍃', category: 'vegetable', defaultUnit: 'cup', physicalProperties: ['choppable', 'solid', 'cookable'] },
  
  // Meats
  { id: 'beef', name: 'Beef', emoji: '🥩', category: 'meat', defaultUnit: 'lb', physicalProperties: ['choppable', 'solid', 'cookable', 'meat'] },
  { id: 'chicken', name: 'Chicken', emoji: '🍗', category: 'meat', defaultUnit: 'lb', physicalProperties: ['choppable', 'solid', 'cookable', 'meat'] },
  { id: 'pork', name: 'Pork', emoji: '🥓', category: 'meat', defaultUnit: 'lb', physicalProperties: ['choppable', 'solid', 'cookable', 'meat'] },
  { id: 'fish', name: 'Fish', emoji: '🐟', category: 'seafood', defaultUnit: 'fillet', physicalProperties: ['choppable', 'solid', 'cookable', 'meat'] },
  { id: 'shrimp', name: 'Shrimp', emoji: '🦐', category: 'seafood', defaultUnit: 'pcs', physicalProperties: ['peelable', 'solid', 'cookable', 'meat'] },

  // Dairy & Egg
  { id: 'egg', name: 'Egg', emoji: '🥚', category: 'dairy', defaultUnit: 'pcs', physicalProperties: ['peelable', 'solid', 'cookable', 'mixable'] }, // Peelable if boiled, technically
  { id: 'milk', name: 'Milk', emoji: '🥛', category: 'dairy', defaultUnit: 'cup', physicalProperties: ['liquid', 'mixable', 'cookable'] },
  { id: 'cheese', name: 'Cheese', emoji: '🧀', category: 'dairy', defaultUnit: 'cup', physicalProperties: ['grateable', 'solid', 'cookable'] },
  { id: 'butter', name: 'Butter', emoji: '🧈', category: 'dairy', defaultUnit: 'tbsp', physicalProperties: ['solid', 'mixable', 'cookable'] },

  // Grains
  { id: 'rice', name: 'Rice', emoji: '🍚', category: 'grain', defaultUnit: 'cup', physicalProperties: ['solid', 'cookable'] },
  { id: 'pasta', name: 'Pasta', emoji: '🍝', category: 'grain', defaultUnit: 'g', physicalProperties: ['solid', 'cookable'] },
  { id: 'bread', name: 'Bread', emoji: '🍞', category: 'grain', defaultUnit: 'slice', physicalProperties: ['solid', 'choppable'] },
  { id: 'flour', name: 'Flour', emoji: '🥡', category: 'grain', defaultUnit: 'cup', physicalProperties: ['solid', 'mixable'] },

  // Fruits
  { id: 'apple', name: 'Apple', emoji: '🍎', category: 'fruit', defaultUnit: 'pcs', physicalProperties: ['peelable', 'choppable', 'solid'] },
  { id: 'lemon', name: 'Lemon', emoji: '🍋', category: 'fruit', defaultUnit: 'pcs', physicalProperties: ['peelable', 'choppable', 'solid', 'liquid'] }, // Juice
  { id: 'banana', name: 'Banana', emoji: '🍌', category: 'fruit', defaultUnit: 'pcs', physicalProperties: ['peelable', 'solid'] },

  // Spices & Condiments
  { id: 'salt', name: 'Salt', emoji: '🧂', category: 'spice', defaultUnit: 'tsp', physicalProperties: ['solid', 'mixable'] },
  { id: 'pepper', name: 'Pepper', emoji: '⚫', category: 'spice', defaultUnit: 'tsp', physicalProperties: ['solid', 'mixable'] },
  { id: 'oil', name: 'Oil', emoji: '🫗', category: 'liquid', defaultUnit: 'tbsp', physicalProperties: ['liquid', 'mixable', 'cookable'] },
  { id: 'sugar', name: 'Sugar', emoji: '🍬', category: 'spice', defaultUnit: 'tsp', physicalProperties: ['solid', 'mixable'] },
  { id: 'chili', name: 'Chili', emoji: '🌶️', category: 'spice', defaultUnit: 'pcs', physicalProperties: ['choppable', 'solid', 'cookable'] },
  { id: 'soysauce', name: 'Soy Sauce', emoji: '🏺', category: 'condiment', defaultUnit: 'tbsp', physicalProperties: ['liquid', 'mixable', 'cookable'] },
  
  // Liquids
  { id: 'water', name: 'Water', emoji: '💧', category: 'liquid', defaultUnit: 'cup', physicalProperties: ['liquid', 'mixable', 'cookable'] },
  { id: 'wine', name: 'Wine', emoji: '🍷', category: 'liquid', defaultUnit: 'cup', physicalProperties: ['liquid', 'mixable', 'cookable'] },
];

export const TOOLS: Tool[] = [
  // Prep
  { id: 'knife', name: 'Chef Knife', icon: Utensils, type: 'prep' },
  { id: 'bowl', name: 'Mixing Bowl', icon: Utensils, type: 'prep' },
  { id: 'peeler', name: 'Peeler', icon: Ban, type: 'prep' },
  
  // Cook
  { id: 'pan', name: 'Frying Pan', icon: Box, type: 'cook' },
  { id: 'pot', name: 'Stock Pot', icon: Utensils, type: 'cook' },
  { id: 'oven', name: 'Oven', icon: Flame, type: 'appliance' },
  { id: 'blender', name: 'Blender', icon: RotateCcw, type: 'appliance' },
  { id: 'grill', name: 'Grill', icon: Waves, type: 'cook' },
];

export const ACTIONS: CookingAction[] = [
  // Prep Actions
  { id: 'chop', name: 'Chop', verb: 'Chopped', icon: '🔪', requiresToolId: 'knife', validProperties: ['choppable'] },
  { id: 'dice', name: 'Dice', verb: 'Diced', icon: '🧊', requiresToolId: 'knife', validProperties: ['choppable'] },
  { id: 'slice', name: 'Slice', verb: 'Sliced', icon: '🍞', requiresToolId: 'knife', validProperties: ['choppable', 'solid'] },
  { id: 'mince', name: 'Mince', verb: 'Minced', icon: '🤏', requiresToolId: 'knife', validProperties: ['choppable'] },
  { id: 'peel', name: 'Peel', verb: 'Peeled', icon: '🍌', requiresToolId: 'peeler', validProperties: ['peelable'] },
  { id: 'mix', name: 'Mix', verb: 'Mixed', icon: '🥣', requiresToolId: 'bowl', validProperties: ['mixable', 'solid', 'liquid'] },
  { id: 'whisk', name: 'Whisk', verb: 'Whisked', icon: '🌪️', requiresToolId: 'bowl', validProperties: ['liquid', 'mixable'] },
  
  // Cooking Actions
  { id: 'fry', name: 'Stir Fry', verb: 'Fried', icon: '🍳', requiresToolId: 'pan', requiresHeat: true, validProperties: ['cookable', 'solid'] },
  { id: 'sear', name: 'Sear', verb: 'Seared', icon: '🔥', requiresToolId: 'pan', requiresHeat: true, validProperties: ['meat', 'cookable'] },
  { id: 'boil', name: 'Boil', verb: 'Boiled', icon: '🥘', requiresToolId: 'pot', requiresHeat: true, validProperties: ['cookable', 'solid'] },
  { id: 'simmer', name: 'Simmer', verb: 'Simmered', icon: '🍲', requiresToolId: 'pot', requiresHeat: true, validProperties: ['liquid', 'cookable'] },
  { id: 'bake', name: 'Bake', verb: 'Baked', icon: '🥯', requiresToolId: 'oven', requiresHeat: true, validProperties: ['cookable'] },
  { id: 'roast', name: 'Roast', verb: 'Roasted', icon: '🍗', requiresToolId: 'oven', requiresHeat: true, validProperties: ['meat', 'vegetable'] },
  { id: 'blend', name: 'Blend', verb: 'Blended', icon: '🥤', requiresToolId: 'blender', validProperties: ['solid', 'liquid', 'mixable'] },
  { id: 'grill', name: 'Grill', verb: 'Grilled', icon: '🌭', requiresToolId: 'grill', requiresHeat: true, validProperties: ['meat', 'vegetable', 'cookable'] },
  
  // Finish
  { id: 'plate', name: 'Plate', verb: 'Plated', icon: '🍽️' },
  { id: 'garnish', name: 'Garnish', verb: 'Garnished', icon: '🌿' },
];

export const TEMPERATURES = ['Low', 'Medium', 'High', '300°F', '350°F', '400°F', '450°F'];
export const TIMES = ['1 min', '5 mins', '10 mins', '15 mins', '30 mins', '45 mins', '1 hr', '2 hrs'];
export const WATER_LEVELS = ['Splash', '1/4 cup', '1 cup', '2 cups', 'Covered'];
