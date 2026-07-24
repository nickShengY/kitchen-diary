import { Ingredient, Tool, CookingAction, CuisineCategory, Category, PhysicalProperty } from '../types';
import { VISUAL_ACTIONS, VISUAL_INGREDIENTS, VISUAL_TOOLS } from './visualCatalog';
import {
  Utensils,
  Flame,
  Box,
  Droplets,
  Waves,
  RotateCcw,
  Ban,
  ChefHat,
  Scissors,
} from 'lucide-react';

const ingredient = (
  id: string,
  name: string,
  emoji: string,
  category: Ingredient['category'],
  defaultUnit: string,
  physicalProperties: Ingredient['physicalProperties'],
): Ingredient => ({
  id,
  name,
  emoji,
  category,
  defaultUnit,
  physicalProperties,
});

const tool = (
  id: string,
  name: string,
  icon: Tool['icon'],
  type: Tool['type'],
): Tool => ({
  id,
  name,
  icon,
  type,
});

const action = (
  id: string,
  name: string,
  verb: string,
  icon: string,
  options: Omit<CookingAction, 'id' | 'name' | 'verb' | 'icon'> = {},
): CookingAction => ({
  id,
  name,
  verb,
  icon,
  ...options,
});

const cuisine = (
  id: string,
  name: string,
  emoji: string,
  dishes: string[],
): CuisineCategory => ({
  id,
  name,
  emoji,
  dishes,
});

export interface RecipeChipOption {
  id: string;
  label: string;
  emoji: string;
  description: string;
}

const CORE_INGREDIENTS: Ingredient[] = [
  ingredient('tomato', 'Tomato', '\u{1F345}', 'vegetable', 'pcs', [
    'peelable',
    'choppable',
    'solid',
    'cookable',
    'vegetable',
  ]),
  ingredient('carrot', 'Carrot', '\u{1F955}', 'vegetable', 'pcs', [
    'peelable',
    'choppable',
    'solid',
    'cookable',
    'grateable',
    'vegetable',
  ]),
  ingredient('potato', 'Potato', '\u{1F954}', 'vegetable', 'pcs', [
    'peelable',
    'choppable',
    'solid',
    'cookable',
    'vegetable',
  ]),
  ingredient('sweet_potato', 'Sweet Potato', '\u{1F360}', 'vegetable', 'pcs', [
    'peelable',
    'choppable',
    'solid',
    'cookable',
    'vegetable',
  ]),
  ingredient('onion', 'Onion', '\u{1F9C5}', 'vegetable', 'pcs', [
    'peelable',
    'choppable',
    'solid',
    'cookable',
    'vegetable',
  ]),
  ingredient('garlic', 'Garlic', '\u{1F9C4}', 'vegetable', 'cloves', [
    'peelable',
    'choppable',
    'solid',
    'cookable',
    'vegetable',
  ]),
  ingredient('ginger', 'Ginger', '\u{1F9C4}', 'vegetable', 'thumb', [
    'peelable',
    'choppable',
    'solid',
    'cookable',
    'vegetable',
  ]),
  ingredient('broccoli', 'Broccoli', '\u{1F966}', 'vegetable', 'head', [
    'choppable',
    'solid',
    'cookable',
    'vegetable',
  ]),
  ingredient('spinach', 'Spinach', '\u{1F96C}', 'vegetable', 'cup', [
    'choppable',
    'solid',
    'cookable',
    'vegetable',
  ]),
  ingredient('mushroom', 'Mushroom', '\u{1F344}', 'vegetable', 'cup', [
    'choppable',
    'solid',
    'cookable',
    'vegetable',
  ]),
  ingredient('bell_pepper', 'Bell Pepper', '\u{1FAD1}', 'vegetable', 'pcs', [
    'choppable',
    'solid',
    'cookable',
    'vegetable',
  ]),
  ingredient('chili_pepper', 'Chili Pepper', '\u{1F336}\uFE0F', 'vegetable', 'pcs', [
    'choppable',
    'solid',
    'cookable',
    'vegetable',
  ]),
  ingredient('eggplant', 'Eggplant', '\u{1F346}', 'vegetable', 'pcs', [
    'choppable',
    'solid',
    'cookable',
    'vegetable',
  ]),
  ingredient('zucchini', 'Zucchini', '\u{1F952}', 'vegetable', 'pcs', [
    'choppable',
    'solid',
    'cookable',
    'vegetable',
  ]),
  ingredient('cucumber', 'Cucumber', '\u{1F952}', 'vegetable', 'pcs', [
    'peelable',
    'choppable',
    'solid',
    'vegetable',
  ]),
  ingredient('corn', 'Corn', '\u{1F33D}', 'vegetable', 'ear', [
    'solid',
    'cookable',
    'vegetable',
  ]),
  ingredient('cabbage', 'Cabbage', '\u{1F96C}', 'vegetable', 'head', [
    'choppable',
    'solid',
    'cookable',
    'vegetable',
  ]),
  ingredient('lettuce', 'Lettuce', '\u{1F96C}', 'vegetable', 'head', [
    'choppable',
    'solid',
    'vegetable',
  ]),
  ingredient('bok_choy', 'Bok Choy', '\u{1F96C}', 'vegetable', 'head', [
    'choppable',
    'solid',
    'cookable',
    'vegetable',
  ]),
  ingredient('green_beans', 'Green Beans', '\u{1FADB}', 'vegetable', 'cup', [
    'choppable',
    'solid',
    'cookable',
    'vegetable',
  ]),
  ingredient('peas', 'Peas', '\u{1FADB}', 'vegetable', 'cup', [
    'solid',
    'cookable',
    'vegetable',
  ]),
  ingredient('chickpeas', 'Chickpeas', '\u{1F95C}', 'vegetable', 'cup', [
    'solid',
    'mixable',
    'cookable',
    'vegetable',
  ]),
  ingredient('lentils', 'Lentils', '\u{1F95C}', 'vegetable', 'cup', [
    'solid',
    'mixable',
    'cookable',
    'vegetable',
  ]),
  ingredient('black_beans', 'Black Beans', '\u{1F95C}', 'vegetable', 'cup', [
    'solid',
    'mixable',
    'cookable',
    'vegetable',
  ]),
  ingredient('tofu', 'Tofu', '\u{1F9C8}', 'vegetable', 'block', [
    'choppable',
    'solid',
    'mixable',
    'cookable',
    'vegetable',
  ]),
  ingredient('basil', 'Basil', '\u{1F33F}', 'herb', 'sprigs', [
    'choppable',
    'solid',
    'mixable',
    'vegetable',
  ]),
  ingredient('parsley', 'Parsley', '\u{1F33F}', 'herb', 'sprigs', [
    'choppable',
    'solid',
    'mixable',
    'vegetable',
  ]),
  ingredient('cilantro', 'Cilantro', '\u{1F33F}', 'herb', 'sprigs', [
    'choppable',
    'solid',
    'mixable',
    'vegetable',
  ]),
  ingredient('mint', 'Mint', '\u{1F33F}', 'herb', 'sprigs', [
    'choppable',
    'solid',
    'mixable',
    'vegetable',
  ]),
  ingredient('thyme', 'Thyme', '\u{1F33F}', 'herb', 'sprigs', [
    'choppable',
    'solid',
    'mixable',
    'vegetable',
  ]),
  ingredient('oregano', 'Oregano', '\u{1F33F}', 'herb', 'sprigs', [
    'choppable',
    'solid',
    'mixable',
    'vegetable',
  ]),
  ingredient('rosemary', 'Rosemary', '\u{1F33F}', 'herb', 'sprigs', [
    'choppable',
    'solid',
    'mixable',
    'vegetable',
  ]),
  ingredient('dill', 'Dill', '\u{1F33F}', 'herb', 'sprigs', [
    'choppable',
    'solid',
    'mixable',
    'vegetable',
  ]),
  ingredient('salt', 'Salt', '\u{1F9C2}', 'spice', 'tsp', ['solid', 'mixable']),
  ingredient('pepper', 'Pepper', '\u{1FAD9}', 'spice', 'tsp', ['solid', 'mixable']),
  ingredient('paprika', 'Paprika', '\u{1F9C2}', 'spice', 'tsp', ['solid', 'mixable']),
  ingredient('cumin', 'Cumin', '\u{1F9C2}', 'spice', 'tsp', ['solid', 'mixable']),
  ingredient('turmeric', 'Turmeric', '\u{1F9C2}', 'spice', 'tsp', ['solid', 'mixable']),
  ingredient('curry_powder', 'Curry Powder', '\u{1F9C2}', 'spice', 'tsp', [
    'solid',
    'mixable',
  ]),
  ingredient('chili_flakes', 'Chili Flakes', '\u{1F336}\uFE0F', 'spice', 'tsp', [
    'solid',
    'mixable',
  ]),
  ingredient('bay_leaf', 'Bay Leaf', '\u{1F342}', 'spice', 'pcs', [
    'solid',
    'mixable',
  ]),
  ingredient('beef', 'Beef', '\u{1F969}', 'meat', 'lb', [
    'choppable',
    'solid',
    'cookable',
    'meat',
  ]),
  ingredient('chicken', 'Chicken', '\u{1F357}', 'meat', 'lb', [
    'choppable',
    'solid',
    'cookable',
    'meat',
  ]),
  ingredient('pork', 'Pork', '\u{1F356}', 'meat', 'lb', [
    'choppable',
    'solid',
    'cookable',
    'meat',
  ]),
  ingredient('sausage', 'Sausage', '\u{1F32D}', 'meat', 'links', [
    'solid',
    'cookable',
    'meat',
  ]),
  ingredient('bacon', 'Bacon', '\u{1F953}', 'meat', 'strips', [
    'solid',
    'cookable',
    'meat',
  ]),
  ingredient('fish', 'Fish', '\u{1F41F}', 'seafood', 'fillet', [
    'choppable',
    'solid',
    'cookable',
    'meat',
  ]),
  ingredient('salmon', 'Salmon', '\u{1F41F}', 'seafood', 'fillet', [
    'choppable',
    'solid',
    'cookable',
    'meat',
  ]),
  ingredient('shrimp', 'Shrimp', '\u{1F990}', 'seafood', 'pcs', [
    'peelable',
    'solid',
    'cookable',
    'meat',
  ]),
  ingredient('egg', 'Egg', '\u{1F95A}', 'dairy', 'pcs', [
    'solid',
    'mixable',
    'cookable',
  ]),
  ingredient('milk', 'Milk', '\u{1F95B}', 'dairy', 'cup', [
    'liquid',
    'mixable',
    'cookable',
  ]),
  ingredient('cheese', 'Cheese', '\u{1F9C0}', 'dairy', 'cup', [
    'solid',
    'cookable',
    'grateable',
  ]),
  ingredient('butter', 'Butter', '\u{1F9C8}', 'dairy', 'tbsp', [
    'solid',
    'mixable',
    'cookable',
  ]),
  ingredient('cream', 'Cream', '\u{1F963}', 'dairy', 'cup', [
    'liquid',
    'mixable',
    'cookable',
  ]),
  ingredient('yogurt', 'Yogurt', '\u{1F963}', 'dairy', 'cup', [
    'liquid',
    'mixable',
  ]),
  ingredient('rice', 'Rice', '\u{1F35A}', 'grain', 'cup', ['solid', 'cookable']),
  ingredient('pasta', 'Pasta', '\u{1F35D}', 'grain', 'g', ['solid', 'cookable']),
  ingredient('noodles', 'Noodles', '\u{1F35C}', 'grain', 'g', ['solid', 'cookable']),
  ingredient('bread', 'Bread', '\u{1F35E}', 'grain', 'slice', [
    'solid',
    'choppable',
    'cookable',
  ]),
  ingredient('flour', 'Flour', '\u{1F35E}', 'grain', 'cup', ['solid', 'mixable']),
  ingredient('oats', 'Oats', '\u{1F95C}', 'grain', 'cup', ['solid', 'mixable', 'cookable']),
  ingredient('tortilla', 'Tortilla', '\u{1FAD3}', 'grain', 'pcs', [
    'solid',
    'cookable',
  ]),
  ingredient('oil', 'Oil', '\u{1FAD7}', 'liquid', 'tbsp', [
    'liquid',
    'mixable',
    'cookable',
  ]),
  ingredient('soy_sauce', 'Soy Sauce', '\u{1FAD9}', 'condiment', 'tbsp', [
    'liquid',
    'mixable',
    'cookable',
  ]),
  ingredient('vinegar', 'Vinegar', '\u{1FAD9}', 'condiment', 'tbsp', [
    'liquid',
    'mixable',
    'cookable',
  ]),
  ingredient('broth', 'Broth', '\u{1F963}', 'liquid', 'cup', [
    'liquid',
    'mixable',
    'cookable',
  ]),
  ingredient('coconut_milk', 'Coconut Milk', '\u{1F965}', 'liquid', 'cup', [
    'liquid',
    'mixable',
    'cookable',
  ]),
  ingredient('water', 'Water', '\u{1F4A7}', 'liquid', 'cup', [
    'liquid',
    'mixable',
    'cookable',
  ]),
  ingredient('apple', 'Apple', '\u{1F34E}', 'fruit', 'pcs', [
    'peelable',
    'choppable',
    'solid',
  ]),
  ingredient('lemon', 'Lemon', '\u{1F34B}', 'fruit', 'pcs', [
    'peelable',
    'choppable',
    'solid',
    'liquid',
  ]),
  ingredient('lime', 'Lime', '\u{1F348}', 'fruit', 'pcs', [
    'peelable',
    'choppable',
    'solid',
    'liquid',
  ]),
  ingredient('banana', 'Banana', '\u{1F34C}', 'fruit', 'pcs', [
    'peelable',
    'solid',
    'mixable',
  ]),
  ingredient('strawberry', 'Strawberry', '\u{1F353}', 'fruit', 'cup', [
    'solid',
    'mixable',
  ]),
  ingredient('avocado', 'Avocado', '\u{1F951}', 'fruit', 'pcs', [
    'peelable',
    'choppable',
    'solid',
    'mixable',
  ]),
  ingredient('lamb', 'Lamb', '\u{1F9D4}', 'meat', 'lb', [
    'choppable',
    'solid',
    'cookable',
  ]),
  ingredient('turkey', 'Turkey', '\u{1F983}', 'meat', 'lb', [
    'choppable',
    'solid',
    'cookable',
  ]),
  ingredient('steak', 'Steak', '\u{1F969}', 'meat', 'pcs', [
    'solid',
    'cookable',
  ]),
  ingredient('orange', 'Orange', '\u{1F34A}', 'fruit', 'pcs', [
    'peelable',
    'choppable',
    'solid',
    'liquid',
  ]),
  ingredient('blueberry', 'Blueberry', '\u{1FAD0}', 'fruit', 'cup', [
    'solid',
    'mixable',
  ]),
  ingredient('mango', 'Mango', '\u{1F96D}', 'fruit', 'pcs', [
    'peelable',
    'choppable',
    'solid',
  ]),
  ingredient('pineapple', 'Pineapple', '\u{1F34D}', 'fruit', 'pcs', [
    'peelable',
    'choppable',
    'solid',
  ]),
  ingredient('grape', 'Grape', '\u{1F347}', 'fruit', 'cup', [
    'solid',
    'mixable',
  ]),
  ingredient('pear', 'Pear', '\u{1F350}', 'fruit', 'pcs', [
    'peelable',
    'choppable',
    'solid',
  ]),
  ingredient('peach', 'Peach', '\u{1F351}', 'fruit', 'pcs', [
    'peelable',
    'choppable',
    'solid',
  ]),
  ingredient('wheat', 'Wheat', '\u{1F33E}', 'grain', 'stalk', [
    'solid',
    'mixable',
  ]),
  ingredient('quinoa', 'Quinoa', '\u{1F33F}', 'grain', 'cup', [
    'solid',
    'mixable',
    'cookable',
  ]),
  ingredient('bun', 'Bun', '\u{1F35F}', 'grain', 'pcs', [
    'solid',
    'cookable',
  ]),
  ingredient('cereal', 'Cereal', '\u{1F95C}', 'grain', 'cup', [
    'solid',
    'mixable',
  ]),
  ingredient('macaroni', 'Macaroni', '\u{1F35C}', 'grain', 'cup', [
    'solid',
    'cookable',
  ]),
  ingredient('chickpea', 'Chickpea', '\u{1F95C}', 'legume', 'cup', [
    'solid',
    'mixable',
    'cookable',
  ]),
  ingredient('lentil', 'Lentil', '\u{1F95C}', 'legume', 'cup', [
    'solid',
    'mixable',
    'cookable',
  ]),
  ingredient('black_bean', 'Black Bean', '\u{1F95C}', 'legume', 'cup', [
    'solid',
    'mixable',
    'cookable',
  ]),
  ingredient('kidney_bean', 'Kidney Bean', '\u{1F95C}', 'legume', 'cup', [
    'solid',
    'mixable',
    'cookable',
  ]),
  ingredient('soybean', 'Soybean', '\u{1F95C}', 'legume', 'cup', [
    'solid',
    'mixable',
    'cookable',
  ]),
  ingredient('edamame', 'Edamame', '\u{1F95C}', 'legume', 'cup', [
    'solid',
    'mixable',
    'cookable',
  ]),
  ingredient('yeast', 'Yeast', '\u{1F9C7}', 'spice', 'tsp', [
    'solid',
    'mixable',
  ]),
  ingredient('cornstarch', 'Cornstarch', '\u{1F9C2}', 'grain', 'tbsp', [
    'solid',
    'mixable',
  ]),
  ingredient('cauliflower', 'Cauliflower', '\u{1FAD5}', 'vegetable', 'head', [
    'choppable',
    'solid',
    'cookable',
  ]),
  ingredient('celery', 'Celery', '\u{1F966}', 'vegetable', 'stalks', [
    'choppable',
    'solid',
  ]),
  ingredient('green_bean', 'Green Bean', '\u{1FADB}', 'vegetable', 'cup', [
    'choppable',
    'solid',
    'cookable',
  ]),
  ingredient('radish', 'Radish', '\u{1F344}', 'vegetable', 'pcs', [
    'peelable',
    'choppable',
    'solid',
  ]),
  ingredient('beet', 'Beet', '\u{1FADB}', 'vegetable', 'pcs', [
    'peelable',
    'choppable',
    'solid',
  ]),
  ingredient('asparagus', 'Asparagus', '\u{1F344}', 'vegetable', 'spears', [
    'choppable',
    'solid',
    'cookable',
  ]),
  ingredient('bean_sprout', 'Bean Sprout', '\u{1FAD8}', 'vegetable', 'cup', [
    'solid',
    'mixable',
    'cookable',
  ]),
];

const CORE_TOOLS: Tool[] = [


  tool('knife', 'Chef Knife', Scissors, 'prep'),
  tool('paring_knife', 'Paring Knife', Scissors, 'prep'),
  tool('bowl', 'Mixing Bowl', Utensils, 'prep'),
  tool('peeler', 'Peeler', Ban, 'prep'),
  tool('whisk', 'Whisk', Utensils, 'prep'),
  tool('grater', 'Grater', Box, 'prep'),
  tool('cutting_board', 'Cutting Board', Box, 'prep'),
  tool('measuring_cup', 'Measuring Cup', Droplets, 'prep'),
  tool('colander', 'Colander', Waves, 'prep'),
  tool('mortar_pestle', 'Mortar and Pestle', ChefHat, 'prep'),
  tool('pan', 'Frying Pan', Box, 'cook'),
  tool('saute_pan', 'Saute Pan', Box, 'cook'),
  tool('wok', 'Wok', Waves, 'cook'),
  tool('pot', 'Stock Pot', Utensils, 'cook'),
  tool('saucepan', 'Saucepan', Utensils, 'cook'),
  tool('dutch_oven', 'Dutch Oven', ChefHat, 'cook'),
  tool('grill', 'Grill', Flame, 'cook'),
  tool('oven', 'Oven', Flame, 'appliance'),
  tool('air_fryer', 'Air Fryer', Flame, 'appliance'),
  tool('blender', 'Blender', RotateCcw, 'appliance'),
  tool('food_processor', 'Food Processor', RotateCcw, 'appliance'),
  tool('plate', 'Serving Plate', Utensils, 'finish'),
];

const CORE_ACTIONS: CookingAction[] = [
  action('chop', 'Chop', 'Chopped', '\u{1F52A}', {
    requiresToolId: 'knife',
    validProperties: ['choppable'],
  }),
  action('dice', 'Dice', 'Diced', '\u{1F52A}', {
    requiresToolId: 'knife',
    validProperties: ['choppable', 'solid'],
  }),
  action('slice', 'Slice', 'Sliced', '\u{1F52A}', {
    requiresToolId: 'knife',
    validProperties: ['choppable', 'solid'],
  }),
  action('mince', 'Mince', 'Minced', '\u{1F9C4}', {
    requiresToolId: 'knife',
    validProperties: ['choppable'],
  }),
  action('peel', 'Peel', 'Peeled', '\u{1F955}', {
    requiresToolId: 'peeler',
    validProperties: ['peelable'],
  }),
  action('grate', 'Grate', 'Grated', '\u{1F9C0}', {
    requiresToolId: 'grater',
    validProperties: ['grateable', 'solid'],
  }),
  action('crush', 'Crush', 'Crushed', '\u{1F9C4}', {
    requiresToolId: 'mortar_pestle',
    validProperties: ['solid'],
  }),
  action('mix', 'Mix', 'Mixed', '\u{1F963}', {
    requiresToolId: 'bowl',
    validProperties: ['mixable', 'solid', 'liquid'],
  }),
  action('whisk', 'Whisk', 'Whisked', '\u{1F95A}', {
    requiresToolId: 'whisk',
    validProperties: ['mixable', 'liquid'],
  }),
  action('marinate', 'Marinate', 'Marinated', '\u{1FAD9}', {
    requiresToolId: 'bowl',
    validProperties: ['solid', 'cookable'],
  }),
  action('stir_fry', 'Stir Fry', 'Stir Fried', '\u{1F373}', {
    requiresToolId: 'pan',
    requiresHeat: true,
    validProperties: ['cookable', 'solid'],
  }),
  action('saute', 'Saute', 'Sauteed', '\u{1F373}', {
    requiresToolId: 'saute_pan',
    requiresHeat: true,
    validProperties: ['cookable', 'solid', 'vegetable'],
  }),
  action('fry', 'Fry', 'Fried', '\u{1F35F}', {
    requiresToolId: 'pan',
    requiresHeat: true,
    validProperties: ['cookable', 'solid'],
  }),
  action('deep_fry', 'Deep Fry', 'Deep Fried', '\u{1F35F}', {
    requiresToolId: 'pot',
    requiresHeat: true,
    validProperties: ['cookable', 'solid'],
  }),
  action('sear', 'Sear', 'Seared', '\u{1F969}', {
    requiresToolId: 'pan',
    requiresHeat: true,
    validProperties: ['meat', 'cookable'],
  }),
  action('boil', 'Boil', 'Boiled', '\u{1FAD5}', {
    requiresToolId: 'pot',
    requiresHeat: true,
    validProperties: ['cookable', 'solid'],
  }),
  action('simmer', 'Simmer', 'Simmered', '\u{1F372}', {
    requiresToolId: 'pot',
    requiresHeat: true,
    validProperties: ['cookable', 'liquid', 'solid'],
  }),
  action('steam', 'Steam', 'Steamed', '\u{1F32B}\uFE0F', {
    requiresToolId: 'pot',
    requiresHeat: true,
    validProperties: ['cookable', 'solid'],
  }),
  action('bake', 'Bake', 'Baked', '\u{1F35E}', {
    requiresToolId: 'oven',
    requiresHeat: true,
    validProperties: ['cookable'],
  }),
  action('roast', 'Roast', 'Roasted', '\u{1F357}', {
    requiresToolId: 'oven',
    requiresHeat: true,
    validProperties: ['cookable', 'solid'],
  }),
  action('grill', 'Grill', 'Grilled', '\u{1F525}', {
    requiresToolId: 'grill',
    requiresHeat: true,
    validProperties: ['cookable', 'meat', 'vegetable'],
  }),
  action('blend', 'Blend', 'Blended', '\u{1F379}', {
    requiresToolId: 'blender',
    validProperties: ['solid', 'liquid', 'mixable'],
  }),
  action('plate', 'Plate', 'Plated', '\u{1F37D}\uFE0F'),
  action('garnish', 'Garnish', 'Garnished', '\u{2728}'),
  action('drizzle', 'Drizzle', 'Drizzled', '\u{1FAD9}'),
  action('sprinkle', 'Sprinkle', 'Sprinkled', '\u{1F33F}'),
];

const categoryForVisual = (category: string): Category => {
  if (category === 'protein') return 'meat';
  if (category === 'plant_protein') return 'legume';
  if (category === 'dessert') return 'grain';
  if (category === 'liquid') return 'liquid';
  if (category === 'seafood') return 'seafood';
  if (category === 'dairy') return 'dairy';
  if (category === 'fruit') return 'fruit';
  if (category === 'herb') return 'herb';
  if (category === 'spice') return 'spice';
  return 'vegetable';
};

const visualProperties: PhysicalProperty[] = [
  'peelable', 'choppable', 'liquid', 'solid', 'mixable', 'cookable', 'grateable', 'meat', 'vegetable',
];
const mergeById = <T extends { id: string }>(core: T[], visual: T[]): T[] => {
  const merged = new Map(core.map((item) => [item.id, item]));
  visual.forEach((item) => {
    if (!merged.has(item.id)) merged.set(item.id, item);
  });
  return Array.from(merged.values());
};

export const INGREDIENTS: Ingredient[] = mergeById(
  CORE_INGREDIENTS,
  VISUAL_INGREDIENTS.map((item) => ingredient(
    item.id,
    item.name,
    item.emoji,
    categoryForVisual(item.category),
    item.defaultUnit,
    (item.physicalProperties as readonly string[]).filter(
      (property): property is PhysicalProperty =>
        (visualProperties as readonly string[]).includes(property),
    ),
  )),
);

export const TOOLS: Tool[] = mergeById(
  CORE_TOOLS,
  VISUAL_TOOLS.map((item) => tool(item.id, item.name, Box, item.type as Tool['type'])),
);

export const ACTIONS: CookingAction[] = mergeById(
  CORE_ACTIONS,
  VISUAL_ACTIONS.map((item) => action(item.id, item.name, item.verb, item.icon, {
    requiresToolId: item.requiresToolId,
    requiresHeat: item.requiresHeat,
    validProperties: ['solid', 'liquid', 'mixable', 'cookable', 'meat', 'vegetable'],
  })),
);

export const TEMPERATURES = [
  'Low',
  'Medium-Low',
  'Medium',
  'Medium-High',
  'High',
  '160C / 325F',
  '180C / 350F',
  '200C / 400F',
  '220C / 425F',
];

export const TIMES = [
  '1 min',
  '3 mins',
  '5 mins',
  '10 mins',
  '15 mins',
  '20 mins',
  '30 mins',
  '45 mins',
  '1 hr',
  '2 hrs',
];

export const WATER_LEVELS = [
  'Splash',
  '2 tbsp',
  '1/4 cup',
  '1/2 cup',
  '1 cup',
  '2 cups',
  'Just covered',
  'Fully covered',
];

export const CUT_SHAPES: RecipeChipOption[] = [
  { id: 'chopped', label: 'Chopped', emoji: '🔪', description: 'Rough, irregular pieces' },
  { id: 'diced', label: 'Diced', emoji: '🧊', description: 'Small, even cubes' },
  { id: 'sliced', label: 'Sliced', emoji: '🍅', description: 'Thin even slices' },
  { id: 'minced', label: 'Minced', emoji: '🧄', description: 'Very fine pieces' },
  { id: 'peeled', label: 'Peeled', emoji: '🥔', description: 'Skin removed cleanly' },
  { id: 'grated', label: 'Grated', emoji: '🧀', description: 'Fine shredded texture' },
  { id: 'julienned', label: 'Julienned', emoji: '🥕', description: 'Thin matchstick cuts' },
  { id: 'crushed', label: 'Crushed', emoji: '🪨', description: 'Lightly smashed' },
  { id: 'mashed', label: 'Mashed', emoji: '🥣', description: 'Soft, broken-down texture' },
  { id: 'halved', label: 'Halved', emoji: '🟠', description: 'Split into two pieces' },
  { id: 'wedged', label: 'Wedged', emoji: '📐', description: 'Chunky wedge cuts' },
  { id: 'trimmed', label: 'Trimmed', emoji: '✂️', description: 'Ends and rough bits removed' },
];

export const COOK_METHODS: RecipeChipOption[] = [
  { id: 'fried', label: 'Fried', emoji: '🍳', description: 'Cooked in hot oil or fat' },
  { id: 'deep_fried', label: 'Deep Fried', emoji: '🍟', description: 'Fully submerged frying' },
  { id: 'stir_fried', label: 'Stir Fried', emoji: '🥢', description: 'Quick wok toss over heat' },
  { id: 'sauteed', label: 'Sautéed', emoji: '🧈', description: 'Quick pan cooking with fat' },
  { id: 'seared', label: 'Seared', emoji: '🥩', description: 'Fast browning on high heat' },
  { id: 'boiled', label: 'Boiled', emoji: '💧', description: 'Cooked in bubbling water' },
  { id: 'simmered', label: 'Simmered', emoji: '🍲', description: 'Gentle cooking below a boil' },
  { id: 'steamed', label: 'Steamed', emoji: '♨️', description: 'Cooked with steam only' },
  { id: 'baked', label: 'Baked', emoji: '🥐', description: 'Cooked in dry oven heat' },
  { id: 'roasted', label: 'Roasted', emoji: '🔥', description: 'Dry heat with browning' },
  { id: 'grilled', label: 'Grilled', emoji: '🍖', description: 'Charred over direct heat' },
  { id: 'marinated', label: 'Marinated', emoji: '🫙', description: 'Soaked in seasoned liquid' },
  { id: 'mixed', label: 'Mixed', emoji: '🥄', description: 'Combined into one blend' },
  { id: 'drizzled', label: 'Drizzled', emoji: '💦', description: 'Thin finishing stream' },
  { id: 'sprinkled', label: 'Sprinkled', emoji: '✨', description: 'Light topping layer' },
  { id: 'plated', label: 'Plated', emoji: '🍽️', description: 'Final serving arrangement' },
];

export const DETAIL_CHIPS: RecipeChipOption[] = [
  { id: 'olive_oil', label: 'Olive Oil', emoji: '🫒', description: 'Fresh savory cooking fat' },
  { id: 'vegetable_oil', label: 'Vegetable Oil', emoji: '🛢️', description: 'Neutral cooking oil' },
  { id: 'butter', label: 'Butter', emoji: '🧈', description: 'Rich dairy fat' },
  { id: 'sesame_oil', label: 'Sesame Oil', emoji: '⚪', description: 'Nutty aromatic oil' },
  { id: 'water', label: 'Water', emoji: '💧', description: 'Plain cooking liquid' },
  { id: 'broth', label: 'Broth', emoji: '🍵', description: 'Savory simmering liquid' },
  { id: 'stock', label: 'Stock', emoji: '🍲', description: 'Deeper flavored liquid base' },
  { id: 'soy_sauce', label: 'Soy Sauce', emoji: '🧂', description: 'Salty umami liquid' },
  { id: 'vinegar', label: 'Vinegar', emoji: '🍶', description: 'Sharp acidic liquid' },
  { id: 'coconut_milk', label: 'Coconut Milk', emoji: '🥥', description: 'Creamy plant-based liquid' },
  { id: 'low_heat', label: 'Low Heat', emoji: '🟦', description: 'Gentle low flame' },
  { id: 'medium_heat', label: 'Medium Heat', emoji: '🟨', description: 'Balanced cooking heat' },
  { id: 'high_heat', label: 'High Heat', emoji: '🟥', description: 'Strong fast heat' },
  { id: 'crispy', label: 'Crispy', emoji: '🍘', description: 'Crunchy finish' },
  { id: 'tender', label: 'Tender', emoji: '🍗', description: 'Soft and gentle bite' },
  { id: 'saucy', label: 'Saucy', emoji: '🥣', description: 'Glossy coated finish' },
  { id: 'garnished', label: 'Garnished', emoji: '🌿', description: 'Finished with a topping' },
];

export const CUISINE_CATEGORIES: CuisineCategory[] = [
  cuisine('italian', 'Italian', '\u{1F35D}', [
    'Carbonara',
    'Lasagna',
    'Risotto',
    'Pizza Margherita',
    'Osso Buco',
    'Tiramisu',
  ]),
  cuisine('french', 'French', '\u{1F96A}', [
    'Coq au Vin',
    'French Onion Soup',
    'Ratatouille',
    'Quiche',
    'Beef Bourguignon',
    'Creme Brulee',
  ]),
  cuisine('spanish', 'Spanish', '\u{1F958}', [
    'Paella',
    'Gazpacho',
    'Tortilla Espanola',
    'Patatas Bravas',
    'Croquetas',
    'Churros',
  ]),
  cuisine('greek', 'Greek', '\u{1F957}', [
    'Moussaka',
    'Gyros',
    'Spanakopita',
    'Souvlaki',
    'Greek Salad',
    'Baklava',
  ]),
  cuisine('levantine', 'Levantine', '\u{1FAD3}', [
    'Hummus',
    'Falafel',
    'Shawarma',
    'Fattoush',
    'Manakish',
    'Kunafa',
  ]),
  cuisine('turkish', 'Turkish', '\u{1F35E}', [
    'Doner',
    'Pide',
    'Menemen',
    'Lentil Soup',
    'Manti',
    'Baklava',
  ]),
  cuisine('persian', 'Persian', '\u{1F35A}', [
    'Chelo Kebab',
    'Ghormeh Sabzi',
    'Fesenjan',
    'Tahdig',
    'Ash Reshteh',
    'Zereshk Polo',
  ]),
  cuisine('moroccan', 'Moroccan', '\u{1F372}', [
    'Tagine',
    'Couscous',
    'Harira',
    'Bastilla',
    'Zaalouk',
    'Mint Tea',
  ]),
  cuisine('american', 'American', '\u{1F354}', [
    'Burger',
    'Mac and Cheese',
    'Meatloaf',
    'Buffalo Wings',
    'Clam Chowder',
    'Apple Pie',
  ]),
  cuisine('southern-us', 'Southern US', '\u{1F357}', [
    'Fried Chicken',
    'Gumbo',
    'Jambalaya',
    'Biscuits and Gravy',
    'Shrimp and Grits',
    'Pecan Pie',
  ]),
  cuisine('mexican', 'Mexican', '\u{1F32E}', [
    'Tacos',
    'Enchiladas',
    'Pozole',
    'Mole',
    'Tamales',
    'Chilaquiles',
  ]),
  cuisine('brazilian', 'Brazilian', '\u{1F356}', [
    'Feijoada',
    'Moqueca',
    'Churrasco',
    'Pao de Queijo',
    'Brigadeiro',
    'Farofa',
  ]),
  cuisine('peruvian', 'Peruvian', '\u{1F41F}', [
    'Ceviche',
    'Lomo Saltado',
    'Aji de Gallina',
    'Anticuchos',
    'Causa',
    'Arroz Chaufa',
  ]),
  cuisine('chinese', 'Chinese', '\u{1F95F}', [
    'Fried Rice',
    'Dumplings',
    'Mapo Tofu',
    'Chow Mein',
    'Sweet and Sour Pork',
    'Hot Pot',
  ]),
  cuisine('cantonese', 'Cantonese', '\u{1F95F}', [
    'Dim Sum',
    'Char Siu',
    'Wonton Noodles',
    'Steamed Fish',
    'Clay Pot Rice',
    'Egg Tarts',
  ]),
  cuisine('sichuan', 'Sichuan', '\u{1F336}\uFE0F', [
    'Kung Pao Chicken',
    'Mapo Tofu',
    'Dan Dan Noodles',
    'Twice-Cooked Pork',
    'Boiled Fish',
    'Suanla Potato',
  ]),
  cuisine('japanese', 'Japanese', '\u{1F371}', [
    'Ramen',
    'Donburi',
    'Tempura',
    'Teriyaki Chicken',
    'Katsu Curry',
    'Onigiri',
  ]),
  cuisine('korean', 'Korean', '\u{1F35A}', [
    'Bibimbap',
    'Kimchi Jjigae',
    'Bulgogi',
    'Japchae',
    'Tteokbokki',
    'Kimbap',
  ]),
  cuisine('thai', 'Thai', '\u{1F35C}', [
    'Pad Thai',
    'Green Curry',
    'Tom Yum',
    'Som Tum',
    'Massaman Curry',
    'Mango Sticky Rice',
  ]),
  cuisine('vietnamese', 'Vietnamese', '\u{1F35C}', [
    'Pho',
    'Banh Mi',
    'Bun Cha',
    'Fresh Spring Rolls',
    'Broken Rice',
    'Caramel Fish',
  ]),
  cuisine('north-indian', 'North Indian', '\u{1F35B}', [
    'Butter Chicken',
    'Palak Paneer',
    'Biryani',
    'Chole',
    'Naan',
    'Gulab Jamun',
  ]),
  cuisine('south-indian', 'South Indian', '\u{1F95E}', [
    'Dosa',
    'Sambar',
    'Idli',
    'Lemon Rice',
    'Chettinad Chicken',
    'Payasam',
  ]),
  cuisine('filipino', 'Filipino', '\u{1F357}', [
    'Adobo',
    'Sinigang',
    'Pancit',
    'Kare-Kare',
    'Lumpia',
    'Halo-Halo',
  ]),
  cuisine('indonesian', 'Indonesian', '\u{1F35A}', [
    'Nasi Goreng',
    'Rendang',
    'Satay',
    'Gado-Gado',
    'Soto Ayam',
    'Martabak',
  ]),
  cuisine('malaysian', 'Malaysian', '\u{1F35C}', [
    'Laksa',
    'Nasi Lemak',
    'Char Kway Teow',
    'Roti Canai',
    'Beef Rendang',
    'Kuih',
  ]),
  cuisine('singaporean', 'Singaporean', '\u{1F35C}', [
    'Hainanese Chicken Rice',
    'Chili Crab',
    'Laksa',
    'Satay',
    'Carrot Cake',
    'Kaya Toast',
  ]),
  cuisine('ethiopian', 'Ethiopian', '\u{1FAD3}', [
    'Doro Wat',
    'Misir Wat',
    'Shiro',
    'Tibs',
    'Injera',
    'Kitfo',
  ]),
  cuisine('german', 'German', '\u{1F32D}', [
    'Schnitzel',
    'Bratwurst',
    'Kartoffelsalat',
    'Rouladen',
    'Spaetzle',
    'Black Forest Cake',
  ]),
  cuisine('british', 'British', '\u{1F35F}', [
    'Fish and Chips',
    'Shepherds Pie',
    'Full English',
    'Bangers and Mash',
    'Chicken Tikka Masala',
    'Sticky Toffee Pudding',
  ]),
  cuisine('caribbean', 'Caribbean', '\u{1F34D}', [
    'Jerk Chicken',
    'Curry Goat',
    'Rice and Peas',
    'Callaloo',
    'Roti',
    'Rum Cake',
  ]),
  cuisine('desserts', 'Desserts', '\u{1F370}', [
    'Cheesecake',
    'Brownies',
    'Fruit Tart',
    'Crepes',
    'Ice Cream Sundae',
    'Mochi',
  ]),
];
