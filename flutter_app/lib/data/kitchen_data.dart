/// Kitchen data - ingredients, tools, and actions for recipe building
class KitchenData {
  static const List<Map<String, dynamic>> ingredients = [
    // Vegetables
    {'id': 'tomato', 'name': 'Tomato', 'emoji': '🍅', 'category': 'vegetable', 'unit': 'pcs'},
    {'id': 'carrot', 'name': 'Carrot', 'emoji': '🥕', 'category': 'vegetable', 'unit': 'pcs'},
    {'id': 'potato', 'name': 'Potato', 'emoji': '🥔', 'category': 'vegetable', 'unit': 'pcs'},
    {'id': 'onion', 'name': 'Onion', 'emoji': '🧅', 'category': 'vegetable', 'unit': 'pcs'},
    {'id': 'garlic', 'name': 'Garlic', 'emoji': '🧄', 'category': 'vegetable', 'unit': 'cloves'},
    {'id': 'broccoli', 'name': 'Broccoli', 'emoji': '🥦', 'category': 'vegetable', 'unit': 'head'},
    {'id': 'spinach', 'name': 'Spinach', 'emoji': '🍃', 'category': 'vegetable', 'unit': 'cup'},
    {'id': 'pepper', 'name': 'Bell Pepper', 'emoji': '🫑', 'category': 'vegetable', 'unit': 'pcs'},
    {'id': 'corn', 'name': 'Corn', 'emoji': '🌽', 'category': 'vegetable', 'unit': 'ear'},
    {'id': 'mushroom', 'name': 'Mushroom', 'emoji': '🍄', 'category': 'vegetable', 'unit': 'cup'},
    
    // Meats
    {'id': 'beef', 'name': 'Beef', 'emoji': '🥩', 'category': 'meat', 'unit': 'lb'},
    {'id': 'chicken', 'name': 'Chicken', 'emoji': '🍗', 'category': 'meat', 'unit': 'lb'},
    {'id': 'pork', 'name': 'Pork', 'emoji': '🥓', 'category': 'meat', 'unit': 'lb'},
    {'id': 'fish', 'name': 'Fish', 'emoji': '🐟', 'category': 'seafood', 'unit': 'fillet'},
    {'id': 'shrimp', 'name': 'Shrimp', 'emoji': '🦐', 'category': 'seafood', 'unit': 'pcs'},
    {'id': 'bacon', 'name': 'Bacon', 'emoji': '🥓', 'category': 'meat', 'unit': 'strips'},
    
    // Dairy & Eggs
    {'id': 'egg', 'name': 'Egg', 'emoji': '🥚', 'category': 'dairy', 'unit': 'pcs'},
    {'id': 'milk', 'name': 'Milk', 'emoji': '🥛', 'category': 'dairy', 'unit': 'cup'},
    {'id': 'cheese', 'name': 'Cheese', 'emoji': '🧀', 'category': 'dairy', 'unit': 'cup'},
    {'id': 'butter', 'name': 'Butter', 'emoji': '🧈', 'category': 'dairy', 'unit': 'tbsp'},
    {'id': 'cream', 'name': 'Cream', 'emoji': '🍦', 'category': 'dairy', 'unit': 'cup'},
    
    // Grains
    {'id': 'rice', 'name': 'Rice', 'emoji': '🍚', 'category': 'grain', 'unit': 'cup'},
    {'id': 'pasta', 'name': 'Pasta', 'emoji': '🍝', 'category': 'grain', 'unit': 'g'},
    {'id': 'bread', 'name': 'Bread', 'emoji': '🍞', 'category': 'grain', 'unit': 'slice'},
    {'id': 'flour', 'name': 'Flour', 'emoji': '🌾', 'category': 'grain', 'unit': 'cup'},
    {'id': 'noodles', 'name': 'Noodles', 'emoji': '🍜', 'category': 'grain', 'unit': 'g'},
    
    // Fruits
    {'id': 'apple', 'name': 'Apple', 'emoji': '🍎', 'category': 'fruit', 'unit': 'pcs'},
    {'id': 'lemon', 'name': 'Lemon', 'emoji': '🍋', 'category': 'fruit', 'unit': 'pcs'},
    {'id': 'banana', 'name': 'Banana', 'emoji': '🍌', 'category': 'fruit', 'unit': 'pcs'},
    {'id': 'strawberry', 'name': 'Strawberry', 'emoji': '🍓', 'category': 'fruit', 'unit': 'cup'},
    {'id': 'avocado', 'name': 'Avocado', 'emoji': '🥑', 'category': 'fruit', 'unit': 'pcs'},
    
    // Spices & Condiments
    {'id': 'salt', 'name': 'Salt', 'emoji': '🧂', 'category': 'spice', 'unit': 'tsp'},
    {'id': 'pepper_spice', 'name': 'Pepper', 'emoji': '⚫', 'category': 'spice', 'unit': 'tsp'},
    {'id': 'oil', 'name': 'Oil', 'emoji': '🫗', 'category': 'liquid', 'unit': 'tbsp'},
    {'id': 'sugar', 'name': 'Sugar', 'emoji': '🍬', 'category': 'spice', 'unit': 'tsp'},
    {'id': 'chili', 'name': 'Chili', 'emoji': '🌶️', 'category': 'spice', 'unit': 'pcs'},
    {'id': 'soysauce', 'name': 'Soy Sauce', 'emoji': '🫘', 'category': 'condiment', 'unit': 'tbsp'},
    {'id': 'honey', 'name': 'Honey', 'emoji': '🍯', 'category': 'condiment', 'unit': 'tbsp'},
    
    // Liquids
    {'id': 'water', 'name': 'Water', 'emoji': '💧', 'category': 'liquid', 'unit': 'cup'},
    {'id': 'wine', 'name': 'Wine', 'emoji': '🍷', 'category': 'liquid', 'unit': 'cup'},
    {'id': 'broth', 'name': 'Broth', 'emoji': '🍲', 'category': 'liquid', 'unit': 'cup'},
  ];

  static const List<Map<String, dynamic>> tools = [
    // Prep tools
    {'id': 'knife', 'name': 'Chef Knife', 'icon': '🔪', 'type': 'prep'},
    {'id': 'bowl', 'name': 'Mixing Bowl', 'icon': '🥣', 'type': 'prep'},
    {'id': 'peeler', 'name': 'Peeler', 'icon': '🥄', 'type': 'prep'},
    {'id': 'grater', 'name': 'Grater', 'icon': '🧀', 'type': 'prep'},
    {'id': 'cutting_board', 'name': 'Cutting Board', 'icon': '🪵', 'type': 'prep'},
    
    // Cooking tools
    {'id': 'pan', 'name': 'Frying Pan', 'icon': '🍳', 'type': 'cook'},
    {'id': 'pot', 'name': 'Stock Pot', 'icon': '🥘', 'type': 'cook'},
    {'id': 'wok', 'name': 'Wok', 'icon': '🥡', 'type': 'cook'},
    {'id': 'grill', 'name': 'Grill', 'icon': '🔥', 'type': 'cook'},
    
    // Appliances
    {'id': 'oven', 'name': 'Oven', 'icon': '♨️', 'type': 'appliance'},
    {'id': 'blender', 'name': 'Blender', 'icon': '🫙', 'type': 'appliance'},
    {'id': 'microwave', 'name': 'Microwave', 'icon': '📻', 'type': 'appliance'},
    {'id': 'airfryer', 'name': 'Air Fryer', 'icon': '🌪️', 'type': 'appliance'},
  ];

  static const List<Map<String, dynamic>> actions = [
    // Prep actions
    {'id': 'chop', 'name': 'Chop', 'verb': 'Chopped', 'icon': '🔪', 'requiresToolId': 'knife'},
    {'id': 'dice', 'name': 'Dice', 'verb': 'Diced', 'icon': '🧊', 'requiresToolId': 'knife'},
    {'id': 'slice', 'name': 'Slice', 'verb': 'Sliced', 'icon': '🍞', 'requiresToolId': 'knife'},
    {'id': 'mince', 'name': 'Mince', 'verb': 'Minced', 'icon': '🤏', 'requiresToolId': 'knife'},
    {'id': 'peel', 'name': 'Peel', 'verb': 'Peeled', 'icon': '🍌', 'requiresToolId': 'peeler'},
    {'id': 'grate', 'name': 'Grate', 'verb': 'Grated', 'icon': '🧀', 'requiresToolId': 'grater'},
    {'id': 'mix', 'name': 'Mix', 'verb': 'Mixed', 'icon': '🥣', 'requiresToolId': 'bowl'},
    {'id': 'whisk', 'name': 'Whisk', 'verb': 'Whisked', 'icon': '🌪️', 'requiresToolId': 'bowl'},
    {'id': 'marinate', 'name': 'Marinate', 'verb': 'Marinated', 'icon': '🫙', 'requiresToolId': 'bowl'},
    
    // Cooking actions
    {'id': 'fry', 'name': 'Stir Fry', 'verb': 'Fried', 'icon': '🍳', 'requiresToolId': 'pan', 'requiresHeat': true},
    {'id': 'sear', 'name': 'Sear', 'verb': 'Seared', 'icon': '🔥', 'requiresToolId': 'pan', 'requiresHeat': true},
    {'id': 'saute', 'name': 'Sauté', 'verb': 'Sautéed', 'icon': '🥘', 'requiresToolId': 'pan', 'requiresHeat': true},
    {'id': 'boil', 'name': 'Boil', 'verb': 'Boiled', 'icon': '♨️', 'requiresToolId': 'pot', 'requiresHeat': true},
    {'id': 'simmer', 'name': 'Simmer', 'verb': 'Simmered', 'icon': '🍲', 'requiresToolId': 'pot', 'requiresHeat': true},
    {'id': 'steam', 'name': 'Steam', 'verb': 'Steamed', 'icon': '💨', 'requiresToolId': 'pot', 'requiresHeat': true},
    {'id': 'bake', 'name': 'Bake', 'verb': 'Baked', 'icon': '🥯', 'requiresToolId': 'oven', 'requiresHeat': true},
    {'id': 'roast', 'name': 'Roast', 'verb': 'Roasted', 'icon': '🍗', 'requiresToolId': 'oven', 'requiresHeat': true},
    {'id': 'grill', 'name': 'Grill', 'verb': 'Grilled', 'icon': '🌭', 'requiresToolId': 'grill', 'requiresHeat': true},
    {'id': 'blend', 'name': 'Blend', 'verb': 'Blended', 'icon': '🥤', 'requiresToolId': 'blender'},
    {'id': 'stirfry', 'name': 'Wok Fry', 'verb': 'Wok Fried', 'icon': '🥡', 'requiresToolId': 'wok', 'requiresHeat': true},
    
    // Finishing actions
    {'id': 'plate', 'name': 'Plate', 'verb': 'Plated', 'icon': '🍽️', 'requiresToolId': null},
    {'id': 'garnish', 'name': 'Garnish', 'verb': 'Garnished', 'icon': '🌿', 'requiresToolId': null},
    {'id': 'drizzle', 'name': 'Drizzle', 'verb': 'Drizzled', 'icon': '🫗', 'requiresToolId': null},
    {'id': 'sprinkle', 'name': 'Sprinkle', 'verb': 'Sprinkled', 'icon': '✨', 'requiresToolId': null},
  ];

  static const List<String> temperatures = [
    'Low',
    'Medium-Low',
    'Medium',
    'Medium-High',
    'High',
    '300°F',
    '350°F',
    '400°F',
    '450°F',
    '500°F',
  ];

  static const List<String> times = [
    '1 min',
    '2 mins',
    '5 mins',
    '10 mins',
    '15 mins',
    '20 mins',
    '30 mins',
    '45 mins',
    '1 hour',
    '2 hours',
  ];

  static const List<String> waterLevels = [
    'Splash',
    '1/4 cup',
    '1/2 cup',
    '1 cup',
    '2 cups',
    'Covered',
  ];

  static const List<Map<String, dynamic>> cuisineCategories = [
    {'id': '1', 'name': 'Italian', 'emoji': '🍝', 'dishes': ['Carbonara', 'Pizza', 'Risotto', 'Lasagna', 'Gnocchi']},
    {'id': '2', 'name': 'Chinese', 'emoji': '🥟', 'dishes': ['Kung Pao Chicken', 'Dumplings', 'Mapo Tofu', 'Fried Rice', 'Chow Mein']},
    {'id': '3', 'name': 'Mexican', 'emoji': '🌮', 'dishes': ['Tacos', 'Burrito', 'Quesadilla', 'Enchiladas', 'Guacamole']},
    {'id': '4', 'name': 'French', 'emoji': '🥐', 'dishes': ['Ratatouille', 'Croissant', 'Onion Soup', 'Coq au Vin', 'Crepes']},
    {'id': '5', 'name': 'Japanese', 'emoji': '🍣', 'dishes': ['Sushi', 'Ramen', 'Tempura', 'Udon', 'Sashimi']},
    {'id': '6', 'name': 'American', 'emoji': '🍔', 'dishes': ['Burger', 'Hot Dog', 'Mac & Cheese', 'BBQ Ribs', 'Fried Chicken']},
    {'id': '7', 'name': 'Indian', 'emoji': '🍛', 'dishes': ['Butter Chicken', 'Biryani', 'Tikka Masala', 'Naan', 'Samosa']},
    {'id': '8', 'name': 'Thai', 'emoji': '🍜', 'dishes': ['Pad Thai', 'Green Curry', 'Tom Yum', 'Mango Sticky Rice', 'Satay']},
    {'id': '9', 'name': 'Korean', 'emoji': '🍱', 'dishes': ['Bibimbap', 'Korean BBQ', 'Kimchi Jjigae', 'Tteokbokki', 'Bulgogi']},
    {'id': '10', 'name': 'Mediterranean', 'emoji': '🫒', 'dishes': ['Hummus', 'Falafel', 'Shawarma', 'Tabbouleh', 'Gyros']},
  ];
}
