import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kitchen_diary/models/nutrition_model.dart';
import 'package:kitchen_diary/providers/nutrition_provider.dart';

void main() {
  late NutritionProvider provider;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_nutrition_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<NutritionProvider> createProvider() async {
    final p = NutritionProvider();
    await Future.delayed(const Duration(milliseconds: 200));
    return p;
  }

  group('NutritionProvider initialization', () {
    test('finishes loading', () async {
      provider = await createProvider();
      expect(provider.isLoading, false);
    });

    test('has default goal', () async {
      provider = await createProvider();
      expect(provider.goal.targetCalories, 2000);
      expect(provider.goal.targetProtein, 50);
    });

    test('creates default achievements on first run', () async {
      provider = await createProvider();
      expect(provider.achievements, isNotEmpty);
      expect(provider.achievements.length, 7);
    });

    test('default achievements are not unlocked', () async {
      provider = await createProvider();
      for (final ach in provider.achievements) {
        expect(ach.isUnlocked, false);
      }
    });

    test('starts with empty logs', () async {
      provider = await createProvider();
      expect(provider.logs, isEmpty);
    });

    test('starts with empty collections', () async {
      provider = await createProvider();
      expect(provider.collections, isEmpty);
    });

    test('starts with zero water', () async {
      provider = await createProvider();
      expect(provider.todayWaterMl, 0);
    });
  });

  group('updateGoal', () {
    test('changes goal values', () async {
      provider = await createProvider();
      const newGoal = NutritionGoal(
        targetCalories: 1800,
        targetProtein: 70,
        targetCarbs: 200,
        targetFat: 55,
      );
      await provider.updateGoal(newGoal);
      expect(provider.goal.targetCalories, 1800);
      expect(provider.goal.targetProtein, 70);
    });
  });

  group('logMeal', () {
    test('creates new daily log on first meal', () async {
      provider = await createProvider();
      await provider.logMeal(const NutritionInfo(
        calories: 500, protein: 30, carbs: 60, fat: 15,
      ));
      expect(provider.logs.length, 1);
      expect(provider.todayLog, isNotNull);
      expect(provider.todayLog!.totals.calories, 500);
      expect(provider.todayLog!.mealsLogged, 1);
    });

    test('accumulates nutrients on same day', () async {
      provider = await createProvider();
      await provider.logMeal(const NutritionInfo(
        calories: 300, protein: 20, carbs: 40, fat: 10,
      ));
      await provider.logMeal(const NutritionInfo(
        calories: 200, protein: 15, carbs: 30, fat: 8,
      ));
      expect(provider.todayLog!.totals.calories, 500);
      expect(provider.todayLog!.totals.protein, 35);
      expect(provider.todayLog!.mealsLogged, 2);
    });

    test('third meal accumulates further', () async {
      provider = await createProvider();
      await provider.logMeal(const NutritionInfo(calories: 100, protein: 5, carbs: 10, fat: 3));
      await provider.logMeal(const NutritionInfo(calories: 200, protein: 10, carbs: 20, fat: 6));
      await provider.logMeal(const NutritionInfo(calories: 300, protein: 15, carbs: 30, fat: 9));
      expect(provider.todayLog!.totals.calories, 600);
      expect(provider.todayLog!.mealsLogged, 3);
    });
  });

  group('progress calculations', () {
    test('calorieProgress is 0 when no log', () async {
      provider = await createProvider();
      expect(provider.calorieProgress, 0);
    });

    test('calorieProgress calculates correctly', () async {
      provider = await createProvider();
      await provider.logMeal(const NutritionInfo(
        calories: 1000, protein: 25, carbs: 125, fat: 32,
      ));
      expect(provider.calorieProgress, closeTo(0.5, 0.01));
    });

    test('proteinProgress is clamped to 1.5', () async {
      provider = await createProvider();
      await provider.logMeal(const NutritionInfo(
        calories: 5000, protein: 200, carbs: 500, fat: 200,
      ));
      expect(provider.proteinProgress, lessThanOrEqualTo(1.5));
    });

    test('waterProgress calculates from 2500ml target', () async {
      provider = await createProvider();
      await provider.addWater(1250);
      expect(provider.waterProgress, closeTo(0.5, 0.01));
    });

    test('waterProgress clamps at 1.5', () async {
      provider = await createProvider();
      await provider.addWater(5000);
      expect(provider.waterProgress, 1.5);
    });

    test('all progress types are 0 with no data', () async {
      provider = await createProvider();
      expect(provider.calorieProgress, 0);
      expect(provider.proteinProgress, 0);
      expect(provider.carbsProgress, 0);
      expect(provider.fatProgress, 0);
    });
  });

  group('addWater', () {
    test('adds water', () async {
      provider = await createProvider();
      await provider.addWater(250);
      expect(provider.todayWaterMl, 250);
    });

    test('accumulates water', () async {
      provider = await createProvider();
      await provider.addWater(250);
      await provider.addWater(350);
      await provider.addWater(150);
      expect(provider.todayWaterMl, 750);
    });
  });

  group('recordCook', () {
    test('first cook sets streak to 1', () async {
      provider = await createProvider();
      await provider.recordCook();
      expect(provider.streak.currentStreak, 1);
      expect(provider.streak.totalMealsCooked, 1);
      expect(provider.streak.lastCookDate, isNotNull);
    });

    test('cooking same day does not increase streak', () async {
      provider = await createProvider();
      await provider.recordCook();
      await provider.recordCook();
      // Same day, diff should be 0, so streak stays the same
      expect(provider.streak.currentStreak, 1);
      expect(provider.streak.totalMealsCooked, 2);
    });

    test('longestStreak updates when current exceeds it', () async {
      provider = await createProvider();
      await provider.recordCook();
      expect(provider.streak.longestStreak, 1);
    });

    test('unlocks first_cook achievement after cooking', () async {
      provider = await createProvider();
      await provider.recordCook();
      final firstCook = provider.achievements.firstWhere((a) => a.id == 'first_cook');
      expect(firstCook.isUnlocked, true);
      expect(firstCook.unlockedAt, isNotNull);
    });

    test('meals_10 achievement tracks progress', () async {
      provider = await createProvider();
      for (int i = 0; i < 5; i++) {
        await provider.recordCook();
      }
      final meals10 = provider.achievements.firstWhere((a) => a.id == 'meals_10');
      expect(meals10.currentValue, 5);
      expect(meals10.isUnlocked, false);
    });
  });

  group('achievements', () {
    test('unlockedAchievements returns only unlocked', () async {
      provider = await createProvider();
      await provider.recordCook(); // Unlocks first_cook
      final unlocked = provider.unlockedAchievements;
      expect(unlocked.length, 1);
      expect(unlocked.first.id, 'first_cook');
    });

    test('inProgressAchievements returns partially completed', () async {
      provider = await createProvider();
      await provider.recordCook();
      final inProgress = provider.inProgressAchievements;
      // streak_7, streak_30, meals_10, meals_50, meals_100 should be in progress
      expect(inProgress.length, greaterThan(0));
      for (final a in inProgress) {
        expect(a.isUnlocked, false);
        expect(a.currentValue, greaterThan(0));
      }
    });
  });

  group('collections', () {
    test('addCollection adds to list', () async {
      provider = await createProvider();
      final col = RecipeCollection(
        id: 'col-1', name: 'Test Collection',
        authorId: 'user-1', createdAt: DateTime(2025, 1, 1),
      );
      await provider.addCollection(col);
      expect(provider.collections.length, 1);
      expect(provider.collections.first.name, 'Test Collection');
    });

    test('addRecipeToCollection adds recipe id', () async {
      provider = await createProvider();
      final col = RecipeCollection(
        id: 'col-1', name: 'Test',
        authorId: 'user-1', createdAt: DateTime(2025, 1, 1),
      );
      await provider.addCollection(col);
      await provider.addRecipeToCollection('col-1', 'recipe-1');
      expect(provider.collections.first.recipeIds, ['recipe-1']);
    });

    test('addRecipeToCollection does not duplicate', () async {
      provider = await createProvider();
      final col = RecipeCollection(
        id: 'col-1', name: 'Test',
        authorId: 'user-1', createdAt: DateTime(2025, 1, 1),
      );
      await provider.addCollection(col);
      await provider.addRecipeToCollection('col-1', 'recipe-1');
      await provider.addRecipeToCollection('col-1', 'recipe-1');
      expect(provider.collections.first.recipeIds.length, 1);
    });

    test('addRecipeToCollection does nothing for nonexistent collection', () async {
      provider = await createProvider();
      await provider.addRecipeToCollection('nonexistent', 'recipe-1');
      // Should not throw
    });

    test('removeRecipeFromCollection removes recipe id', () async {
      provider = await createProvider();
      final col = RecipeCollection(
        id: 'col-1', name: 'Test',
        authorId: 'user-1', createdAt: DateTime(2025, 1, 1),
        recipeIds: ['r1', 'r2', 'r3'],
      );
      await provider.addCollection(col);
      await provider.removeRecipeFromCollection('col-1', 'r2');
      expect(provider.collections.first.recipeIds, ['r1', 'r3']);
    });

    test('removeCollection removes by id', () async {
      provider = await createProvider();
      await provider.addCollection(RecipeCollection(
        id: 'col-a', name: 'A', authorId: 'u', createdAt: DateTime(2025, 1, 1),
      ));
      await provider.addCollection(RecipeCollection(
        id: 'col-b', name: 'B', authorId: 'u', createdAt: DateTime(2025, 1, 1),
      ));
      await provider.removeCollection('col-a');
      expect(provider.collections.length, 1);
      expect(provider.collections.first.id, 'col-b');
    });

    test('adding 3 collections unlocks curator achievement', () async {
      provider = await createProvider();
      for (int i = 0; i < 3; i++) {
        await provider.addCollection(RecipeCollection(
          id: 'col-$i', name: 'Col $i',
          authorId: 'u', createdAt: DateTime(2025, 1, 1),
        ));
      }
      final curator = provider.achievements.firstWhere((a) => a.id == 'collections_3');
      expect(curator.isUnlocked, true);
    });
  });

  group('persistence', () {
    test('goal persists across provider instances', () async {
      provider = await createProvider();
      await provider.updateGoal(const NutritionGoal(targetCalories: 3000));

      final provider2 = NutritionProvider();
      await Future.delayed(const Duration(milliseconds: 200));
      expect(provider2.goal.targetCalories, 3000);
    });

    test('water persists across provider instances', () async {
      provider = await createProvider();
      await provider.addWater(1500);

      final provider2 = NutritionProvider();
      await Future.delayed(const Duration(milliseconds: 200));
      expect(provider2.todayWaterMl, 1500);
    });
  });
}
