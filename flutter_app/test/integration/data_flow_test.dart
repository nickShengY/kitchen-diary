import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kitchen_diary/models/meal_plan_model.dart';
import 'package:kitchen_diary/models/nutrition_model.dart';
import 'package:kitchen_diary/models/pantry_model.dart';
import 'package:kitchen_diary/models/recipe_model.dart';
import 'package:kitchen_diary/models/procedure_model.dart';
import 'package:kitchen_diary/providers/meal_plan_provider.dart';
import 'package:kitchen_diary/providers/pantry_provider.dart';
import 'package:kitchen_diary/providers/nutrition_provider.dart';
import 'package:kitchen_diary/providers/decider_provider.dart';
import 'package:kitchen_diary/providers/theme_provider.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_integration_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<T> create<T>(T Function() factory) async {
    final p = factory();
    await Future.delayed(const Duration(milliseconds: 250));
    return p;
  }

  group('Meal Planning + Nutrition Data Flow', () {
    test('logging a meal updates nutrition progress', () async {
      final nutrition = await create(() => NutritionProvider());
      expect(nutrition.calorieProgress, 0);

      await nutrition.logMeal(const NutritionInfo(
        calories: 500, protein: 30, carbs: 60, fat: 15,
      ));
      expect(nutrition.calorieProgress, greaterThan(0));
      expect(nutrition.todayLog, isNotNull);
      expect(nutrition.todayLog!.mealsLogged, 1);
    });

    test('adding meals to plan and tracking cooking', () async {
      final mealPlan = await create(() => MealPlanProvider());
      final nutrition = await create(() => NutritionProvider());

      // Add a meal to today's plan
      final today = mealPlan.currentWeekPlan!.days
          .firstWhere((d) => d.date.day == DateTime.now().day,
              orElse: () => mealPlan.currentWeekPlan!.days.first);
      const meal = PlannedMeal(
        id: 'integration-meal-1',
        title: 'Grilled Chicken Salad',
        slot: MealSlot.lunch,
        estimatedCalories: 450,
        prepTimeMinutes: 20,
      );
      await mealPlan.addMealToDay(today.date, meal);

      // Toggle as cooked
      await mealPlan.toggleMealCooked(today.date, 'integration-meal-1');

      // Record the cook in nutrition
      await nutrition.recordCook();

      // Verify
      final plan = mealPlan.currentWeekPlan!;
      final dayPlan = plan.days.firstWhere((d) => d.date == today.date);
      expect(dayPlan.meals.first.isCooked, true);
      expect(dayPlan.cookedCount, 1);
      expect(nutrition.streak.totalMealsCooked, 1);
      expect(nutrition.streak.currentStreak, 1);
    });

    test('full day meal planning workflow', () async {
      final mealPlan = await create(() => MealPlanProvider());

      final date = mealPlan.currentWeekPlan!.days.first.date;

      // Add breakfast, lunch, dinner
      await mealPlan.addMealToDay(date, const PlannedMeal(
        id: 'b', title: 'Omelette', slot: MealSlot.breakfast,
        estimatedCalories: 350, prepTimeMinutes: 10,
      ));
      await mealPlan.addMealToDay(date, const PlannedMeal(
        id: 'l', title: 'Grilled Chicken', slot: MealSlot.lunch,
        estimatedCalories: 500, prepTimeMinutes: 25,
      ));
      await mealPlan.addMealToDay(date, const PlannedMeal(
        id: 'd', title: 'Pasta', slot: MealSlot.dinner,
        estimatedCalories: 600, prepTimeMinutes: 30,
      ));

      final day = mealPlan.currentWeekPlan!.days.first;
      expect(day.meals.length, 3);
      expect(day.totalCalories, 1450);
      expect(day.totalPrepTime, 65);
      expect(day.cookedCount, 0);

      // Cook all meals
      await mealPlan.toggleMealCooked(date, 'b');
      await mealPlan.toggleMealCooked(date, 'l');
      await mealPlan.toggleMealCooked(date, 'd');

      final cookedDay = mealPlan.currentWeekPlan!.days.first;
      expect(cookedDay.cookedCount, 3);
    });
  });

  group('Pantry + Recipe Data Flow', () {
    test('pantry items can be used as recipe ingredients', () async {
      final pantry = await create(() => PantryProvider());
      await pantry.addItem(const PantryItem(
        id: 'eggs',
        name: 'Eggs',
        category: PantryCategory.dairy,
        quantity: 12,
        unit: 'pcs',
      ));

      // Check that pantry has items
      expect(pantry.allItems, isNotEmpty);

      // Get available ingredient names
      final available = pantry.availableIngredientNames;
      expect(available, isNotEmpty);

      // Create a recipe that uses available ingredients
      final recipe = RecipeModel(
        id: 'r-integration',
        title: 'Quick Eggs',
        authorId: 'test-user',
        authorName: 'Test Chef',
        authorAvatar: '👨‍🍳',
        steps: [
          CookingStep(
            id: 's1', stepNumber: 1, station: StationCategory.prep,
            ingredients: [
              RecipeIngredient(
                ingredientId: 'eggs', name: 'Eggs',
                emoji: '🥚', amount: '3', unit: 'pcs',
              ),
            ],
            toolId: 'pan', toolName: 'Frying Pan', toolIcon: '🍳',
            actionId: 'fry', actionName: 'Fry', actionEmoji: '🍳',
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(recipe.allIngredients.length, 1);
      expect(recipe.allIngredients.first.name, 'Eggs');

      // Use eggs from pantry
      final eggs = pantry.allItems.firstWhere((i) => i.name == 'Eggs');
      await pantry.useItem(eggs.id, 3);
      final remaining = pantry.allItems.firstWhere((i) => i.id == eggs.id);
      expect(remaining.quantity, 9); // 12 - 3
    });

    test('pantry filtering works with search and category combined', () async {
      final pantry = await create(() => PantryProvider());
      await pantry.addItem(const PantryItem(
        id: 'eggs',
        name: 'Eggs',
        category: PantryCategory.dairy,
        quantity: 12,
        unit: 'pcs',
      ));
      await pantry.addItem(const PantryItem(
        id: 'milk',
        name: 'Milk',
        category: PantryCategory.dairy,
        quantity: 1,
        unit: 'L',
      ));
      await pantry.addItem(const PantryItem(
        id: 'rice',
        name: 'Rice',
        category: PantryCategory.grains,
        quantity: 2,
        unit: 'kg',
      ));

      // Filter by dairy category
      pantry.setCategory(PantryCategory.dairy);
      final dairyCount = pantry.items.length;
      expect(dairyCount, greaterThan(0));

      // Further filter by search
      pantry.setSearchQuery('Eggs');
      expect(pantry.items.length, lessThanOrEqualTo(dairyCount));

      // Clear all filters
      pantry.setCategory(null);
      pantry.setSearchQuery('');
      expect(pantry.items.length, pantry.allItems.length);
    });
  });

  group('Grocery List Data Flow', () {
    test('create grocery list and manage items through full lifecycle', () async {
      final mealPlan = await create(() => MealPlanProvider());

      // Create a grocery list
      final list = await mealPlan.createGroceryList('Weekly Shopping');
      expect(list.items, isEmpty);

      // Add items
      await mealPlan.addGroceryItem(list.id, const GroceryItem(
        id: 'g1', name: 'Tomatoes', amount: '4', unit: 'pcs',
        category: 'produce',
      ));
      await mealPlan.addGroceryItem(list.id, const GroceryItem(
        id: 'g2', name: 'Chicken', amount: '500', unit: 'g',
        category: 'meat',
      ));
      await mealPlan.addGroceryItem(list.id, const GroceryItem(
        id: 'g3', name: 'Rice', amount: '1', unit: 'kg',
        category: 'grains',
      ));

      var groceryList = mealPlan.groceryLists.first;
      expect(groceryList.items.length, 3);
      expect(groceryList.neededCount, 3);
      expect(groceryList.progress, 0.0);

      // Move items through lifecycle: needed -> inCart -> purchased
      await mealPlan.toggleGroceryItemStatus(list.id, 'g1');
      groceryList = mealPlan.groceryLists.first;
      expect(groceryList.items.firstWhere((i) => i.id == 'g1').status, GroceryItemStatus.inCart);
      expect(groceryList.inCartCount, 1);

      await mealPlan.toggleGroceryItemStatus(list.id, 'g1');
      groceryList = mealPlan.groceryLists.first;
      expect(groceryList.items.firstWhere((i) => i.id == 'g1').status, GroceryItemStatus.purchased);
      expect(groceryList.purchasedCount, 1);

      // Purchase all
      await mealPlan.toggleGroceryItemStatus(list.id, 'g2'); // needed -> inCart
      await mealPlan.toggleGroceryItemStatus(list.id, 'g2'); // inCart -> purchased
      await mealPlan.toggleGroceryItemStatus(list.id, 'g3'); // needed -> inCart
      await mealPlan.toggleGroceryItemStatus(list.id, 'g3'); // inCart -> purchased

      groceryList = mealPlan.groceryLists.first;
      expect(groceryList.purchasedCount, 3);
      expect(groceryList.progress, 1.0);
    });
  });

  group('Recipe Procedure Data Flow', () {
    test('recipe with procedure generates display steps from graph', () {
      final recipe = RecipeModel(
        id: 'r-proc',
        title: 'Procedure Recipe',
        authorId: 'a', authorName: 'Chef', authorAvatar: '👨‍🍳',
        steps: [], // empty original steps
        procedure: const RecipeProcedure(
          version: '1.0.0',
          lots: [
            MaterialLot(id: 'l1', ingredientId: 'tomato', name: 'Tomato', emoji: '🍅', amount: '2', unit: 'pcs', state: 'raw', assetKey: 'tomato_raw'),
            MaterialLot(id: 'l2', ingredientId: 'onion', name: 'Onion', emoji: '🧅', amount: '1', unit: 'pcs', state: 'raw', assetKey: 'onion_raw'),
            MaterialLot(id: 'l3', ingredientId: 'sauce', name: 'Sauce', emoji: '🥫', amount: '500', unit: 'ml', state: 'cooked', assetKey: 'sauce_cooked'),
          ],
          operations: [
            ProcedureOperation(
              id: 'op1', station: ProcedureStation.prep,
              actionId: 'chop', actionName: 'Chop', actionEmoji: '🔪',
              toolId: 'knife', toolName: 'Knife', toolIcon: '🔪',
              inputLotIds: ['l1', 'l2'], outputLotIds: ['l3'],
            ),
            ProcedureOperation(
              id: 'op2', station: ProcedureStation.cook,
              actionId: 'simmer', actionName: 'Simmer', actionEmoji: '♨️',
              toolId: 'pot', toolName: 'Pot', toolIcon: '🍲',
              temperature: 'Low', duration: '30 mins',
              inputLotIds: ['l3'], outputLotIds: [],
            ),
          ],
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final steps = recipe.displaySteps;
      expect(steps.length, 2);

      // First step: Chop - has 2 ingredients
      expect(steps[0].actionName, 'Chop');
      expect(steps[0].stepNumber, 1);
      expect(steps[0].station, StationCategory.prep);
      expect(steps[0].ingredients.length, 2);
      expect(steps[0].ingredients.map((i) => i.name).toList()..sort(),
          ['Onion', 'Tomato']);

      // Second step: Simmer - has 1 ingredient (sauce from lots)
      expect(steps[1].actionName, 'Simmer');
      expect(steps[1].stepNumber, 2);
      expect(steps[1].station, StationCategory.cook);
      expect(steps[1].temperature, 'Low');
      expect(steps[1].duration, '30 mins');
    });

    test('recipe falls back to original steps when procedure is empty', () {
      const originalStep = CookingStep(
        id: 's1', stepNumber: 1, station: StationCategory.prep,
        ingredients: [], toolId: 't', toolName: 'T', toolIcon: '🔧',
        actionId: 'a', actionName: 'Original Action', actionEmoji: '🔪',
      );
      final recipe = RecipeModel(
        id: 'r', title: 'Fallback Recipe',
        authorId: 'a', authorName: 'Chef', authorAvatar: '👨‍🍳',
        steps: [originalStep],
        procedure: RecipeProcedure.empty(),
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );

      expect(recipe.displaySteps.length, 1);
      expect(recipe.displaySteps.first.actionName, 'Original Action');
    });
  });

  group('Achievement + Cooking Streak Data Flow', () {
    test('cooking multiple meals unlocks achievements progressively', () async {
      final nutrition = await create(() => NutritionProvider());

      // Initially no achievements unlocked
      expect(nutrition.unlockedAchievements, isEmpty);

      // Cook first meal
      await nutrition.recordCook();
      expect(nutrition.unlockedAchievements.length, 1);
      expect(nutrition.unlockedAchievements.first.id, 'first_cook');

      // Cook more meals
      for (int i = 0; i < 9; i++) {
        await nutrition.recordCook();
      }

      // meals_10 should now be unlocked (10 total meals)
      final meals10 = nutrition.achievements.firstWhere((a) => a.id == 'meals_10');
      expect(meals10.isUnlocked, true);

      // But meals_50 should not yet be unlocked
      final meals50 = nutrition.achievements.firstWhere((a) => a.id == 'meals_50');
      expect(meals50.isUnlocked, false);
      expect(meals50.currentValue, 10);
    });

    test('collection creation triggers curator achievement', () async {
      final nutrition = await create(() => NutritionProvider());

      for (int i = 0; i < 3; i++) {
        await nutrition.addCollection(RecipeCollection(
          id: 'col-$i', name: 'Collection $i',
          authorId: 'user-1', createdAt: DateTime.now(),
        ));
      }

      final curator = nutrition.achievements.firstWhere((a) => a.id == 'collections_3');
      expect(curator.isUnlocked, true);
      expect(curator.unlockedAt, isNotNull);
    });
  });

  group('Theme + Decider Provider Independence', () {
    test('theme and decider providers operate independently', () async {
      final theme = await create(() => ThemeProvider());
      final decider = await create(() => DeciderProvider());

      // Modify theme
      await theme.toggleTheme();
      expect(theme.isDarkMode, true);

      // Decider should be unaffected
      expect(decider.cuisines, isEmpty);
      expect(decider.isLoading, false);

      // Modify decider
      await decider.addCuisine(name: 'New Cuisine', emoji: '🆕');

      // Theme should be unaffected
      expect(theme.isDarkMode, true);
    });
  });

  group('Multi-Provider Data Persistence', () {
    test('all providers persist data independently', () async {
      final mealPlan = await create(() => MealPlanProvider());
      final pantry = await create(() => PantryProvider());
      final nutrition = await create(() => NutritionProvider());
      final theme = await create(() => ThemeProvider());
      final decider = await create(() => DeciderProvider());

      // Make changes to each
      final date = mealPlan.currentWeekPlan!.days.first.date;
      await mealPlan.addMealToDay(date, const PlannedMeal(
        id: 'persist-m', title: 'Persist Meal', slot: MealSlot.lunch,
      ));
      await pantry.addItem(const PantryItem(
        id: 'persist-p', name: 'Persist Item',
        category: PantryCategory.snacks, quantity: 1, unit: 'pcs',
      ));
      await nutrition.addWater(500);
      await theme.toggleTheme();
      await decider.toggleFavorite('Test Dish');

      // Recreate all providers and verify persistence
      final mp2 = await create(() => MealPlanProvider());
      final pa2 = await create(() => PantryProvider());
      final nu2 = await create(() => NutritionProvider());
      final th2 = await create(() => ThemeProvider());
      final de2 = await create(() => DeciderProvider());

      expect(mp2.currentWeekPlan!.days.first.meals.any((m) => m.id == 'persist-m'), true);
      expect(pa2.allItems.any((i) => i.id == 'persist-p'), true);
      expect(nu2.todayWaterMl, 500);
      expect(th2.isDarkMode, true);
      expect(de2.favoriteDishes.contains('Test Dish'), true);
    });
  });

  group('Nutrition Logging Workflow', () {
    test('full day nutrition tracking with water', () async {
      final nutrition = await create(() => NutritionProvider());

      // Breakfast
      await nutrition.logMeal(const NutritionInfo(
        calories: 400, protein: 20, carbs: 50, fat: 12,
      ));
      await nutrition.addWater(500);

      // Lunch
      await nutrition.logMeal(const NutritionInfo(
        calories: 600, protein: 35, carbs: 70, fat: 20,
      ));
      await nutrition.addWater(750);

      // Dinner
      await nutrition.logMeal(const NutritionInfo(
        calories: 700, protein: 40, carbs: 80, fat: 25,
      ));
      await nutrition.addWater(500);

      // Check totals
      expect(nutrition.todayLog!.totals.calories, 1700);
      expect(nutrition.todayLog!.totals.protein, 95);
      expect(nutrition.todayLog!.mealsLogged, 3);
      expect(nutrition.todayWaterMl, 1750);

      // Progress against default 2000 cal goal
      expect(nutrition.calorieProgress, closeTo(0.85, 0.01));
      expect(nutrition.waterProgress, closeTo(0.7, 0.01)); // 1750/2500
    });
  });

  group('Week Navigation Data Flow', () {
    test('navigating weeks creates and maintains separate plans', () async {
      final mealPlan = await create(() => MealPlanProvider());

      // Current week
      final currentWeekStart = mealPlan.focusedWeekStart;
      final date = mealPlan.currentWeekPlan!.days.first.date;
      await mealPlan.addMealToDay(date, const PlannedMeal(
        id: 'current-week-meal', title: 'This Week', slot: MealSlot.lunch,
      ));

      // Navigate to next week
      await mealPlan.navigateWeek(1);
      expect(mealPlan.focusedWeekStart, currentWeekStart.add(const Duration(days: 7)));

      // Next week should have empty meals
      final nextWeekPlan = mealPlan.weekPlans.firstWhere(
        (p) => p.weekStart.isAtSameMomentAs(mealPlan.focusedWeekStart),
      );
      for (final day in nextWeekPlan.days) {
        expect(day.meals, isEmpty);
      }

      // Navigate back - meals should still be there
      await mealPlan.navigateWeek(-1);
      final restored = mealPlan.currentWeekPlan!.days.first.meals;
      expect(restored.any((m) => m.id == 'current-week-meal'), true);
    });
  });
}
