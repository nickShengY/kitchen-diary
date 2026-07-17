/// Kitchen data - ingredients, tools, actions, and cuisine categories
/// used by the recipe builder, procedure builder, and decider surfaces.
class KitchenData {
  static const List<Map<String, dynamic>> ingredients = [
    {
      'id': 'onion',
      'name': 'Onion',
      'emoji': '🧅',
      'category': 'vegetable',
      'unit': 'pcs',
      'defaultUnit': 'pcs'
    },
    {
      'id': 'garlic',
      'name': 'Garlic',
      'emoji': '🧄',
      'category': 'vegetable',
      'unit': 'cloves',
      'defaultUnit': 'cloves'
    },
    {
      'id': 'shallot',
      'name': 'Shallot',
      'emoji': '🧅',
      'category': 'vegetable',
      'unit': 'pcs',
      'defaultUnit': 'pcs'
    },
    {
      'id': 'scallion',
      'name': 'Scallion',
      'emoji': '🌿',
      'category': 'herb',
      'unit': 'stalks',
      'defaultUnit': 'stalks'
    },
    {
      'id': 'ginger',
      'name': 'Ginger',
      'emoji': '🫚',
      'category': 'vegetable',
      'unit': 'thumb',
      'defaultUnit': 'thumb'
    },
    {
      'id': 'leek',
      'name': 'Leek',
      'emoji': '🥬',
      'category': 'vegetable',
      'unit': 'stalks',
      'defaultUnit': 'stalks'
    },
    {
      'id': 'tomato',
      'name': 'Tomato',
      'emoji': '🍅',
      'category': 'vegetable',
      'unit': 'pcs',
      'defaultUnit': 'pcs'
    },
    {
      'id': 'potato',
      'name': 'Potato',
      'emoji': '🥔',
      'category': 'vegetable',
      'unit': 'pcs',
      'defaultUnit': 'pcs'
    },
    {
      'id': 'sweet_potato',
      'name': 'Sweet Potato',
      'emoji': '🍠',
      'category': 'vegetable',
      'unit': 'pcs',
      'defaultUnit': 'pcs'
    },
    {
      'id': 'carrot',
      'name': 'Carrot',
      'emoji': '🥕',
      'category': 'vegetable',
      'unit': 'pcs',
      'defaultUnit': 'pcs'
    },
    {
      'id': 'celery',
      'name': 'Celery',
      'emoji': '🥬',
      'category': 'vegetable',
      'unit': 'stalks',
      'defaultUnit': 'stalks'
    },
    {
      'id': 'mushroom',
      'name': 'Mushroom',
      'emoji': '🍄',
      'category': 'vegetable',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'bell_pepper',
      'name': 'Bell Pepper',
      'emoji': '🫑',
      'category': 'vegetable',
      'unit': 'pcs',
      'defaultUnit': 'pcs'
    },
    {
      'id': 'chili_pepper',
      'name': 'Chili Pepper',
      'emoji': '🌶️',
      'category': 'vegetable',
      'unit': 'pcs',
      'defaultUnit': 'pcs'
    },
    {
      'id': 'broccoli',
      'name': 'Broccoli',
      'emoji': '🥦',
      'category': 'vegetable',
      'unit': 'head',
      'defaultUnit': 'head'
    },
    {
      'id': 'cauliflower',
      'name': 'Cauliflower',
      'emoji': '🥦',
      'category': 'vegetable',
      'unit': 'head',
      'defaultUnit': 'head'
    },
    {
      'id': 'cabbage',
      'name': 'Cabbage',
      'emoji': '🥬',
      'category': 'vegetable',
      'unit': 'head',
      'defaultUnit': 'head'
    },
    {
      'id': 'napa_cabbage',
      'name': 'Napa Cabbage',
      'emoji': '🥬',
      'category': 'vegetable',
      'unit': 'head',
      'defaultUnit': 'head'
    },
    {
      'id': 'spinach',
      'name': 'Spinach',
      'emoji': '🥬',
      'category': 'vegetable',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'kale',
      'name': 'Kale',
      'emoji': '🥬',
      'category': 'vegetable',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'lettuce',
      'name': 'Lettuce',
      'emoji': '🥬',
      'category': 'vegetable',
      'unit': 'head',
      'defaultUnit': 'head'
    },
    {
      'id': 'bok_choy',
      'name': 'Bok Choy',
      'emoji': '🥬',
      'category': 'vegetable',
      'unit': 'head',
      'defaultUnit': 'head'
    },
    {
      'id': 'zucchini',
      'name': 'Zucchini',
      'emoji': '🥒',
      'category': 'vegetable',
      'unit': 'pcs',
      'defaultUnit': 'pcs'
    },
    {
      'id': 'eggplant',
      'name': 'Eggplant',
      'emoji': '🍆',
      'category': 'vegetable',
      'unit': 'pcs',
      'defaultUnit': 'pcs'
    },
    {
      'id': 'cucumber',
      'name': 'Cucumber',
      'emoji': '🥒',
      'category': 'vegetable',
      'unit': 'pcs',
      'defaultUnit': 'pcs'
    },
    {
      'id': 'corn',
      'name': 'Corn',
      'emoji': '🌽',
      'category': 'vegetable',
      'unit': 'ear',
      'defaultUnit': 'ear'
    },
    {
      'id': 'green_beans',
      'name': 'Green Beans',
      'emoji': '🫛',
      'category': 'vegetable',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'peas',
      'name': 'Peas',
      'emoji': '🫛',
      'category': 'vegetable',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'chickpeas',
      'name': 'Chickpeas',
      'emoji': '🫘',
      'category': 'vegetable',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'lentils',
      'name': 'Lentils',
      'emoji': '🫘',
      'category': 'vegetable',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'black_beans',
      'name': 'Black Beans',
      'emoji': '🫘',
      'category': 'vegetable',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'kidney_beans',
      'name': 'Kidney Beans',
      'emoji': '🫘',
      'category': 'vegetable',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'basil',
      'name': 'Basil',
      'emoji': '🌿',
      'category': 'herb',
      'unit': 'sprigs',
      'defaultUnit': 'sprigs'
    },
    {
      'id': 'parsley',
      'name': 'Parsley',
      'emoji': '🌿',
      'category': 'herb',
      'unit': 'sprigs',
      'defaultUnit': 'sprigs'
    },
    {
      'id': 'cilantro',
      'name': 'Cilantro',
      'emoji': '🌿',
      'category': 'herb',
      'unit': 'sprigs',
      'defaultUnit': 'sprigs'
    },
    {
      'id': 'mint',
      'name': 'Mint',
      'emoji': '🌿',
      'category': 'herb',
      'unit': 'sprigs',
      'defaultUnit': 'sprigs'
    },
    {
      'id': 'dill',
      'name': 'Dill',
      'emoji': '🌿',
      'category': 'herb',
      'unit': 'sprigs',
      'defaultUnit': 'sprigs'
    },
    {
      'id': 'thyme',
      'name': 'Thyme',
      'emoji': '🌿',
      'category': 'herb',
      'unit': 'sprigs',
      'defaultUnit': 'sprigs'
    },
    {
      'id': 'rosemary',
      'name': 'Rosemary',
      'emoji': '🌿',
      'category': 'herb',
      'unit': 'sprigs',
      'defaultUnit': 'sprigs'
    },
    {
      'id': 'oregano',
      'name': 'Oregano',
      'emoji': '🌿',
      'category': 'herb',
      'unit': 'sprigs',
      'defaultUnit': 'sprigs'
    },
    {
      'id': 'bay_leaf',
      'name': 'Bay Leaf',
      'emoji': '🍃',
      'category': 'herb',
      'unit': 'pcs',
      'defaultUnit': 'pcs'
    },
    {
      'id': 'chicken_breast',
      'name': 'Chicken Breast',
      'emoji': '🍗',
      'category': 'meat',
      'unit': 'lb',
      'defaultUnit': 'lb'
    },
    {
      'id': 'chicken_thigh',
      'name': 'Chicken Thigh',
      'emoji': '🍗',
      'category': 'meat',
      'unit': 'lb',
      'defaultUnit': 'lb'
    },
    {
      'id': 'ground_beef',
      'name': 'Ground Beef',
      'emoji': '🥩',
      'category': 'meat',
      'unit': 'lb',
      'defaultUnit': 'lb'
    },
    {
      'id': 'beef_slice',
      'name': 'Beef Slice',
      'emoji': '🥩',
      'category': 'meat',
      'unit': 'lb',
      'defaultUnit': 'lb'
    },
    {
      'id': 'steak',
      'name': 'Steak',
      'emoji': '🥩',
      'category': 'meat',
      'unit': 'pcs',
      'defaultUnit': 'pcs'
    },
    {
      'id': 'pork_belly',
      'name': 'Pork Belly',
      'emoji': '🥓',
      'category': 'meat',
      'unit': 'lb',
      'defaultUnit': 'lb'
    },
    {
      'id': 'pork_chop',
      'name': 'Pork Chop',
      'emoji': '🍖',
      'category': 'meat',
      'unit': 'pcs',
      'defaultUnit': 'pcs'
    },
    {
      'id': 'bacon',
      'name': 'Bacon',
      'emoji': '🥓',
      'category': 'meat',
      'unit': 'strips',
      'defaultUnit': 'strips'
    },
    {
      'id': 'sausage',
      'name': 'Sausage',
      'emoji': '🌭',
      'category': 'meat',
      'unit': 'links',
      'defaultUnit': 'links'
    },
    {
      'id': 'lamb_shoulder',
      'name': 'Lamb Shoulder',
      'emoji': '🍖',
      'category': 'meat',
      'unit': 'lb',
      'defaultUnit': 'lb'
    },
    {
      'id': 'turkey',
      'name': 'Turkey',
      'emoji': '🍗',
      'category': 'meat',
      'unit': 'lb',
      'defaultUnit': 'lb'
    },
    {
      'id': 'tofu',
      'name': 'Tofu',
      'emoji': '⬜',
      'category': 'dairy',
      'unit': 'block',
      'defaultUnit': 'block'
    },
    {
      'id': 'tempeh',
      'name': 'Tempeh',
      'emoji': '🟫',
      'category': 'dairy',
      'unit': 'block',
      'defaultUnit': 'block'
    },
    {
      'id': 'paneer',
      'name': 'Paneer',
      'emoji': '🧀',
      'category': 'dairy',
      'unit': 'block',
      'defaultUnit': 'block'
    },
    {
      'id': 'salmon',
      'name': 'Salmon',
      'emoji': '🐟',
      'category': 'seafood',
      'unit': 'fillets',
      'defaultUnit': 'fillets'
    },
    {
      'id': 'white_fish',
      'name': 'White Fish',
      'emoji': '🐟',
      'category': 'seafood',
      'unit': 'fillets',
      'defaultUnit': 'fillets'
    },
    {
      'id': 'tuna',
      'name': 'Tuna',
      'emoji': '🐟',
      'category': 'seafood',
      'unit': 'fillets',
      'defaultUnit': 'fillets'
    },
    {
      'id': 'shrimp',
      'name': 'Shrimp',
      'emoji': '🦐',
      'category': 'seafood',
      'unit': 'pcs',
      'defaultUnit': 'pcs'
    },
    {
      'id': 'squid',
      'name': 'Squid',
      'emoji': '🦑',
      'category': 'seafood',
      'unit': 'pcs',
      'defaultUnit': 'pcs'
    },
    {
      'id': 'egg',
      'name': 'Egg',
      'emoji': '🥚',
      'category': 'dairy',
      'unit': 'pcs',
      'defaultUnit': 'pcs'
    },
    {
      'id': 'butter',
      'name': 'Butter',
      'emoji': '🧈',
      'category': 'dairy',
      'unit': 'tbsp',
      'defaultUnit': 'tbsp'
    },
    {
      'id': 'milk',
      'name': 'Milk',
      'emoji': '🥛',
      'category': 'dairy',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'cream',
      'name': 'Cream',
      'emoji': '🥛',
      'category': 'dairy',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'yogurt',
      'name': 'Yogurt',
      'emoji': '🥣',
      'category': 'dairy',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'mozzarella',
      'name': 'Mozzarella',
      'emoji': '🧀',
      'category': 'dairy',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'cheddar',
      'name': 'Cheddar',
      'emoji': '🧀',
      'category': 'dairy',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'parmesan',
      'name': 'Parmesan',
      'emoji': '🧀',
      'category': 'dairy',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'white_rice',
      'name': 'White Rice',
      'emoji': '🍚',
      'category': 'grain',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'brown_rice',
      'name': 'Brown Rice',
      'emoji': '🍚',
      'category': 'grain',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'jasmine_rice',
      'name': 'Jasmine Rice',
      'emoji': '🍚',
      'category': 'grain',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'basmati_rice',
      'name': 'Basmati Rice',
      'emoji': '🍚',
      'category': 'grain',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'spaghetti',
      'name': 'Spaghetti',
      'emoji': '🍝',
      'category': 'grain',
      'unit': 'g',
      'defaultUnit': 'g'
    },
    {
      'id': 'penne',
      'name': 'Penne',
      'emoji': '🍝',
      'category': 'grain',
      'unit': 'g',
      'defaultUnit': 'g'
    },
    {
      'id': 'ramen_noodles',
      'name': 'Ramen Noodles',
      'emoji': '🍜',
      'category': 'grain',
      'unit': 'g',
      'defaultUnit': 'g'
    },
    {
      'id': 'udon',
      'name': 'Udon',
      'emoji': '🍜',
      'category': 'grain',
      'unit': 'g',
      'defaultUnit': 'g'
    },
    {
      'id': 'rice_noodles',
      'name': 'Rice Noodles',
      'emoji': '🍜',
      'category': 'grain',
      'unit': 'g',
      'defaultUnit': 'g'
    },
    {
      'id': 'bread_slice',
      'name': 'Bread Slice',
      'emoji': '🍞',
      'category': 'grain',
      'unit': 'slice',
      'defaultUnit': 'slice'
    },
    {
      'id': 'pita',
      'name': 'Pita',
      'emoji': '🫓',
      'category': 'grain',
      'unit': 'pcs',
      'defaultUnit': 'pcs'
    },
    {
      'id': 'naan',
      'name': 'Naan',
      'emoji': '🫓',
      'category': 'grain',
      'unit': 'pcs',
      'defaultUnit': 'pcs'
    },
    {
      'id': 'tortilla',
      'name': 'Tortilla',
      'emoji': '🫓',
      'category': 'grain',
      'unit': 'pcs',
      'defaultUnit': 'pcs'
    },
    {
      'id': 'flour',
      'name': 'Flour',
      'emoji': '🌾',
      'category': 'grain',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'couscous',
      'name': 'Couscous',
      'emoji': '🍚',
      'category': 'grain',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'quinoa',
      'name': 'Quinoa',
      'emoji': '🍚',
      'category': 'grain',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'olive_oil',
      'name': 'Olive Oil',
      'emoji': '🫒',
      'category': 'liquid',
      'unit': 'tbsp',
      'defaultUnit': 'tbsp'
    },
    {
      'id': 'vegetable_oil',
      'name': 'Vegetable Oil',
      'emoji': '🫗',
      'category': 'liquid',
      'unit': 'tbsp',
      'defaultUnit': 'tbsp'
    },
    {
      'id': 'sesame_oil',
      'name': 'Sesame Oil',
      'emoji': '🫗',
      'category': 'liquid',
      'unit': 'tbsp',
      'defaultUnit': 'tbsp'
    },
    {
      'id': 'soy_sauce',
      'name': 'Soy Sauce',
      'emoji': '🥣',
      'category': 'condiment',
      'unit': 'tbsp',
      'defaultUnit': 'tbsp'
    },
    {
      'id': 'vinegar',
      'name': 'Vinegar',
      'emoji': '🫗',
      'category': 'condiment',
      'unit': 'tbsp',
      'defaultUnit': 'tbsp'
    },
    {
      'id': 'fish_sauce',
      'name': 'Fish Sauce',
      'emoji': '🥣',
      'category': 'condiment',
      'unit': 'tbsp',
      'defaultUnit': 'tbsp'
    },
    {
      'id': 'oyster_sauce',
      'name': 'Oyster Sauce',
      'emoji': '🥣',
      'category': 'condiment',
      'unit': 'tbsp',
      'defaultUnit': 'tbsp'
    },
    {
      'id': 'tomato_paste',
      'name': 'Tomato Paste',
      'emoji': '🍅',
      'category': 'condiment',
      'unit': 'tbsp',
      'defaultUnit': 'tbsp'
    },
    {
      'id': 'coconut_milk',
      'name': 'Coconut Milk',
      'emoji': '🥥',
      'category': 'liquid',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'broth',
      'name': 'Broth',
      'emoji': '🍲',
      'category': 'liquid',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'water',
      'name': 'Water',
      'emoji': '💧',
      'category': 'liquid',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'wine',
      'name': 'Wine',
      'emoji': '🍷',
      'category': 'liquid',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'salt',
      'name': 'Salt',
      'emoji': '🧂',
      'category': 'spice',
      'unit': 'tsp',
      'defaultUnit': 'tsp'
    },
    {
      'id': 'black_pepper',
      'name': 'Black Pepper',
      'emoji': '🧂',
      'category': 'spice',
      'unit': 'tsp',
      'defaultUnit': 'tsp'
    },
    {
      'id': 'chili_flakes',
      'name': 'Chili Flakes',
      'emoji': '🌶️',
      'category': 'spice',
      'unit': 'tsp',
      'defaultUnit': 'tsp'
    },
    {
      'id': 'paprika',
      'name': 'Paprika',
      'emoji': '🧂',
      'category': 'spice',
      'unit': 'tsp',
      'defaultUnit': 'tsp'
    },
    {
      'id': 'cumin',
      'name': 'Cumin',
      'emoji': '🧂',
      'category': 'spice',
      'unit': 'tsp',
      'defaultUnit': 'tsp'
    },
    {
      'id': 'turmeric',
      'name': 'Turmeric',
      'emoji': '🧂',
      'category': 'spice',
      'unit': 'tsp',
      'defaultUnit': 'tsp'
    },
    {
      'id': 'coriander',
      'name': 'Coriander',
      'emoji': '🧂',
      'category': 'spice',
      'unit': 'tsp',
      'defaultUnit': 'tsp'
    },
    {
      'id': 'curry_powder',
      'name': 'Curry Powder',
      'emoji': '🧂',
      'category': 'spice',
      'unit': 'tsp',
      'defaultUnit': 'tsp'
    },
    {
      'id': 'garam_masala',
      'name': 'Garam Masala',
      'emoji': '🧂',
      'category': 'spice',
      'unit': 'tsp',
      'defaultUnit': 'tsp'
    },
    {
      'id': 'cinnamon',
      'name': 'Cinnamon',
      'emoji': '🧂',
      'category': 'spice',
      'unit': 'tsp',
      'defaultUnit': 'tsp'
    },
    {
      'id': 'nutmeg',
      'name': 'Nutmeg',
      'emoji': '🧂',
      'category': 'spice',
      'unit': 'tsp',
      'defaultUnit': 'tsp'
    },
    {
      'id': 'sumac',
      'name': 'Sumac',
      'emoji': '🧂',
      'category': 'spice',
      'unit': 'tsp',
      'defaultUnit': 'tsp'
    },
    {
      'id': 'zaatar',
      'name': 'Zaatar',
      'emoji': '🧂',
      'category': 'spice',
      'unit': 'tsp',
      'defaultUnit': 'tsp'
    },
    {
      'id': 'mustard',
      'name': 'Mustard',
      'emoji': '🥣',
      'category': 'condiment',
      'unit': 'tbsp',
      'defaultUnit': 'tbsp'
    },
    {
      'id': 'mayonnaise',
      'name': 'Mayonnaise',
      'emoji': '🥣',
      'category': 'condiment',
      'unit': 'tbsp',
      'defaultUnit': 'tbsp'
    },
    {
      'id': 'ketchup',
      'name': 'Ketchup',
      'emoji': '🥣',
      'category': 'condiment',
      'unit': 'tbsp',
      'defaultUnit': 'tbsp'
    },
    {
      'id': 'honey',
      'name': 'Honey',
      'emoji': '🍯',
      'category': 'condiment',
      'unit': 'tbsp',
      'defaultUnit': 'tbsp'
    },
    {
      'id': 'lemon',
      'name': 'Lemon',
      'emoji': '🍋',
      'category': 'fruit',
      'unit': 'pcs',
      'defaultUnit': 'pcs'
    },
    {
      'id': 'lime',
      'name': 'Lime',
      'emoji': '🍋',
      'category': 'fruit',
      'unit': 'pcs',
      'defaultUnit': 'pcs'
    },
    {
      'id': 'apple',
      'name': 'Apple',
      'emoji': '🍎',
      'category': 'fruit',
      'unit': 'pcs',
      'defaultUnit': 'pcs'
    },
    {
      'id': 'banana',
      'name': 'Banana',
      'emoji': '🍌',
      'category': 'fruit',
      'unit': 'pcs',
      'defaultUnit': 'pcs'
    },
    {
      'id': 'strawberry',
      'name': 'Strawberry',
      'emoji': '🍓',
      'category': 'fruit',
      'unit': 'cup',
      'defaultUnit': 'cup'
    },
    {
      'id': 'avocado',
      'name': 'Avocado',
      'emoji': '🥑',
      'category': 'fruit',
      'unit': 'pcs',
      'defaultUnit': 'pcs'
    },
  ];

  static const List<Map<String, dynamic>> tools = [
    {'id': 'chef_knife', 'name': 'Chef Knife', 'icon': '🔪', 'type': 'prep'},
    {
      'id': 'paring_knife',
      'name': 'Paring Knife',
      'icon': '🔪',
      'type': 'prep'
    },
    {'id': 'cleaver', 'name': 'Cleaver', 'icon': '🔪', 'type': 'prep'},
    {'id': 'peeler', 'name': 'Peeler', 'icon': '🥕', 'type': 'prep'},
    {'id': 'grater', 'name': 'Grater', 'icon': '🧀', 'type': 'prep'},
    {'id': 'mandoline', 'name': 'Mandoline', 'icon': '🥒', 'type': 'prep'},
    {'id': 'whisk', 'name': 'Whisk', 'icon': '🥣', 'type': 'prep'},
    {'id': 'spatula', 'name': 'Spatula', 'icon': '🍳', 'type': 'prep'},
    {'id': 'tongs', 'name': 'Tongs', 'icon': '🍖', 'type': 'prep'},
    {'id': 'ladle', 'name': 'Ladle', 'icon': '🍲', 'type': 'prep'},
    {
      'id': 'slotted_spoon',
      'name': 'Slotted Spoon',
      'icon': '🥄',
      'type': 'prep'
    },
    {
      'id': 'mortar_pestle',
      'name': 'Mortar and Pestle',
      'icon': '🧂',
      'type': 'prep'
    },
    {'id': 'rolling_pin', 'name': 'Rolling Pin', 'icon': '🫓', 'type': 'prep'},
    {'id': 'mixing_bowl', 'name': 'Mixing Bowl', 'icon': '🥣', 'type': 'prep'},
    {
      'id': 'cutting_board',
      'name': 'Cutting Board',
      'icon': '🪵',
      'type': 'prep'
    },
    {
      'id': 'measuring_cup',
      'name': 'Measuring Cup',
      'icon': '🥛',
      'type': 'prep'
    },
    {
      'id': 'measuring_spoon',
      'name': 'Measuring Spoon',
      'icon': '🥄',
      'type': 'prep'
    },
    {'id': 'colander', 'name': 'Colander', 'icon': '🍝', 'type': 'prep'},
    {'id': 'sieve', 'name': 'Sieve', 'icon': '🌾', 'type': 'prep'},
    {'id': 'saute_pan', 'name': 'Saute Pan', 'icon': '🍳', 'type': 'cook'},
    {'id': 'skillet', 'name': 'Skillet', 'icon': '🍳', 'type': 'cook'},
    {'id': 'wok', 'name': 'Wok', 'icon': '🥘', 'type': 'cook'},
    {'id': 'stock_pot', 'name': 'Stock Pot', 'icon': '🍲', 'type': 'cook'},
    {'id': 'saucepan', 'name': 'Saucepan', 'icon': '🍲', 'type': 'cook'},
    {'id': 'dutch_oven', 'name': 'Dutch Oven', 'icon': '🍲', 'type': 'cook'},
    {'id': 'grill', 'name': 'Grill', 'icon': '🔥', 'type': 'cook'},
    {'id': 'steamer', 'name': 'Steamer', 'icon': '♨️', 'type': 'cook'},
    {
      'id': 'rice_cooker',
      'name': 'Rice Cooker',
      'icon': '🍚',
      'type': 'appliance'
    },
    {
      'id': 'pressure_cooker',
      'name': 'Pressure Cooker',
      'icon': '🍲',
      'type': 'appliance'
    },
    {'id': 'oven', 'name': 'Oven', 'icon': '🔥', 'type': 'appliance'},
    {'id': 'air_fryer', 'name': 'Air Fryer', 'icon': '🍗', 'type': 'appliance'},
    {'id': 'blender', 'name': 'Blender', 'icon': '🥤', 'type': 'appliance'},
    {
      'id': 'food_processor',
      'name': 'Food Processor',
      'icon': '🥣',
      'type': 'appliance'
    },
    {'id': 'sheet_pan', 'name': 'Sheet Pan', 'icon': '🍪', 'type': 'cook'},
    {'id': 'baking_dish', 'name': 'Baking Dish', 'icon': '🥘', 'type': 'cook'},
    {'id': 'plate', 'name': 'Plate', 'icon': '🍽️', 'type': 'finish'},
  ];

  static const List<Map<String, dynamic>> actions = [
    {
      'id': 'wash',
      'name': 'Wash',
      'verb': 'Washed',
      'icon': '💧',
      'requiresToolId': 'colander'
    },
    {
      'id': 'peel',
      'name': 'Peel',
      'verb': 'Peeled',
      'icon': '🥕',
      'requiresToolId': 'peeler'
    },
    {
      'id': 'trim',
      'name': 'Trim',
      'verb': 'Trimmed',
      'icon': '🔪',
      'requiresToolId': 'paring_knife'
    },
    {
      'id': 'slice',
      'name': 'Slice',
      'verb': 'Sliced',
      'icon': '🔪',
      'requiresToolId': 'chef_knife'
    },
    {
      'id': 'dice',
      'name': 'Dice',
      'verb': 'Diced',
      'icon': '🔪',
      'requiresToolId': 'chef_knife'
    },
    {
      'id': 'chop',
      'name': 'Chop',
      'verb': 'Chopped',
      'icon': '🔪',
      'requiresToolId': 'chef_knife'
    },
    {
      'id': 'mince',
      'name': 'Mince',
      'verb': 'Minced',
      'icon': '🔪',
      'requiresToolId': 'chef_knife'
    },
    {
      'id': 'julienne',
      'name': 'Julienne',
      'verb': 'Julienned',
      'icon': '🔪',
      'requiresToolId': 'chef_knife'
    },
    {
      'id': 'grate',
      'name': 'Grate',
      'verb': 'Grated',
      'icon': '🧀',
      'requiresToolId': 'grater'
    },
    {
      'id': 'crush',
      'name': 'Crush',
      'verb': 'Crushed',
      'icon': '🧂',
      'requiresToolId': 'mortar_pestle'
    },
    {
      'id': 'mash',
      'name': 'Mash',
      'verb': 'Mashed',
      'icon': '🥣',
      'requiresToolId': 'mixing_bowl'
    },
    {
      'id': 'mix',
      'name': 'Mix',
      'verb': 'Mixed',
      'icon': '🥣',
      'requiresToolId': 'mixing_bowl'
    },
    {
      'id': 'whisk',
      'name': 'Whisk',
      'verb': 'Whisked',
      'icon': '🥣',
      'requiresToolId': 'whisk'
    },
    {
      'id': 'marinate',
      'name': 'Marinate',
      'verb': 'Marinated',
      'icon': '🥣',
      'requiresToolId': 'mixing_bowl'
    },
    {
      'id': 'knead',
      'name': 'Knead',
      'verb': 'Kneaded',
      'icon': '🫓',
      'requiresToolId': 'mixing_bowl'
    },
    {
      'id': 'toss',
      'name': 'Toss',
      'verb': 'Tossed',
      'icon': '🥗',
      'requiresToolId': 'mixing_bowl'
    },
    {
      'id': 'stir',
      'name': 'Stir',
      'verb': 'Stirred',
      'icon': '🥄',
      'requiresToolId': 'ladle'
    },
    {
      'id': 'saute',
      'name': 'Saute',
      'verb': 'Sauteed',
      'icon': '🍳',
      'requiresToolId': 'saute_pan',
      'requiresHeat': true
    },
    {
      'id': 'stir_fry',
      'name': 'Stir Fry',
      'verb': 'Stir Fried',
      'icon': '🥘',
      'requiresToolId': 'wok',
      'requiresHeat': true
    },
    {
      'id': 'fry',
      'name': 'Fry',
      'verb': 'Fried',
      'icon': '🍳',
      'requiresToolId': 'skillet',
      'requiresHeat': true
    },
    {
      'id': 'deep_fry',
      'name': 'Deep Fry',
      'verb': 'Deep Fried',
      'icon': '🍤',
      'requiresToolId': 'stock_pot',
      'requiresHeat': true
    },
    {
      'id': 'sear',
      'name': 'Sear',
      'verb': 'Seared',
      'icon': '🔥',
      'requiresToolId': 'skillet',
      'requiresHeat': true
    },
    {
      'id': 'boil',
      'name': 'Boil',
      'verb': 'Boiled',
      'icon': '🍲',
      'requiresToolId': 'stock_pot',
      'requiresHeat': true
    },
    {
      'id': 'blanch',
      'name': 'Blanch',
      'verb': 'Blanched',
      'icon': '♨️',
      'requiresToolId': 'stock_pot',
      'requiresHeat': true
    },
    {
      'id': 'simmer',
      'name': 'Simmer',
      'verb': 'Simmered',
      'icon': '🍲',
      'requiresToolId': 'saucepan',
      'requiresHeat': true
    },
    {
      'id': 'braise',
      'name': 'Braise',
      'verb': 'Braised',
      'icon': '🍲',
      'requiresToolId': 'dutch_oven',
      'requiresHeat': true
    },
    {
      'id': 'steam',
      'name': 'Steam',
      'verb': 'Steamed',
      'icon': '♨️',
      'requiresToolId': 'steamer',
      'requiresHeat': true
    },
    {
      'id': 'bake',
      'name': 'Bake',
      'verb': 'Baked',
      'icon': '🔥',
      'requiresToolId': 'oven',
      'requiresHeat': true
    },
    {
      'id': 'roast',
      'name': 'Roast',
      'verb': 'Roasted',
      'icon': '🔥',
      'requiresToolId': 'oven',
      'requiresHeat': true
    },
    {
      'id': 'grill',
      'name': 'Grill',
      'verb': 'Grilled',
      'icon': '🔥',
      'requiresToolId': 'grill',
      'requiresHeat': true
    },
    {
      'id': 'toast',
      'name': 'Toast',
      'verb': 'Toasted',
      'icon': '🍞',
      'requiresToolId': 'sheet_pan',
      'requiresHeat': true
    },
    {
      'id': 'poach',
      'name': 'Poach',
      'verb': 'Poached',
      'icon': '🥚',
      'requiresToolId': 'saucepan',
      'requiresHeat': true
    },
    {
      'id': 'scramble',
      'name': 'Scramble',
      'verb': 'Scrambled',
      'icon': '🥚',
      'requiresToolId': 'skillet',
      'requiresHeat': true
    },
    {
      'id': 'smoke',
      'name': 'Smoke',
      'verb': 'Smoked',
      'icon': '🔥',
      'requiresToolId': 'grill',
      'requiresHeat': true
    },
    {
      'id': 'pickle',
      'name': 'Pickle',
      'verb': 'Pickled',
      'icon': '🥒',
      'requiresToolId': 'mixing_bowl'
    },
    {
      'id': 'ferment',
      'name': 'Ferment',
      'verb': 'Fermented',
      'icon': '🥬',
      'requiresToolId': 'mixing_bowl'
    },
    {
      'id': 'blend',
      'name': 'Blend',
      'verb': 'Blended',
      'icon': '🥤',
      'requiresToolId': 'blender'
    },
    {
      'id': 'puree',
      'name': 'Puree',
      'verb': 'Pureed',
      'icon': '🥤',
      'requiresToolId': 'food_processor'
    },
    {
      'id': 'reduce',
      'name': 'Reduce',
      'verb': 'Reduced',
      'icon': '🍲',
      'requiresToolId': 'saucepan',
      'requiresHeat': true
    },
    {
      'id': 'drizzle',
      'name': 'Drizzle',
      'verb': 'Drizzled',
      'icon': '🫗',
      'requiresToolId': null
    },
    {
      'id': 'sprinkle',
      'name': 'Sprinkle',
      'verb': 'Sprinkled',
      'icon': '✨',
      'requiresToolId': null
    },
    {
      'id': 'garnish',
      'name': 'Garnish',
      'verb': 'Garnished',
      'icon': '🌿',
      'requiresToolId': null
    },
    {
      'id': 'plate',
      'name': 'Plate',
      'verb': 'Plated',
      'icon': '🍽️',
      'requiresToolId': 'plate'
    },
  ];

  static const List<String> temperatures = [
    'Low',
    'Medium-Low',
    'Medium',
    'Medium-High',
    'High',
    '180 C',
    '200 C',
    '220 C',
    '300 F',
    '350 F',
    '400 F',
    '450 F',
  ];

  static const List<String> times = [
    '30 sec',
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
    '4 hours',
    'Overnight',
  ];

  static const List<String> waterLevels = [
    'Splash',
    '2 tbsp',
    '1/4 cup',
    '1/2 cup',
    '1 cup',
    '2 cups',
    'Covered',
    'Submerged',
  ];

  static const List<Map<String, dynamic>> cuisineCategories = [
    {
      'id': 'italian',
      'name': 'Italian',
      'emoji': '🍝',
      'dishes': [
        'Carbonara',
        'Lasagna',
        'Risotto',
        'Margherita Pizza',
        'Gnocchi',
        'Osso Buco'
      ]
    },
    {
      'id': 'french',
      'name': 'French',
      'emoji': '🥐',
      'dishes': [
        'Coq au Vin',
        'Ratatouille',
        'Onion Soup',
        'Crepes',
        'Quiche',
        'Bouillabaisse'
      ]
    },
    {
      'id': 'spanish',
      'name': 'Spanish',
      'emoji': '🥘',
      'dishes': [
        'Paella',
        'Tortilla Espanola',
        'Patatas Bravas',
        'Gazpacho',
        'Croquetas',
        'Churros'
      ]
    },
    {
      'id': 'portuguese',
      'name': 'Portuguese',
      'emoji': '🐟',
      'dishes': [
        'Bacalhau',
        'Caldo Verde',
        'Piri Piri Chicken',
        'Francesinha',
        'Pastel de Nata'
      ]
    },
    {
      'id': 'mediterranean',
      'name': 'Mediterranean',
      'emoji': '🥗',
      'dishes': [
        'Grain Bowls',
        'Roasted Vegetables',
        'Lemon Herb Chicken',
        'Stuffed Peppers',
        'Chickpea Salad'
      ]
    },
    {
      'id': 'greek',
      'name': 'Greek',
      'emoji': '🫒',
      'dishes': [
        'Moussaka',
        'Gyros',
        'Souvlaki',
        'Spanakopita',
        'Greek Salad',
        'Avgolemono'
      ]
    },
    {
      'id': 'turkish',
      'name': 'Turkish',
      'emoji': '🍢',
      'dishes': [
        'Doner',
        'Menemen',
        'Lahmacun',
        'Pide',
        'Mercimek Corbasi',
        'Baklava'
      ]
    },
    {
      'id': 'levantine',
      'name': 'Levantine',
      'emoji': '🥙',
      'dishes': [
        'Hummus',
        'Falafel',
        'Shawarma',
        'Tabbouleh',
        'Manakish',
        'Fattoush'
      ]
    },
    {
      'id': 'persian',
      'name': 'Persian',
      'emoji': '🍚',
      'dishes': [
        'Chelo Kebab',
        'Ghormeh Sabzi',
        'Fesenjan',
        'Tahdig',
        'Ash Reshteh',
        'Kuku Sabzi'
      ]
    },
    {
      'id': 'moroccan',
      'name': 'Moroccan',
      'emoji': '🍲',
      'dishes': [
        'Tagine',
        'Couscous',
        'Harira',
        'Bastilla',
        'Zaalouk',
        'Rfissa'
      ]
    },
    {
      'id': 'ethiopian',
      'name': 'Ethiopian',
      'emoji': '🥘',
      'dishes': ['Doro Wat', 'Misir Wat', 'Tibs', 'Shiro', 'Injera Platter']
    },
    {
      'id': 'egyptian',
      'name': 'Egyptian',
      'emoji': '🥣',
      'dishes': ['Koshari', 'Molokhia', 'Ful Medames', 'Mahshi', 'Hawawshi']
    },
    {
      'id': 'american',
      'name': 'American',
      'emoji': '🍔',
      'dishes': [
        'Burger',
        'Mac and Cheese',
        'BBQ Ribs',
        'Meatloaf',
        'Buffalo Wings',
        'Pancakes'
      ]
    },
    {
      'id': 'southern_us',
      'name': 'Southern US',
      'emoji': '🍗',
      'dishes': [
        'Fried Chicken',
        'Grits',
        'Gumbo',
        'Biscuits and Gravy',
        'Jambalaya',
        'Collard Greens'
      ]
    },
    {
      'id': 'cajun_creole',
      'name': 'Cajun and Creole',
      'emoji': '🦐',
      'dishes': [
        'Etouffee',
        'Red Beans and Rice',
        'Crawfish Boil',
        'Dirty Rice',
        'Shrimp Creole'
      ]
    },
    {
      'id': 'mexican',
      'name': 'Mexican',
      'emoji': '🌮',
      'dishes': [
        'Tacos',
        'Enchiladas',
        'Pozole',
        'Mole',
        'Tamales',
        'Guacamole'
      ]
    },
    {
      'id': 'tex_mex',
      'name': 'Tex-Mex',
      'emoji': '🫔',
      'dishes': [
        'Fajitas',
        'Chili con Carne',
        'Nachos',
        'Queso Dip',
        'Burrito Bowl'
      ]
    },
    {
      'id': 'peruvian',
      'name': 'Peruvian',
      'emoji': '🍋',
      'dishes': [
        'Ceviche',
        'Lomo Saltado',
        'Aji de Gallina',
        'Anticuchos',
        'Arroz con Mariscos'
      ]
    },
    {
      'id': 'brazilian',
      'name': 'Brazilian',
      'emoji': '🥩',
      'dishes': [
        'Feijoada',
        'Pao de Queijo',
        'Moqueca',
        'Brigadeiro',
        'Churrasco'
      ]
    },
    {
      'id': 'argentinian',
      'name': 'Argentinian',
      'emoji': '🥩',
      'dishes': ['Asado', 'Empanadas', 'Milanesa', 'Chimichurri Steak', 'Locro']
    },
    {
      'id': 'chinese',
      'name': 'Chinese',
      'emoji': '🥡',
      'dishes': [
        'Fried Rice',
        'Dumplings',
        'Mapo Tofu',
        'Chow Mein',
        'Congee',
        'Sweet and Sour Pork'
      ]
    },
    {
      'id': 'cantonese',
      'name': 'Cantonese',
      'emoji': '🥢',
      'dishes': [
        'Dim Sum',
        'Char Siu',
        'Wonton Noodles',
        'Steamed Fish',
        'Clay Pot Rice'
      ]
    },
    {
      'id': 'sichuan',
      'name': 'Sichuan',
      'emoji': '🌶️',
      'dishes': [
        'Mapo Tofu',
        'Kung Pao Chicken',
        'Dan Dan Noodles',
        'Twice-Cooked Pork',
        'Mala Hot Pot'
      ]
    },
    {
      'id': 'japanese',
      'name': 'Japanese',
      'emoji': '🍣',
      'dishes': [
        'Ramen',
        'Katsu Curry',
        'Tempura',
        'Udon',
        'Teriyaki',
        'Donburi'
      ]
    },
    {
      'id': 'korean',
      'name': 'Korean',
      'emoji': '🍲',
      'dishes': [
        'Bibimbap',
        'Bulgogi',
        'Kimchi Jjigae',
        'Japchae',
        'Tteokbokki',
        'Samgyeopsal'
      ]
    },
    {
      'id': 'thai',
      'name': 'Thai',
      'emoji': '🍜',
      'dishes': [
        'Pad Thai',
        'Green Curry',
        'Tom Yum',
        'Pad Kra Pao',
        'Massaman Curry',
        'Som Tam'
      ]
    },
    {
      'id': 'vietnamese',
      'name': 'Vietnamese',
      'emoji': '🍜',
      'dishes': [
        'Pho',
        'Banh Mi',
        'Bun Cha',
        'Goi Cuon',
        'Bun Bo Hue',
        'Ca Kho To'
      ]
    },
    {
      'id': 'filipino',
      'name': 'Filipino',
      'emoji': '🍗',
      'dishes': ['Adobo', 'Sinigang', 'Pancit', 'Kare-Kare', 'Lumpia', 'Tocino']
    },
    {
      'id': 'indonesian',
      'name': 'Indonesian',
      'emoji': '🍚',
      'dishes': [
        'Nasi Goreng',
        'Satay',
        'Rendang',
        'Gado-Gado',
        'Soto Ayam',
        'Mie Goreng'
      ]
    },
    {
      'id': 'malaysian',
      'name': 'Malaysian',
      'emoji': '🍛',
      'dishes': [
        'Laksa',
        'Nasi Lemak',
        'Char Kway Teow',
        'Roti Canai',
        'Beef Rendang'
      ]
    },
    {
      'id': 'singaporean',
      'name': 'Singaporean',
      'emoji': '🍲',
      'dishes': [
        'Hainanese Chicken Rice',
        'Chili Crab',
        'Laksa',
        'Carrot Cake',
        'Bak Kut Teh'
      ]
    },
    {
      'id': 'indian_north',
      'name': 'North Indian',
      'emoji': '🍛',
      'dishes': [
        'Butter Chicken',
        'Biryani',
        'Paneer Tikka',
        'Dal Makhani',
        'Naan',
        'Chole'
      ]
    },
    {
      'id': 'indian_south',
      'name': 'South Indian',
      'emoji': '🥥',
      'dishes': [
        'Dosa',
        'Sambar',
        'Idli',
        'Chettinad Curry',
        'Lemon Rice',
        'Upma'
      ]
    },
    {
      'id': 'pakistani',
      'name': 'Pakistani',
      'emoji': '🍢',
      'dishes': [
        'Nihari',
        'Karahi',
        'Biryani',
        'Seekh Kebab',
        'Haleem',
        'Chapli Kebab'
      ]
    },
    {
      'id': 'bengali',
      'name': 'Bengali',
      'emoji': '🐟',
      'dishes': [
        'Machher Jhol',
        'Shorshe Ilish',
        'Khichuri',
        'Luchi and Aloo Dum',
        'Mishti Doi'
      ]
    },
    {
      'id': 'nepali',
      'name': 'Nepali',
      'emoji': '🥟',
      'dishes': ['Momo', 'Thukpa', 'Dal Bhat', 'Sel Roti', 'Choila']
    },
    {
      'id': 'sri_lankan',
      'name': 'Sri Lankan',
      'emoji': '🥥',
      'dishes': ['Rice and Curry', 'Kottu', 'Hoppers', 'Parippu', 'Pol Sambol']
    },
    {
      'id': 'russian',
      'name': 'Russian',
      'emoji': '🥣',
      'dishes': [
        'Borscht',
        'Beef Stroganoff',
        'Pelmeni',
        'Olivier Salad',
        'Blini'
      ]
    },
    {
      'id': 'ukrainian',
      'name': 'Ukrainian',
      'emoji': '🥟',
      'dishes': ['Borscht', 'Varenyky', 'Holubtsi', 'Deruny', 'Syrnyky']
    },
    {
      'id': 'polish',
      'name': 'Polish',
      'emoji': '🥟',
      'dishes': ['Pierogi', 'Bigos', 'Zurek', 'Golabki', 'Placki Ziemniaczane']
    },
    {
      'id': 'german',
      'name': 'German',
      'emoji': '🥨',
      'dishes': [
        'Schnitzel',
        'Bratwurst',
        'Potato Salad',
        'Spaetzle',
        'Sauerbraten'
      ]
    },
    {
      'id': 'british',
      'name': 'British',
      'emoji': '🥧',
      'dishes': [
        'Fish and Chips',
        'Shepherds Pie',
        'Sunday Roast',
        'Full English',
        'Sticky Toffee Pudding'
      ]
    },
    {
      'id': 'irish',
      'name': 'Irish',
      'emoji': '🍀',
      'dishes': ['Irish Stew', 'Colcannon', 'Boxty', 'Soda Bread', 'Coddle']
    },
    {
      'id': 'scandinavian',
      'name': 'Scandinavian',
      'emoji': '🐟',
      'dishes': [
        'Smorrebrod',
        'Meatballs',
        'Gravlax',
        'Cardamom Buns',
        'Salmon Soup'
      ]
    },
    {
      'id': 'australian',
      'name': 'Australian',
      'emoji': '🥧',
      'dishes': [
        'Meat Pie',
        'Barramundi',
        'Lamingtons',
        'Sausage Rolls',
        'Pumpkin Soup'
      ]
    },
  ];

  static const Map<String, Map<String, dynamic>> actionTransformations = {
    'wash': {
      'inputStates': [
        'raw',
        'washed',
        'peeled',
        'trimmed',
        'sliced',
        'diced',
        'chopped',
        'minced',
        'julienned',
        'grated',
        'crushed',
        'mashed',
        'mixed'
      ],
      'outputState': 'washed',
      'animationType': 'prep_motion'
    },
    'peel': {
      'inputStates': ['raw', 'washed'],
      'outputState': 'peeled',
      'animationType': 'prep_motion'
    },
    'trim': {
      'inputStates': ['raw', 'washed', 'peeled'],
      'outputState': 'trimmed',
      'animationType': 'prep_motion'
    },
    'slice': {
      'inputStates': ['raw', 'washed', 'peeled', 'trimmed'],
      'outputState': 'sliced',
      'animationType': 'cutting_motion'
    },
    'dice': {
      'inputStates': ['raw', 'washed', 'peeled', 'trimmed', 'sliced'],
      'outputState': 'diced',
      'animationType': 'cutting_motion'
    },
    'chop': {
      'inputStates': ['raw', 'washed', 'peeled', 'trimmed', 'sliced'],
      'outputState': 'chopped',
      'animationType': 'cutting_motion'
    },
    'mince': {
      'inputStates': [
        'raw',
        'washed',
        'peeled',
        'trimmed',
        'sliced',
        'chopped'
      ],
      'outputState': 'minced',
      'animationType': 'cutting_motion'
    },
    'julienne': {
      'inputStates': ['raw', 'washed', 'peeled', 'trimmed'],
      'outputState': 'julienned',
      'animationType': 'cutting_motion'
    },
    'grate': {
      'inputStates': ['raw', 'washed', 'peeled', 'trimmed'],
      'outputState': 'grated',
      'animationType': 'cutting_motion'
    },
    'crush': {
      'inputStates': ['raw', 'washed', 'peeled'],
      'outputState': 'crushed',
      'animationType': 'prep_motion'
    },
    'mash': {
      'inputStates': ['boiled', 'steamed', 'roasted'],
      'outputState': 'mashed',
      'animationType': 'mixing_motion'
    },
    'mix': {
      'inputStates': [
        'raw',
        'washed',
        'peeled',
        'trimmed',
        'sliced',
        'diced',
        'chopped',
        'minced',
        'julienned',
        'grated',
        'crushed',
        'mashed',
        'whisked',
        'mixed',
        'marinated'
      ],
      'outputState': 'mixed',
      'animationType': 'mixing_motion'
    },
    'whisk': {
      'inputStates': ['raw', 'mixed'],
      'outputState': 'whisked',
      'animationType': 'mixing_motion'
    },
    'marinate': {
      'inputStates': ['raw', 'sliced', 'diced', 'mixed'],
      'outputState': 'marinated',
      'animationType': 'mixing_motion'
    },
    'knead': {
      'inputStates': ['mixed'],
      'outputState': 'mixed',
      'animationType': 'mixing_motion'
    },
    'toss': {
      'inputStates': ['raw', 'washed', 'mixed', 'garnished'],
      'outputState': 'mixed',
      'animationType': 'mixing_motion'
    },
    'stir': {
      'inputStates': ['mixed', 'simmered', 'sauce'],
      'outputState': 'mixed',
      'animationType': 'mixing_motion'
    },
    'saute': {
      'inputStates': [
        'raw',
        'washed',
        'peeled',
        'trimmed',
        'sliced',
        'diced',
        'chopped',
        'minced'
      ],
      'outputState': 'sauteed',
      'animationType': 'sizzling_motion'
    },
    'stir_fry': {
      'inputStates': [
        'raw',
        'washed',
        'peeled',
        'trimmed',
        'sliced',
        'diced',
        'chopped',
        'marinated'
      ],
      'outputState': 'fried',
      'animationType': 'sizzling_motion'
    },
    'fry': {
      'inputStates': [
        'raw',
        'washed',
        'peeled',
        'trimmed',
        'sliced',
        'diced',
        'chopped',
        'marinated'
      ],
      'outputState': 'fried',
      'animationType': 'sizzling_motion'
    },
    'deep_fry': {
      'inputStates': ['raw', 'sliced', 'diced', 'marinated'],
      'outputState': 'fried',
      'animationType': 'sizzling_motion'
    },
    'sear': {
      'inputStates': ['raw', 'marinated'],
      'outputState': 'seared',
      'animationType': 'sizzling_motion'
    },
    'boil': {
      'inputStates': [
        'raw',
        'washed',
        'peeled',
        'trimmed',
        'sliced',
        'diced',
        'mixed'
      ],
      'outputState': 'boiled',
      'animationType': 'boiling_motion'
    },
    'blanch': {
      'inputStates': ['raw', 'washed', 'trimmed', 'sliced'],
      'outputState': 'boiled',
      'animationType': 'boiling_motion'
    },
    'simmer': {
      'inputStates': ['raw', 'mixed', 'boiled', 'sauce'],
      'outputState': 'simmered',
      'animationType': 'boiling_motion'
    },
    'braise': {
      'inputStates': ['raw', 'seared', 'marinated'],
      'outputState': 'simmered',
      'animationType': 'boiling_motion'
    },
    'steam': {
      'inputStates': ['raw', 'washed', 'trimmed', 'sliced', 'mixed'],
      'outputState': 'steamed',
      'animationType': 'boiling_motion'
    },
    'bake': {
      'inputStates': ['raw', 'mixed', 'marinated'],
      'outputState': 'baked',
      'animationType': 'oven_motion'
    },
    'roast': {
      'inputStates': ['raw', 'mixed', 'marinated'],
      'outputState': 'roasted',
      'animationType': 'oven_motion'
    },
    'grill': {
      'inputStates': ['raw', 'marinated'],
      'outputState': 'grilled',
      'animationType': 'grill_motion'
    },
    'toast': {
      'inputStates': ['raw', 'sliced', 'baked'],
      'outputState': 'toasted',
      'animationType': 'oven_motion'
    },
    'poach': {
      'inputStates': ['raw'],
      'outputState': 'boiled',
      'animationType': 'boiling_motion'
    },
    'scramble': {
      'inputStates': ['raw', 'whisked'],
      'outputState': 'scrambled',
      'animationType': 'sizzling_motion'
    },
    'smoke': {
      'inputStates': ['raw', 'marinated', 'seared'],
      'outputState': 'grilled',
      'animationType': 'grill_motion'
    },
    'pickle': {
      'inputStates': ['raw', 'washed', 'sliced'],
      'outputState': 'mixed',
      'animationType': 'prep_motion'
    },
    'ferment': {
      'inputStates': ['raw', 'washed', 'chopped'],
      'outputState': 'mixed',
      'animationType': 'prep_motion'
    },
    'blend': {
      'inputStates': [
        'raw',
        'washed',
        'sliced',
        'diced',
        'chopped',
        'mixed',
        'boiled',
        'roasted'
      ],
      'outputState': 'mixed',
      'animationType': 'mixing_motion'
    },
    'puree': {
      'inputStates': ['boiled', 'roasted', 'mixed'],
      'outputState': 'sauce',
      'animationType': 'mixing_motion'
    },
    'reduce': {
      'inputStates': ['raw', 'mixed', 'simmered', 'sauce'],
      'outputState': 'sauce',
      'animationType': 'boiling_motion'
    },
    'drizzle': {
      'inputStates': ['raw', 'mixed', 'simmered', 'sauce', 'plated'],
      'outputState': 'drizzled',
      'animationType': 'finish_motion'
    },
    'sprinkle': {
      'inputStates': ['raw', 'mixed', 'simmered', 'sauce', 'plated'],
      'outputState': 'sprinkled',
      'animationType': 'finish_motion'
    },
    'garnish': {
      'inputStates': ['raw', 'mixed', 'simmered', 'sauce', 'plated'],
      'outputState': 'garnished',
      'animationType': 'finish_motion'
    },
    'plate': {
      'inputStates': [
        'raw',
        'mixed',
        'simmered',
        'sauce',
        'garnished',
        'drizzled',
        'sprinkled'
      ],
      'outputState': 'plated',
      'animationType': 'finish_motion'
    },
  };

  static const Map<String, Map<String, dynamic>> animationTypes = {
    'cutting_motion': {
      'id': 'cutting_motion',
      'name': 'Cutting Motion',
      'easing': 'easeInOutCubic',
      'duration': 700,
      'particleEffects': ['knife_glint'],
      'frames': 8
    },
    'prep_motion': {
      'id': 'prep_motion',
      'name': 'Prep Motion',
      'easing': 'easeInOutCubic',
      'duration': 700,
      'particleEffects': [],
      'frames': 8
    },
    'mixing_motion': {
      'id': 'mixing_motion',
      'name': 'Mixing Motion',
      'easing': 'easeInOutCubic',
      'duration': 900,
      'particleEffects': ['swirl'],
      'frames': 10
    },
    'sizzling_motion': {
      'id': 'sizzling_motion',
      'name': 'Sizzling Motion',
      'easing': 'easeOutCubic',
      'duration': 1100,
      'particleEffects': ['steam', 'oil'],
      'frames': 12
    },
    'boiling_motion': {
      'id': 'boiling_motion',
      'name': 'Boiling Motion',
      'easing': 'easeInOutSine',
      'duration': 1200,
      'particleEffects': ['steam', 'bubble'],
      'frames': 12
    },
    'oven_motion': {
      'id': 'oven_motion',
      'name': 'Oven Motion',
      'easing': 'easeOutQuad',
      'duration': 1300,
      'particleEffects': ['warm_glow'],
      'frames': 10
    },
    'grill_motion': {
      'id': 'grill_motion',
      'name': 'Grill Motion',
      'easing': 'easeOutCubic',
      'duration': 1200,
      'particleEffects': ['smoke', 'char'],
      'frames': 12
    },
    'finish_motion': {
      'id': 'finish_motion',
      'name': 'Finish Motion',
      'easing': 'easeOutBack',
      'duration': 800,
      'particleEffects': ['sparkle'],
      'frames': 8
    },
  };

  static Map<String, dynamic> get fallbackRawData => {
        'version': '4.0.0',
        'ingredients': ingredients,
        'tools': tools,
        'actions': actions,
        'temperatures': temperatures,
        'times': times,
        'waterLevels': waterLevels,
        'cuisineCategories': cuisineCategories,
        'actionTransformations': actionTransformations,
        'animationTypes': animationTypes,
      };
}
