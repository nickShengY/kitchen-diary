import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_diary/models/nutrition_model.dart';

void main() {
  group('NutritionInfo', () {
    test('creation with required fields', () {
      const info = NutritionInfo(
        calories: 500,
        protein: 30,
        carbs: 60,
        fat: 15,
      );
      expect(info.calories, 500);
      expect(info.protein, 30);
      expect(info.carbs, 60);
      expect(info.fat, 15);
      expect(info.fiber, 0);
      expect(info.sugar, 0);
      expect(info.sodium, 0);
      expect(info.saturatedFat, isNull);
      expect(info.cholesterol, isNull);
      expect(info.vitaminA, isNull);
      expect(info.vitaminC, isNull);
      expect(info.calcium, isNull);
      expect(info.iron, isNull);
    });

    test('creation with all fields', () {
      const info = NutritionInfo(
        calories: 800,
        protein: 40,
        carbs: 90,
        fat: 30,
        fiber: 10,
        sugar: 20,
        sodium: 500,
        saturatedFat: 8,
        cholesterol: 50,
        vitaminA: 100,
        vitaminC: 60,
        calcium: 200,
        iron: 5,
      );
      expect(info.fiber, 10);
      expect(info.sugar, 20);
      expect(info.sodium, 500);
      expect(info.saturatedFat, 8);
      expect(info.cholesterol, 50);
      expect(info.vitaminA, 100);
      expect(info.vitaminC, 60);
      expect(info.calcium, 200);
      expect(info.iron, 5);
    });

    test('operator + sums basic nutrients', () {
      const a = NutritionInfo(calories: 300, protein: 20, carbs: 40, fat: 10, fiber: 5, sugar: 8, sodium: 200);
      const b = NutritionInfo(calories: 200, protein: 15, carbs: 30, fat: 8, fiber: 3, sugar: 5, sodium: 100);
      final sum = a + b;
      expect(sum.calories, 500);
      expect(sum.protein, 35);
      expect(sum.carbs, 70);
      expect(sum.fat, 18);
      expect(sum.fiber, 8);
      expect(sum.sugar, 13);
      expect(sum.sodium, 300);
    });

    test('operator + with zero values', () {
      const a = NutritionInfo(calories: 0, protein: 0, carbs: 0, fat: 0);
      const b = NutritionInfo(calories: 100, protein: 10, carbs: 20, fat: 5);
      final sum = a + b;
      expect(sum.calories, 100);
      expect(sum.protein, 10);
    });

    test('toJson produces correct map', () {
      const info = NutritionInfo(
        calories: 500,
        protein: 30,
        carbs: 60,
        fat: 15,
        saturatedFat: 5,
      );
      final json = info.toJson();
      expect(json['calories'], 500);
      expect(json['protein'], 30);
      expect(json['carbs'], 60);
      expect(json['fat'], 15);
      expect(json['saturatedFat'], 5);
      expect(json['cholesterol'], isNull);
    });

    test('fromJson creates correct object', () {
      final json = {
        'calories': 400,
        'protein': 25,
        'carbs': 50,
        'fat': 12,
        'fiber': 8,
        'sugar': 10,
        'sodium': 300,
      };
      final info = NutritionInfo.fromJson(json);
      expect(info.calories, 400);
      expect(info.protein, 25);
      expect(info.carbs, 50);
      expect(info.fat, 12);
      expect(info.fiber, 8);
    });

    test('fromJson with null values defaults to 0', () {
      final json = <String, dynamic>{};
      final info = NutritionInfo.fromJson(json);
      expect(info.calories, 0);
      expect(info.protein, 0);
      expect(info.carbs, 0);
      expect(info.fat, 0);
    });

    test('fromJson handles int values via num cast', () {
      final json = {
        'calories': 500,
        'protein': 30,
        'carbs': 60,
        'fat': 15,
      };
      final info = NutritionInfo.fromJson(json);
      expect(info.calories, 500.0);
      expect(info.protein, 30.0);
    });

    test('toJson/fromJson roundtrip', () {
      const original = NutritionInfo(
        calories: 750,
        protein: 45,
        carbs: 80,
        fat: 25,
        fiber: 12,
        sugar: 15,
        sodium: 600,
        saturatedFat: 8,
        cholesterol: 70,
        vitaminA: 150,
        vitaminC: 80,
        calcium: 300,
        iron: 6,
      );
      final restored = NutritionInfo.fromJson(original.toJson());
      expect(restored.calories, original.calories);
      expect(restored.protein, original.protein);
      expect(restored.carbs, original.carbs);
      expect(restored.fat, original.fat);
      expect(restored.fiber, original.fiber);
      expect(restored.sugar, original.sugar);
      expect(restored.sodium, original.sodium);
      expect(restored.saturatedFat, original.saturatedFat);
      expect(restored.cholesterol, original.cholesterol);
      expect(restored.vitaminA, original.vitaminA);
      expect(restored.vitaminC, original.vitaminC);
      expect(restored.calcium, original.calcium);
      expect(restored.iron, original.iron);
    });
  });

  group('NutritionGoal', () {
    test('default values', () {
      const goal = NutritionGoal();
      expect(goal.targetCalories, 2000);
      expect(goal.targetProtein, 50);
      expect(goal.targetCarbs, 250);
      expect(goal.targetFat, 65);
      expect(goal.targetFiber, 25);
      expect(goal.targetSodium, 2300);
    });

    test('custom values', () {
      const goal = NutritionGoal(
        targetCalories: 1800,
        targetProtein: 70,
        targetCarbs: 200,
        targetFat: 55,
        targetFiber: 30,
        targetSodium: 2000,
      );
      expect(goal.targetCalories, 1800);
      expect(goal.targetProtein, 70);
    });

    test('toJson/fromJson roundtrip', () {
      const original = NutritionGoal(
        targetCalories: 2500,
        targetProtein: 80,
        targetCarbs: 300,
        targetFat: 70,
        targetFiber: 35,
        targetSodium: 2200,
      );
      final restored = NutritionGoal.fromJson(original.toJson());
      expect(restored.targetCalories, original.targetCalories);
      expect(restored.targetProtein, original.targetProtein);
      expect(restored.targetCarbs, original.targetCarbs);
      expect(restored.targetFat, original.targetFat);
      expect(restored.targetFiber, original.targetFiber);
      expect(restored.targetSodium, original.targetSodium);
    });

    test('fromJson with missing values uses defaults', () {
      final json = <String, dynamic>{};
      final goal = NutritionGoal.fromJson(json);
      expect(goal.targetCalories, 2000);
      expect(goal.targetProtein, 50);
    });
  });

  group('DailyNutritionLog', () {
    test('creation with defaults', () {
      final log = DailyNutritionLog(
        date: DateTime(2025, 6, 1),
        totals: const NutritionInfo(calories: 1200, protein: 50, carbs: 150, fat: 40),
      );
      expect(log.mealsLogged, 0);
      expect(log.waterIntakeMl, 0);
    });

    test('toJson/fromJson roundtrip', () {
      final original = DailyNutritionLog(
        date: DateTime(2025, 6, 15),
        totals: const NutritionInfo(calories: 1800, protein: 70, carbs: 200, fat: 60),
        mealsLogged: 3,
        waterIntakeMl: 2000,
      );
      final restored = DailyNutritionLog.fromJson(original.toJson());
      expect(restored.date.year, 2025);
      expect(restored.date.month, 6);
      expect(restored.date.day, 15);
      expect(restored.totals.calories, 1800);
      expect(restored.mealsLogged, 3);
      expect(restored.waterIntakeMl, 2000);
    });
  });

  group('CookingStreak', () {
    test('default values', () {
      const streak = CookingStreak();
      expect(streak.currentStreak, 0);
      expect(streak.longestStreak, 0);
      expect(streak.lastCookDate, isNull);
      expect(streak.totalMealsCooked, 0);
      expect(streak.totalRecipesCreated, 0);
      expect(streak.cuisineBreakdown, isEmpty);
    });

    test('custom values', () {
      final streak = CookingStreak(
        currentStreak: 5,
        longestStreak: 10,
        lastCookDate: DateTime(2025, 6, 1),
        totalMealsCooked: 50,
        totalRecipesCreated: 15,
        cuisineBreakdown: {'Italian': 10, 'Mexican': 8},
      );
      expect(streak.currentStreak, 5);
      expect(streak.longestStreak, 10);
      expect(streak.totalMealsCooked, 50);
      expect(streak.cuisineBreakdown['Italian'], 10);
    });

    test('toJson/fromJson roundtrip', () {
      final original = CookingStreak(
        currentStreak: 7,
        longestStreak: 14,
        lastCookDate: DateTime(2025, 6, 15),
        totalMealsCooked: 100,
        totalRecipesCreated: 25,
        cuisineBreakdown: {'Thai': 5, 'French': 3},
      );
      final restored = CookingStreak.fromJson(original.toJson());
      expect(restored.currentStreak, original.currentStreak);
      expect(restored.longestStreak, original.longestStreak);
      expect(restored.totalMealsCooked, original.totalMealsCooked);
      expect(restored.totalRecipesCreated, original.totalRecipesCreated);
      expect(restored.cuisineBreakdown, original.cuisineBreakdown);
    });

    test('fromJson with null lastCookDate', () {
      final json = {
        'currentStreak': 0,
        'longestStreak': 0,
        'lastCookDate': null,
        'totalMealsCooked': 0,
        'totalRecipesCreated': 0,
        'cuisineBreakdown': <String, dynamic>{},
      };
      final streak = CookingStreak.fromJson(json);
      expect(streak.lastCookDate, isNull);
    });
  });

  group('Achievement', () {
    test('creation with defaults', () {
      const ach = Achievement(
        id: 'first_cook',
        title: 'First Dish',
        description: 'Cook your first meal',
        emoji: '🍳',
        category: 'cooking',
        requiredValue: 1,
      );
      expect(ach.currentValue, 0);
      expect(ach.isUnlocked, false);
      expect(ach.unlockedAt, isNull);
    });

    test('progress calculation', () {
      const ach = Achievement(
        id: 'meals_10',
        title: 'Home Cook',
        description: 'Cook 10 meals',
        emoji: '👨‍🍳',
        category: 'cooking',
        requiredValue: 10,
        currentValue: 5,
      );
      expect(ach.progress, 0.5);
    });

    test('progress clamps to 1.0 when exceeded', () {
      const ach = Achievement(
        id: 'meals_10',
        title: 'Home Cook',
        description: 'Cook 10 meals',
        emoji: '👨‍🍳',
        category: 'cooking',
        requiredValue: 10,
        currentValue: 15,
      );
      expect(ach.progress, 1.0);
    });

    test('progress is 0 when requiredValue is 0', () {
      const ach = Achievement(
        id: 'test',
        title: 'Test',
        description: 'Test',
        emoji: '🎯',
        category: 'test',
        requiredValue: 0,
        currentValue: 5,
      );
      expect(ach.progress, 0);
    });

    test('progress is 0 when currentValue is 0', () {
      const ach = Achievement(
        id: 'test',
        title: 'Test',
        description: 'Test',
        emoji: '🎯',
        category: 'test',
        requiredValue: 10,
        currentValue: 0,
      );
      expect(ach.progress, 0.0);
    });

    test('toJson/fromJson roundtrip', () {
      final original = Achievement(
        id: 'streak_7',
        title: 'Week Warrior',
        description: '7-day cooking streak',
        emoji: '🔥',
        category: 'streak',
        requiredValue: 7,
        currentValue: 7,
        isUnlocked: true,
        unlockedAt: DateTime(2025, 6, 1),
      );
      final restored = Achievement.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.emoji, original.emoji);
      expect(restored.category, original.category);
      expect(restored.requiredValue, original.requiredValue);
      expect(restored.currentValue, original.currentValue);
      expect(restored.isUnlocked, original.isUnlocked);
    });

    test('fromJson with missing optional fields', () {
      final json = {
        'id': 'test',
        'title': 'Test',
        'description': 'Test',
        'emoji': '🎯',
        'category': 'test',
        'requiredValue': 5,
      };
      final ach = Achievement.fromJson(json);
      expect(ach.currentValue, 0);
      expect(ach.isUnlocked, false);
      expect(ach.unlockedAt, isNull);
    });
  });

  group('RecipeCollection', () {
    test('creation with defaults', () {
      final col = RecipeCollection(
        id: 'col-1',
        name: 'Italian Classics',
        authorId: 'user-1',
        createdAt: DateTime(2025, 1, 1),
      );
      expect(col.emoji, '📚');
      expect(col.recipeIds, isEmpty);
      expect(col.isPublic, false);
      expect(col.followersCount, 0);
      expect(col.description, isNull);
      expect(col.coverImageUrl, isNull);
    });

    test('creation with all fields', () {
      final col = RecipeCollection(
        id: 'col-2',
        name: 'Quick Dinners',
        description: 'Under 30 minutes',
        emoji: '⚡',
        coverImageUrl: 'https://example.com/cover.jpg',
        recipeIds: ['r1', 'r2', 'r3'],
        isPublic: true,
        authorId: 'user-1',
        createdAt: DateTime(2025, 1, 1),
        followersCount: 100,
      );
      expect(col.description, 'Under 30 minutes');
      expect(col.emoji, '⚡');
      expect(col.recipeIds.length, 3);
      expect(col.isPublic, true);
      expect(col.followersCount, 100);
    });

    test('copyWith preserves unchanged values', () {
      final original = RecipeCollection(
        id: 'col-1',
        name: 'My Recipes',
        authorId: 'user-1',
        createdAt: DateTime(2025, 1, 1),
      );
      final updated = original.copyWith(name: 'Favorite Recipes');
      expect(updated.id, 'col-1');
      expect(updated.name, 'Favorite Recipes');
      expect(updated.authorId, 'user-1');
    });

    test('copyWith adds recipes', () {
      final original = RecipeCollection(
        id: 'col-1',
        name: 'My Recipes',
        authorId: 'user-1',
        createdAt: DateTime(2025, 1, 1),
        recipeIds: ['r1'],
      );
      final updated = original.copyWith(recipeIds: [...original.recipeIds, 'r2']);
      expect(updated.recipeIds, ['r1', 'r2']);
    });

    test('toJson/fromJson roundtrip', () {
      final original = RecipeCollection(
        id: 'col-3',
        name: 'Baking',
        description: 'Sweet treats',
        emoji: '🧁',
        coverImageUrl: 'https://example.com/baking.jpg',
        recipeIds: ['r10', 'r20'],
        isPublic: true,
        authorId: 'user-2',
        createdAt: DateTime(2025, 3, 1),
        followersCount: 50,
      );
      final restored = RecipeCollection.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.emoji, original.emoji);
      expect(restored.coverImageUrl, original.coverImageUrl);
      expect(restored.recipeIds, original.recipeIds);
      expect(restored.isPublic, original.isPublic);
      expect(restored.authorId, original.authorId);
      expect(restored.followersCount, original.followersCount);
    });

    test('fromJson with missing optional fields', () {
      final json = {
        'id': 'col-4',
        'name': 'Test',
        'authorId': 'user-1',
        'createdAt': '2025-01-01T00:00:00.000',
      };
      final col = RecipeCollection.fromJson(json);
      expect(col.emoji, '📚');
      expect(col.recipeIds, isEmpty);
      expect(col.isPublic, false);
      expect(col.followersCount, 0);
    });
  });
}
