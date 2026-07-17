import 'dart:typed_data';

/// Data shapes retained for the UI. AI requests are deliberately disabled:
/// mobile clients must never hold a provider API key. Add a server endpoint
/// that verifies Firebase tokens and enforces quotas before enabling them.
class MenuItemExtracted {
  final String name;
  final String? description, price, category;
  final List<String> ingredients, dietaryInfo;
  final bool isSpicy, isVegetarian, isVegan;
  MenuItemExtracted(
      {required this.name,
      this.description,
      this.price,
      this.category,
      this.ingredients = const [],
      this.dietaryInfo = const [],
      this.isSpicy = false,
      this.isVegetarian = false,
      this.isVegan = false});
  factory MenuItemExtracted.fromJson(Map<String, dynamic> json) =>
      MenuItemExtracted(
          name: json['name'] ?? '',
          description: json['description'],
          price: json['price'],
          category: json['category'],
          ingredients: List<String>.from(json['ingredients'] ?? []),
          dietaryInfo: List<String>.from(json['dietaryInfo'] ?? []),
          isSpicy: json['isSpicy'] ?? false,
          isVegetarian: json['isVegetarian'] ?? false,
          isVegan: json['isVegan'] ?? false);
}

class ExtractedMenu {
  final String? restaurantName, cuisineType;
  final List<MenuItemExtracted> items;
  final List<String> categories;
  ExtractedMenu(
      {this.restaurantName,
      this.cuisineType,
      this.items = const [],
      this.categories = const []});
  factory ExtractedMenu.fromJson(Map<String, dynamic> json) => ExtractedMenu(
      restaurantName: json['restaurantName'],
      cuisineType: json['cuisineType'],
      items: (json['items'] as List? ?? [])
          .map((item) =>
              MenuItemExtracted.fromJson(item as Map<String, dynamic>))
          .toList(),
      categories: List<String>.from(json['categories'] ?? []));
}

class RecipeSuggestion {
  final String title, description, difficulty;
  final List<String> tags, ingredients, instructions;
  final int estimatedMinutes;
  RecipeSuggestion(
      {required this.title,
      required this.description,
      this.tags = const [],
      this.difficulty = 'medium',
      this.estimatedMinutes = 30,
      this.ingredients = const [],
      this.instructions = const []});
  factory RecipeSuggestion.fromJson(Map<String, dynamic> json) =>
      RecipeSuggestion(
          title: json['title'] ?? '',
          description: json['description'] ?? '',
          tags: List<String>.from(json['tags'] ?? []),
          difficulty: json['difficulty'] ?? 'medium',
          estimatedMinutes: json['estimatedMinutes'] ?? 30,
          ingredients: List<String>.from(json['ingredients'] ?? []),
          instructions: List<String>.from(json['instructions'] ?? []));
}

class GeminiService {
  static const unavailableMessage =
      'AI is unavailable until a secure server endpoint is configured.';
  void initWithApiKey(String apiKey) {
    throw UnsupportedError(unavailableMessage);
  }

  Future<ExtractedMenu> analyzeMenuImage(Uint8List imageBytes) async =>
      ExtractedMenu();
  Future<List<RecipeSuggestion>> searchSmartRecipes(String query) async =>
      const [];
  Future<Map<String, dynamic>> getDishDetails(String dishName) async =>
      {'description': unavailableMessage};
  Future<RecipeSuggestion?> generateRecipeFromDish(String dishName) async =>
      null;
  Future<List<Map<String, String>>> suggestSubstitutions(
          String ingredient) async =>
      const [];
  Future<Map<String, dynamic>> analyzeNutrition(
          List<String> ingredients) async =>
      const {};
  Future<List<Map<String, dynamic>>> getMealPlanSuggestions(
          {required int days,
          List<String>? dietaryRestrictions,
          String? cuisinePreference}) async =>
      const [];
}

final geminiService = GeminiService();
