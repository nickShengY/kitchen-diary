import 'package:flutter_test/flutter_test.dart';

// Import models
import 'package:kitchen_diary/models/user_model.dart';
import 'package:kitchen_diary/models/recipe_model.dart';
import 'package:kitchen_diary/models/community_model.dart';

// Import services
import 'package:kitchen_diary/services/gemini_service.dart';

// Import data
import 'package:kitchen_diary/data/kitchen_data.dart';

void main() {
  group('Model Tests', () {
    test('UserModel creation and serialization', () {
      final user = UserModel(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test Chef',
        avatarEmoji: '👨‍🍳',
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );

      expect(user.id, 'test-id');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test Chef');
      expect(user.avatarEmoji, '👨‍🍳');
      expect(user.isVip, false);
      expect(user.hasValidVip, false);

      final json = user.toFirestore();
      expect(json['email'], 'test@example.com');
      expect(json['displayName'], 'Test Chef');
    });

    test('UserModel VIP status validation', () {
      final vipUser = UserModel(
        id: 'vip-id',
        email: 'vip@example.com',
        displayName: 'VIP Chef',
        isVip: true,
        vipExpiresAt: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );

      expect(vipUser.isVip, true);
      expect(vipUser.hasValidVip, true);

      final expiredVipUser = UserModel(
        id: 'expired-vip-id',
        email: 'expired@example.com',
        displayName: 'Expired VIP',
        isVip: true,
        vipExpiresAt: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );

      expect(expiredVipUser.isVip, true);
      expect(expiredVipUser.hasValidVip, false);
    });

    test('RecipeModel creation', () {
      final recipe = RecipeModel(
        id: 'recipe-1',
        title: 'Test Recipe',
        description: 'A delicious test recipe',
        authorId: 'author-1',
        authorName: 'Chef Test',
        authorAvatar: '👨‍🍳',
        steps: [],
        tags: ['test', 'quick'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(recipe.id, 'recipe-1');
      expect(recipe.title, 'Test Recipe');
      expect(recipe.totalTimeMinutes, 30); // 10 prep + 20 cook default
      expect(recipe.allIngredients, isEmpty);
    });

    test('RecipeModel with steps', () {
      const step = CookingStep(
        id: 'step-1',
        stepNumber: 1,
        station: StationCategory.prep,
        ingredients: [
          RecipeIngredient(
            ingredientId: 'tomato',
            name: 'Tomato',
            emoji: '🍅',
            amount: '2',
            unit: 'pcs',
          ),
        ],
        toolId: 'knife',
        toolName: 'Chef Knife',
        toolIcon: '🔪',
        actionId: 'chop',
        actionName: 'Chop',
        actionEmoji: '🔪',
      );

      final recipe = RecipeModel(
        id: 'recipe-2',
        title: 'Recipe with Steps',
        authorId: 'author-1',
        authorName: 'Chef Test',
        authorAvatar: '👨‍🍳',
        steps: [step],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(recipe.steps.length, 1);
      expect(recipe.allIngredients.length, 1);
      expect(recipe.allIngredients.first.name, 'Tomato');
    });

    test('CookingStep copyWith', () {
      const step = CookingStep(
        id: 'step-1',
        stepNumber: 1,
        station: StationCategory.prep,
        ingredients: [],
        toolId: 'knife',
        toolName: 'Chef Knife',
        toolIcon: '🔪',
        actionId: 'chop',
        actionName: 'Chop',
        actionEmoji: '🔪',
      );

      final updatedStep = step.copyWith(
        temperature: 'Medium',
        duration: '5 mins',
      );

      expect(updatedStep.temperature, 'Medium');
      expect(updatedStep.duration, '5 mins');
      expect(updatedStep.id, step.id);
    });

    test('ForumPostModel creation', () {
      final post = ForumPostModel(
        id: 'post-1',
        title: 'Test Post',
        content: 'This is a test post content',
        authorId: 'author-1',
        authorName: 'Test Author',
        authorAvatar: '👨‍🍳',
        category: 'tips',
        createdAt: DateTime.now(),
        editedAt: DateTime.now(),
      );

      expect(post.id, 'post-1');
      expect(post.title, 'Test Post');
      expect(post.category, 'tips');
      expect(post.likes, 0);
    });

    test('ChallengeModel creation', () {
      final challenge = ChallengeModel(
        id: 'challenge-1',
        title: 'Weekly Challenge',
        description: 'Cook something amazing',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
      );

      expect(challenge.id, 'challenge-1');
      expect(challenge.title, 'Weekly Challenge');
      expect(challenge.participantsCount, 0);
      expect(challenge.isActive, true);
    });
  });

  group('KitchenData Tests', () {
    test('Ingredients data is valid', () {
      expect(KitchenData.ingredients.isNotEmpty, true);
      
      for (final ing in KitchenData.ingredients) {
        expect(ing['id'], isNotNull);
        expect(ing['name'], isNotNull);
        expect(ing['emoji'], isNotNull);
        expect(ing['category'], isNotNull);
        expect(ing['unit'], isNotNull);
      }
    });

    test('Tools data is valid', () {
      expect(KitchenData.tools.isNotEmpty, true);
      
      for (final tool in KitchenData.tools) {
        expect(tool['id'], isNotNull);
        expect(tool['name'], isNotNull);
        expect(tool['icon'], isNotNull);
        expect(tool['type'], isNotNull);
      }
    });

    test('Actions data is valid', () {
      expect(KitchenData.actions.isNotEmpty, true);
      
      for (final action in KitchenData.actions) {
        expect(action['id'], isNotNull);
        expect(action['name'], isNotNull);
        expect(action['icon'], isNotNull);
      }
    });

    test('Cuisine categories data is valid', () {
      expect(KitchenData.cuisineCategories.isNotEmpty, true);
      expect(KitchenData.cuisineCategories.length, 10);
      
      for (final cuisine in KitchenData.cuisineCategories) {
        expect(cuisine['id'], isNotNull);
        expect(cuisine['name'], isNotNull);
        expect(cuisine['emoji'], isNotNull);
        expect(cuisine['dishes'], isNotNull);
        expect((cuisine['dishes'] as List).isNotEmpty, true);
      }
    });

    test('Temperatures list is valid', () {
      expect(KitchenData.temperatures.isNotEmpty, true);
      expect(KitchenData.temperatures.contains('Medium'), true);
      expect(KitchenData.temperatures.contains('High'), true);
    });

    test('Times list is valid', () {
      expect(KitchenData.times.isNotEmpty, true);
      expect(KitchenData.times.contains('5 mins'), true);
      expect(KitchenData.times.contains('30 mins'), true);
    });
  });

  group('GeminiService Model Tests', () {
    test('MenuItemExtracted creation', () {
      final item = MenuItemExtracted(
        name: 'Pasta Carbonara',
        description: 'Classic Italian pasta',
        price: '\$15.99',
        isVegetarian: false,
      );

      expect(item.name, 'Pasta Carbonara');
      expect(item.price, '\$15.99');
      expect(item.isVegetarian, false);
    });

    test('MenuItemExtracted fromJson', () {
      final json = {
        'name': 'Margherita Pizza',
        'description': 'Fresh tomatoes and mozzarella',
        'price': '\$12.99',
        'isVegetarian': true,
        'isVegan': false,
        'isSpicy': false,
        'ingredients': ['tomatoes', 'mozzarella', 'basil'],
      };

      final item = MenuItemExtracted.fromJson(json);
      expect(item.name, 'Margherita Pizza');
      expect(item.isVegetarian, true);
      expect(item.ingredients.length, 3);
    });

    test('ExtractedMenu creation', () {
      final menu = ExtractedMenu(
        restaurantName: 'Test Restaurant',
        cuisineType: 'Italian',
        items: [
          MenuItemExtracted(name: 'Pizza'),
          MenuItemExtracted(name: 'Pasta'),
        ],
        categories: ['Main Course', 'Appetizers'],
      );

      expect(menu.restaurantName, 'Test Restaurant');
      expect(menu.cuisineType, 'Italian');
      expect(menu.items.length, 2);
      expect(menu.categories.length, 2);
    });

    test('RecipeSuggestion creation', () {
      final suggestion = RecipeSuggestion(
        title: 'Quick Pasta',
        description: 'A fast and easy pasta recipe',
        tags: ['quick', 'easy', 'italian'],
        difficulty: 'easy',
        estimatedMinutes: 20,
        ingredients: ['pasta', 'sauce', 'cheese'],
        instructions: ['Boil pasta', 'Add sauce', 'Serve'],
      );

      expect(suggestion.title, 'Quick Pasta');
      expect(suggestion.difficulty, 'easy');
      expect(suggestion.estimatedMinutes, 20);
      expect(suggestion.ingredients.length, 3);
      expect(suggestion.instructions.length, 3);
    });
  });

  group('Enum Tests', () {
    test('IngredientCategory values', () {
      expect(IngredientCategory.values.length, 10);
      expect(IngredientCategory.vegetable.name, 'vegetable');
      expect(IngredientCategory.meat.name, 'meat');
    });

    test('StationCategory values', () {
      expect(StationCategory.values.length, 3);
      expect(StationCategory.prep.name, 'prep');
      expect(StationCategory.cook.name, 'cook');
      expect(StationCategory.finish.name, 'finish');
    });

    test('RecipeDifficulty values', () {
      expect(RecipeDifficulty.values.length, 4);
      expect(RecipeDifficulty.easy.name, 'easy');
      expect(RecipeDifficulty.expert.name, 'expert');
    });

    test('MealType values', () {
      expect(MealType.values.length, 6);
      expect(MealType.breakfast.name, 'breakfast');
      expect(MealType.dinner.name, 'dinner');
    });
  });
}
