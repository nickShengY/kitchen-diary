import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_diary/models/meal_plan_model.dart';
import 'package:kitchen_diary/models/pantry_model.dart';
import 'package:kitchen_diary/models/nutrition_model.dart';
import 'package:kitchen_diary/models/recipe_model.dart';
import 'package:kitchen_diary/models/procedure_model.dart';
import 'package:kitchen_diary/models/community_model.dart';
import 'package:kitchen_diary/models/user_model.dart';

void main() {
  group('Edge Cases - Null and Empty Input', () {
    test('NutritionInfo fromJson with empty map', () {
      final info = NutritionInfo.fromJson({});
      expect(info.calories, 0);
      expect(info.protein, 0);
      expect(info.carbs, 0);
      expect(info.fat, 0);
      expect(info.fiber, 0);
      expect(info.sugar, 0);
      expect(info.sodium, 0);
      expect(info.saturatedFat, isNull);
    });

    test('NutritionGoal fromJson with empty map uses defaults', () {
      final goal = NutritionGoal.fromJson({});
      expect(goal.targetCalories, 2000);
      expect(goal.targetProtein, 50);
      expect(goal.targetCarbs, 250);
      expect(goal.targetFat, 65);
      expect(goal.targetFiber, 25);
      expect(goal.targetSodium, 2300);
    });

    test('MaterialLot fromJson with empty map uses defaults', () {
      final lot = MaterialLot.fromJson({});
      expect(lot.id, '');
      expect(lot.name, '');
      expect(lot.amount, '1');
      expect(lot.unit, 'pcs');
      expect(lot.state, 'raw');
    });

    test('ProcedureOperation fromJson with empty map uses defaults', () {
      final op = ProcedureOperation.fromJson({});
      expect(op.id, '');
      expect(op.station, ProcedureStation.prep);
      expect(op.inputLotIds, isEmpty);
      expect(op.outputLotIds, isEmpty);
    });

    test('RecipeProcedure fromJson with empty map', () {
      final proc = RecipeProcedure.fromJson({});
      expect(proc.version, '1.0.0');
      expect(proc.lots, isEmpty);
      expect(proc.operations, isEmpty);
    });

    test('GroceryItem fromJson with missing amount/unit', () {
      final item = GroceryItem.fromJson({
        'id': 'x', 'name': 'X', 'status': 'needed',
      });
      expect(item.amount, '');
      expect(item.unit, '');
    });

    test('PlannedMeal fromJson with minimal data', () {
      final meal = PlannedMeal.fromJson({
        'id': 'x', 'title': 'X', 'slot': 'breakfast',
      });
      expect(meal.servings, 2);
      expect(meal.estimatedCalories, 0);
      expect(meal.isCooked, false);
    });

    test('CookingStreak fromJson with empty map', () {
      final streak = CookingStreak.fromJson({});
      expect(streak.currentStreak, 0);
      expect(streak.longestStreak, 0);
      expect(streak.totalMealsCooked, 0);
      expect(streak.lastCookDate, isNull);
      expect(streak.cuisineBreakdown, isEmpty);
    });

    test('ForumPostModel.fromApiJson with entirely empty map', () {
      final post = ForumPostModel.fromApiJson({});
      expect(post.id, '');
      expect(post.authorName, 'Chef');
      expect(post.likes, 0);
      expect(post.views, 0);
      expect(post.isPinned, false);
    });
  });

  group('Edge Cases - Boundary Values', () {
    test('Achievement progress with zero requiredValue', () {
      const ach = Achievement(
        id: 'x', title: 'X', description: 'X',
        emoji: '🎯', category: 'test',
        requiredValue: 0, currentValue: 10,
      );
      expect(ach.progress, 0);
    });

    test('Achievement progress clamps at 1.0 when over limit', () {
      const ach = Achievement(
        id: 'x', title: 'X', description: 'X',
        emoji: '🎯', category: 'test',
        requiredValue: 5, currentValue: 100,
      );
      expect(ach.progress, 1.0);
    });

    test('Achievement progress at exactly required value', () {
      const ach = Achievement(
        id: 'x', title: 'X', description: 'X',
        emoji: '🎯', category: 'test',
        requiredValue: 10, currentValue: 10,
      );
      expect(ach.progress, 1.0);
    });

    test('GroceryList progress with all purchased', () {
      final list = GroceryList(
        id: 'gl', name: 'Test', createdAt: DateTime(2025, 1, 1),
        items: const [
          GroceryItem(id: '1', name: 'A', amount: '1', unit: 'x', status: GroceryItemStatus.purchased),
          GroceryItem(id: '2', name: 'B', amount: '1', unit: 'x', status: GroceryItemStatus.purchased),
        ],
      );
      expect(list.progress, 1.0);
    });

    test('GroceryList progress with none purchased', () {
      final list = GroceryList(
        id: 'gl', name: 'Test', createdAt: DateTime(2025, 1, 1),
        items: const [
          GroceryItem(id: '1', name: 'A', amount: '1', unit: 'x', status: GroceryItemStatus.needed),
          GroceryItem(id: '2', name: 'B', amount: '1', unit: 'x', status: GroceryItemStatus.inCart),
        ],
      );
      expect(list.progress, 0.0);
    });

    test('DayPlan with zero-calorie meals', () {
      final plan = DayPlan(
        date: DateTime(2025, 1, 1),
        meals: const [
          PlannedMeal(id: '1', title: 'Water', slot: MealSlot.breakfast, estimatedCalories: 0),
          PlannedMeal(id: '2', title: 'Tea', slot: MealSlot.morningSnack, estimatedCalories: 0),
        ],
      );
      expect(plan.totalCalories, 0);
      expect(plan.totalPrepTime, 0);
    });

    test('PantryItem with zero quantity', () {
      const item = PantryItem(
        id: 'p1', name: 'Empty', category: PantryCategory.other,
        quantity: 0, unit: 'pcs',
      );
      expect(item.quantity, 0);
    });

    test('PantryItem with very large quantity', () {
      const item = PantryItem(
        id: 'p1', name: 'Huge Stock', category: PantryCategory.grains,
        quantity: 999999.99, unit: 'kg',
      );
      expect(item.quantity, 999999.99);
    });

    test('NutritionInfo with zero values', () {
      const info = NutritionInfo(calories: 0, protein: 0, carbs: 0, fat: 0);
      final sum = info + info;
      expect(sum.calories, 0);
      expect(sum.protein, 0);
    });

    test('NutritionInfo addition with very large values', () {
      const a = NutritionInfo(calories: 99999, protein: 9999, carbs: 9999, fat: 9999);
      const b = NutritionInfo(calories: 1, protein: 1, carbs: 1, fat: 1);
      final sum = a + b;
      expect(sum.calories, 100000);
      expect(sum.protein, 10000);
    });

    test('RecipeModel with zero time', () {
      final recipe = RecipeModel(
        id: 'r', title: 'Instant', authorId: 'a', authorName: 'A', authorAvatar: '👨‍🍳',
        steps: [], prepTimeMinutes: 0, cookTimeMinutes: 0,
        createdAt: DateTime(2025, 1, 1), updatedAt: DateTime(2025, 1, 1),
      );
      expect(recipe.totalTimeMinutes, 0);
    });

    test('RecipeModel with very long time', () {
      final recipe = RecipeModel(
        id: 'r', title: 'Slow Cook', authorId: 'a', authorName: 'A', authorAvatar: '👨‍🍳',
        steps: [], prepTimeMinutes: 60, cookTimeMinutes: 1440,
        createdAt: DateTime(2025, 1, 1), updatedAt: DateTime(2025, 1, 1),
      );
      expect(recipe.totalTimeMinutes, 1500);
    });
  });

  group('Edge Cases - Invalid Enum Values in fromJson', () {
    test('PlannedMeal with unknown slot falls back to lunch', () {
      final meal = PlannedMeal.fromJson({
        'id': 'x', 'title': 'X', 'slot': 'brunch',
      });
      expect(meal.slot, MealSlot.lunch);
    });

    test('GroceryItem with unknown status falls back to needed', () {
      final item = GroceryItem.fromJson({
        'id': 'x', 'name': 'X', 'amount': '1', 'unit': 'x',
        'status': 'on_order',
      });
      expect(item.status, GroceryItemStatus.needed);
    });

    test('PantryItem with unknown category falls back to other', () {
      final item = PantryItem.fromJson({
        'id': 'x', 'name': 'X', 'category': 'exotic',
        'quantity': 1, 'unit': 'x',
      });
      expect(item.category, PantryCategory.other);
    });

    test('ProcedureOperation with unknown station falls back to prep', () {
      final op = ProcedureOperation.fromJson({
        'id': 'x', 'station': 'grill', 'actionId': 'a',
        'actionName': 'A', 'actionEmoji': '🔥',
        'inputLotIds': [], 'outputLotIds': [],
      });
      expect(op.station, ProcedureStation.prep);
    });

    test('Ingredient with unknown category falls back to vegetable', () {
      final ing = Ingredient.fromJson({
        'id': 'x', 'name': 'X', 'emoji': '❓',
        'category': 'alien_food', 'defaultUnit': 'pcs',
        'physicalProperties': [],
      });
      expect(ing.category, IngredientCategory.vegetable);
    });
  });

  group('Edge Cases - Date handling', () {
    test('PantryItem expiry at exactly midnight boundary', () {
      final midnight = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final item = PantryItem(
        id: 'p1', name: 'Boundary', category: PantryCategory.dairy,
        quantity: 1, unit: 'L',
        expiryDate: midnight,
      );
      // Should be expired or expiringSoon depending on time of day
      expect(item.freshnessStatus, anyOf(
        FreshnessStatus.expired,
        FreshnessStatus.expiringSoon,
      ));
    });

    test('PantryItem expiry far in the future', () {
      final item = PantryItem(
        id: 'p1', name: 'Long Life', category: PantryCategory.canned,
        quantity: 1, unit: 'can',
        expiryDate: DateTime.now().add(const Duration(days: 365 * 5)),
      );
      expect(item.freshnessStatus, FreshnessStatus.fresh);
      expect(item.daysUntilExpiry, greaterThan(1000));
    });

    test('PantryItem expiry far in the past', () {
      final item = PantryItem(
        id: 'p1', name: 'Ancient', category: PantryCategory.canned,
        quantity: 1, unit: 'can',
        expiryDate: DateTime(2020, 1, 1),
      );
      expect(item.freshnessStatus, FreshnessStatus.expired);
      expect(item.daysUntilExpiry, lessThan(-1000));
    });

    test('ChallengeModel with same start and end date', () {
      final now = DateTime.now();
      final challenge = ChallengeModel(
        id: 'ch', title: 'Flash Challenge', description: 'One day only',
        startDate: now.subtract(const Duration(hours: 1)),
        endDate: now.add(const Duration(hours: 1)),
      );
      expect(challenge.isOngoing, true);
    });

    test('WeekPlan with leap year date', () {
      final leapDay = DateTime(2024, 2, 29);
      final plan = WeekPlan(
        id: 'wp', weekStart: leapDay,
        days: [DayPlan(date: leapDay)],
      );
      final json = plan.toJson();
      final restored = WeekPlan.fromJson(json);
      expect(restored.weekStart.month, 2);
      expect(restored.weekStart.day, 29);
    });
  });

  group('Edge Cases - copyWith preserves all fields', () {
    test('PlannedMeal copyWith with no changes returns equivalent', () {
      const original = PlannedMeal(
        id: 'x', title: 'X', slot: MealSlot.breakfast,
        servings: 4, estimatedCalories: 300, isCooked: true,
      );
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.title, original.title);
      expect(copy.slot, original.slot);
      expect(copy.servings, original.servings);
      expect(copy.estimatedCalories, original.estimatedCalories);
      expect(copy.isCooked, original.isCooked);
    });

    test('GroceryItem copyWith with no changes returns equivalent', () {
      const original = GroceryItem(
        id: 'x', name: 'X', amount: '1', unit: 'pcs',
        status: GroceryItemStatus.inCart, isCustom: true,
      );
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.status, original.status);
      expect(copy.isCustom, original.isCustom);
    });

    test('PantryItem copyWith with no changes returns equivalent', () {
      const original = PantryItem(
        id: 'x', name: 'X', category: PantryCategory.dairy,
        quantity: 5, unit: 'L', isStaple: true,
      );
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.category, original.category);
      expect(copy.quantity, original.quantity);
      expect(copy.isStaple, original.isStaple);
    });

    test('RecipeCollection copyWith with no changes returns equivalent', () {
      final original = RecipeCollection(
        id: 'x', name: 'X', authorId: 'a',
        createdAt: DateTime(2025, 1, 1),
        recipeIds: ['r1'], isPublic: true, followersCount: 10,
      );
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.recipeIds, original.recipeIds);
      expect(copy.isPublic, original.isPublic);
      expect(copy.followersCount, original.followersCount);
    });

    test('MaterialLot copyWith with no changes returns equivalent', () {
      const original = MaterialLot(
        id: 'x', ingredientId: 'a', name: 'A',
        emoji: '🅰️', amount: '1', unit: 'pcs', state: 'raw', assetKey: 'a_raw',
      );
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.ingredientId, original.ingredientId);
      expect(copy.state, original.state);
    });

    test('UserModel copyWith with no changes returns equivalent', () {
      final original = UserModel(
        id: 'u', email: 'a@b.com', displayName: 'A',
        isVip: true, recipesCount: 5,
        createdAt: DateTime(2025, 1, 1), lastActiveAt: DateTime(2025, 6, 1),
      );
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.email, original.email);
      expect(copy.isVip, original.isVip);
      expect(copy.recipesCount, original.recipesCount);
    });
  });

  group('Edge Cases - Special Characters', () {
    test('PlannedMeal with Unicode title', () {
      const meal = PlannedMeal(
        id: 'm', title: '🍕 Pizza Napoletana 日本料理', slot: MealSlot.dinner,
      );
      final restored = PlannedMeal.fromJson(meal.toJson());
      expect(restored.title, '🍕 Pizza Napoletana 日本料理');
    });

    test('PantryItem with special characters in name', () {
      const item = PantryItem(
        id: 'p', name: "Häagen-Dazs® Ice Cream",
        category: PantryCategory.frozen, quantity: 1, unit: 'tub',
      );
      final restored = PantryItem.fromJson(item.toJson());
      expect(restored.name, "Häagen-Dazs® Ice Cream");
    });

    test('GroceryItem with empty name', () {
      const item = GroceryItem(id: 'g', name: '', amount: '0', unit: '');
      final restored = GroceryItem.fromJson(item.toJson());
      expect(restored.name, '');
    });

    test('RecipeCollection with very long name', () {
      final longName = 'A' * 1000;
      final col = RecipeCollection(
        id: 'c', name: longName, authorId: 'a',
        createdAt: DateTime(2025, 1, 1),
      );
      final restored = RecipeCollection.fromJson(col.toJson());
      expect(restored.name.length, 1000);
    });
  });

  group('Edge Cases - Type Coercion in fromJson', () {
    test('NutritionInfo fromJson with int values', () {
      final info = NutritionInfo.fromJson({
        'calories': 500, 'protein': 30, 'carbs': 60, 'fat': 15,
      });
      expect(info.calories, 500.0);
      expect(info.protein, 30.0);
    });

    test('NutritionInfo fromJson with double values', () {
      final info = NutritionInfo.fromJson({
        'calories': 500.5, 'protein': 30.3, 'carbs': 60.7, 'fat': 15.1,
      });
      expect(info.calories, 500.5);
      expect(info.protein, 30.3);
    });

    test('PantryItem fromJson quantity as int', () {
      final item = PantryItem.fromJson({
        'id': 'p', 'name': 'X', 'category': 'dairy',
        'quantity': 5, 'unit': 'pcs',
      });
      expect(item.quantity, 5.0);
    });

    test('PantryItem fromJson quantity as double', () {
      final item = PantryItem.fromJson({
        'id': 'p', 'name': 'X', 'category': 'dairy',
        'quantity': 2.5, 'unit': 'L',
      });
      expect(item.quantity, 2.5);
    });

    test('ForumPostModel.fromApiJson with string numeric likes', () {
      final post = ForumPostModel.fromApiJson({
        'id': '1', 'likes': '42', 'views': '100',
        'comments_count': '5', 'created_at': '2025-01-01T00:00:00Z',
      });
      expect(post.likes, 42);
      expect(post.views, 100);
      expect(post.commentsCount, 5);
    });

    test('ForumPostModel.fromApiJson with non-numeric likes defaults to 0', () {
      final post = ForumPostModel.fromApiJson({
        'id': '1', 'likes': 'not_a_number',
        'created_at': '2025-01-01T00:00:00Z',
      });
      expect(post.likes, 0);
    });
  });

  group('Edge Cases - Collection operations', () {
    test('RecipeCollection with empty recipeIds', () {
      final col = RecipeCollection(
        id: 'c', name: 'Empty', authorId: 'a',
        createdAt: DateTime(2025, 1, 1), recipeIds: [],
      );
      expect(col.recipeIds, isEmpty);
      final restored = RecipeCollection.fromJson(col.toJson());
      expect(restored.recipeIds, isEmpty);
    });

    test('RecipeCollection with many recipe IDs', () {
      final ids = List.generate(100, (i) => 'recipe-$i');
      final col = RecipeCollection(
        id: 'c', name: 'Big', authorId: 'a',
        createdAt: DateTime(2025, 1, 1), recipeIds: ids,
      );
      final restored = RecipeCollection.fromJson(col.toJson());
      expect(restored.recipeIds.length, 100);
    });
  });
}
