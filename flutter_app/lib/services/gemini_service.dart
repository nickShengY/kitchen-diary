import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Structured output models for menu extraction
class MenuItemExtracted {
  final String name;
  final String? description;
  final String? price;
  final String? category;
  final List<String> ingredients;
  final List<String> dietaryInfo;
  final bool isSpicy;
  final bool isVegetarian;
  final bool isVegan;

  MenuItemExtracted({
    required this.name,
    this.description,
    this.price,
    this.category,
    this.ingredients = const [],
    this.dietaryInfo = const [],
    this.isSpicy = false,
    this.isVegetarian = false,
    this.isVegan = false,
  });

  factory MenuItemExtracted.fromJson(Map<String, dynamic> json) {
    return MenuItemExtracted(
      name: json['name'] ?? '',
      description: json['description'],
      price: json['price'],
      category: json['category'],
      ingredients: List<String>.from(json['ingredients'] ?? []),
      dietaryInfo: List<String>.from(json['dietaryInfo'] ?? []),
      isSpicy: json['isSpicy'] ?? false,
      isVegetarian: json['isVegetarian'] ?? false,
      isVegan: json['isVegan'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'price': price,
    'category': category,
    'ingredients': ingredients,
    'dietaryInfo': dietaryInfo,
    'isSpicy': isSpicy,
    'isVegetarian': isVegetarian,
    'isVegan': isVegan,
  };
}

class ExtractedMenu {
  final String? restaurantName;
  final String? cuisineType;
  final List<MenuItemExtracted> items;
  final List<String> categories;

  ExtractedMenu({
    this.restaurantName,
    this.cuisineType,
    this.items = const [],
    this.categories = const [],
  });

  factory ExtractedMenu.fromJson(Map<String, dynamic> json) {
    return ExtractedMenu(
      restaurantName: json['restaurantName'],
      cuisineType: json['cuisineType'],
      items: (json['items'] as List? ?? [])
          .map((item) => MenuItemExtracted.fromJson(item))
          .toList(),
      categories: List<String>.from(json['categories'] ?? []),
    );
  }
}

class RecipeSuggestion {
  final String title;
  final String description;
  final List<String> tags;
  final String difficulty;
  final int estimatedMinutes;
  final List<String> ingredients;
  final List<String> instructions;

  RecipeSuggestion({
    required this.title,
    required this.description,
    this.tags = const [],
    this.difficulty = 'medium',
    this.estimatedMinutes = 30,
    this.ingredients = const [],
    this.instructions = const [],
  });

  factory RecipeSuggestion.fromJson(Map<String, dynamic> json) {
    return RecipeSuggestion(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      difficulty: json['difficulty'] ?? 'medium',
      estimatedMinutes: json['estimatedMinutes'] ?? 30,
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
    );
  }
}

class GeminiService {
  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  
  late final GenerativeModel _model;
  late final GenerativeModel _visionModel;
  
  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
    
    _visionModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
  }
  
  /// Initialize with custom API key (for runtime configuration)
  void initWithApiKey(String apiKey) {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
    _model = model;
    _visionModel = model;
  }

  /// Analyze a menu image and extract structured dish information
  /// This is a VIP feature
  Future<ExtractedMenu> analyzeMenuImage(Uint8List imageBytes) async {
    try {
      const prompt = '''
Analyze this restaurant menu image carefully. Extract all the information you can find and return it as structured JSON.

Return a JSON object with this exact structure:
{
  "restaurantName": "Name of the restaurant if visible, or null",
  "cuisineType": "Type of cuisine (Italian, Chinese, Mexican, etc.) or null",
  "categories": ["List of menu categories found like Appetizers, Main Course, Desserts, etc."],
  "items": [
    {
      "name": "Name of the dish",
      "description": "Description of the dish if available",
      "price": "Price as shown on menu or null",
      "category": "Which category this item belongs to",
      "ingredients": ["List of ingredients if mentioned"],
      "dietaryInfo": ["Any dietary info like gluten-free, contains nuts, etc."],
      "isSpicy": true/false,
      "isVegetarian": true/false,
      "isVegan": true/false
    }
  ]
}

Extract ALL dishes visible on the menu. Be thorough and accurate.
''';

      final content = [
        Content.multi([
          DataPart('image/jpeg', imageBytes),
          TextPart(prompt),
        ]),
      ];

      final response = await _visionModel.generateContent(content);
      final text = response.text;
      
      if (text != null) {
        final json = jsonDecode(text) as Map<String, dynamic>;
        return ExtractedMenu.fromJson(json);
      }
      
      return ExtractedMenu();
    } catch (e) {
      debugPrint('Error analyzing menu: $e'); // Replace print with debugPrint
      return ExtractedMenu();
    }
  }

  /// Get AI-powered recipe suggestions based on a query
  Future<List<RecipeSuggestion>> searchSmartRecipes(String query) async {
    try {
      final prompt = '''
Based on the query "$query", suggest 5 creative and delicious recipes.

Return a JSON array with this structure:
[
  {
    "title": "Name of the recipe",
    "description": "A mouthwatering 1-2 sentence description",
    "tags": ["Relevant tags like Dinner, Quick, Healthy, etc."],
    "difficulty": "easy/medium/hard",
    "estimatedMinutes": 30,
    "ingredients": ["Main ingredients needed"],
    "instructions": ["Brief step-by-step instructions"]
  }
]

Make the recipes diverse, practical, and appetizing. Include a mix of difficulties.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final text = response.text;
      
      if (text != null) {
        final List<dynamic> json = jsonDecode(text);
        return json.map((item) => RecipeSuggestion.fromJson(item)).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error searching recipes: $e'); // Replace print with debugPrint
      return [];
    }
  }

  /// Get a detailed description and cooking tips for a dish
  Future<Map<String, dynamic>> getDishDetails(String dishName) async {
    try {
      final prompt = '''
Provide detailed information about the dish "$dishName".

Return a JSON object with:
{
  "description": "A delightful 2-3 sentence description of the dish",
  "origin": "Where this dish originates from",
  "tasteProfile": "Description of taste - sweet, savory, spicy, etc.",
  "texture": "Description of the texture",
  "cookingTips": ["3-5 pro tips for making this dish perfectly"],
  "pairings": ["What drinks or sides go well with this dish"],
  "funFact": "An interesting fact about this dish"
}
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;
      
      if (text != null) {
        return jsonDecode(text) as Map<String, dynamic>;
      }
      
      return {'description': 'A delicious dish!'};
    } catch (e) {
      debugPrint('Error getting dish details: $e'); // Replace print with debugPrint
      return {'description': 'Sounds yummy!'};
    }
  }

  /// Generate a complete recipe from a dish name
  Future<RecipeSuggestion?> generateRecipeFromDish(String dishName) async {
    try {
      final prompt = '''
Create a complete, detailed recipe for "$dishName".

Return a JSON object with:
{
  "title": "$dishName",
  "description": "A mouthwatering description",
  "tags": ["Relevant tags"],
  "difficulty": "easy/medium/hard",
  "estimatedMinutes": total cooking time,
  "ingredients": ["Complete list with quantities like '2 cups flour', '1 lb chicken breast'"],
  "instructions": ["Detailed step-by-step cooking instructions"]
}

Make it practical, detailed, and achievable for home cooks.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;
      
      if (text != null) {
        final json = jsonDecode(text) as Map<String, dynamic>;
        return RecipeSuggestion.fromJson(json);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error generating recipe: $e'); // Replace print with debugPrint
      return null;
    }
  }

  /// Suggest ingredient substitutions
  Future<List<Map<String, String>>> suggestSubstitutions(String ingredient) async {
    try {
      final prompt = '''
Suggest substitutions for "$ingredient" in cooking.

Return a JSON array:
[
  {
    "substitute": "Name of substitute ingredient",
    "ratio": "How much to use (e.g., '1:1' or 'use half the amount')",
    "notes": "Any important notes about using this substitute",
    "bestFor": "What types of recipes this substitute works best for"
  }
]

Provide 4-6 practical substitutions.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;
      
      if (text != null) {
        final List<dynamic> json = jsonDecode(text);
        return json.map((item) => Map<String, String>.from(item)).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error getting substitutions: $e'); // Replace print with debugPrint
      return [];
    }
  }

  /// Analyze nutritional information from ingredients
  Future<Map<String, dynamic>> analyzeNutrition(List<String> ingredients) async {
    try {
      final ingredientList = ingredients.join(', ');
      final prompt = '''
Estimate the nutritional information for a dish containing: $ingredientList

Return a JSON object with approximate values per serving:
{
  "calories": estimated calories,
  "protein": "grams of protein",
  "carbs": "grams of carbohydrates",
  "fat": "grams of fat",
  "fiber": "grams of fiber",
  "sodium": "mg of sodium",
  "vitamins": ["Key vitamins present"],
  "healthNotes": "Brief health notes about this combination"
}
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;
      
      if (text != null) {
        return jsonDecode(text) as Map<String, dynamic>;
      }
      
      return {};
    } catch (e) {
      debugPrint('Error analyzing nutrition: $e'); // Replace print with debugPrint
      return {};
    }
  }

  /// Get meal planning suggestions
  Future<List<Map<String, dynamic>>> getMealPlanSuggestions({
    required int days,
    List<String>? dietaryRestrictions,
    String? cuisinePreference,
  }) async {
    try {
      final restrictions = dietaryRestrictions?.join(', ') ?? 'none';
      final cuisine = cuisinePreference ?? 'varied';
      
      final prompt = '''
Create a $days-day meal plan.
Dietary restrictions: $restrictions
Cuisine preference: $cuisine

Return a JSON array where each element is a day:
[
  {
    "day": 1,
    "breakfast": {
      "name": "Dish name",
      "description": "Brief description",
      "prepTime": minutes
    },
    "lunch": {
      "name": "Dish name",
      "description": "Brief description",
      "prepTime": minutes
    },
    "dinner": {
      "name": "Dish name",
      "description": "Brief description",
      "prepTime": minutes
    },
    "snack": {
      "name": "Snack option",
      "description": "Brief description"
    }
  }
]

Make meals balanced, varied, and practical.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;
      
      if (text != null) {
        final List<dynamic> json = jsonDecode(text);
        return json.map((item) => item as Map<String, dynamic>).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error getting meal plan: $e'); // Replace print with debugPrint
      return [];
    }
  }
}

// Singleton instance
final geminiService = GeminiService();
