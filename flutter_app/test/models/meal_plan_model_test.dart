import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_diary/models/meal_plan_model.dart';

void main() {
  group('MealSlot', () {
    test('has correct number of values', () {
      expect(MealSlot.values.length, 6);
    });

    test('labels are correctly assigned', () {
      expect(MealSlot.breakfast.label, 'Breakfast');
      expect(MealSlot.morningSnack.label, 'Morning Snack');
      expect(MealSlot.lunch.label, 'Lunch');
      expect(MealSlot.afternoonSnack.label, 'Afternoon Snack');
      expect(MealSlot.dinner.label, 'Dinner');
      expect(MealSlot.eveningSnack.label, 'Evening Snack');
    });

    test('emojis are correctly assigned', () {
      expect(MealSlot.breakfast.emoji, '🌅');
      expect(MealSlot.morningSnack.emoji, '🍎');
      expect(MealSlot.lunch.emoji, '☀️');
      expect(MealSlot.afternoonSnack.emoji, '🍪');
      expect(MealSlot.dinner.emoji, '🌙');
      expect(MealSlot.eveningSnack.emoji, '🫖');
    });
  });

  group('PlannedMeal', () {
    test('creation with required fields only', () {
      const meal = PlannedMeal(
        id: 'meal-1',
        title: 'Omelette',
        slot: MealSlot.breakfast,
      );
      expect(meal.id, 'meal-1');
      expect(meal.title, 'Omelette');
      expect(meal.slot, MealSlot.breakfast);
      expect(meal.servings, 2);
      expect(meal.estimatedCalories, 0);
      expect(meal.prepTimeMinutes, 0);
      expect(meal.isCooked, false);
      expect(meal.recipeId, isNull);
      expect(meal.imageUrl, isNull);
      expect(meal.notes, isNull);
    });

    test('creation with all fields', () {
      const meal = PlannedMeal(
        id: 'meal-2',
        recipeId: 'recipe-123',
        title: 'Grilled Chicken',
        imageUrl: 'https://example.com/img.jpg',
        slot: MealSlot.dinner,
        servings: 4,
        estimatedCalories: 500,
        prepTimeMinutes: 45,
        notes: 'Extra spicy',
        isCooked: true,
      );
      expect(meal.recipeId, 'recipe-123');
      expect(meal.imageUrl, 'https://example.com/img.jpg');
      expect(meal.servings, 4);
      expect(meal.estimatedCalories, 500);
      expect(meal.prepTimeMinutes, 45);
      expect(meal.notes, 'Extra spicy');
      expect(meal.isCooked, true);
    });

    test('copyWith preserves unchanged values', () {
      const meal = PlannedMeal(
        id: 'meal-1',
        title: 'Omelette',
        slot: MealSlot.breakfast,
        servings: 2,
      );
      final updated = meal.copyWith(title: 'Scrambled Eggs');
      expect(updated.id, 'meal-1');
      expect(updated.title, 'Scrambled Eggs');
      expect(updated.slot, MealSlot.breakfast);
      expect(updated.servings, 2);
    });

    test('copyWith changes isCooked', () {
      const meal = PlannedMeal(
        id: 'meal-1',
        title: 'Pasta',
        slot: MealSlot.dinner,
        isCooked: false,
      );
      final cooked = meal.copyWith(isCooked: true);
      expect(cooked.isCooked, true);
      expect(cooked.title, 'Pasta');
    });

    test('toJson produces correct map', () {
      const meal = PlannedMeal(
        id: 'meal-1',
        recipeId: 'r1',
        title: 'Soup',
        slot: MealSlot.lunch,
        servings: 3,
        estimatedCalories: 350,
        prepTimeMinutes: 20,
        isCooked: true,
      );
      final json = meal.toJson();
      expect(json['id'], 'meal-1');
      expect(json['recipeId'], 'r1');
      expect(json['title'], 'Soup');
      expect(json['slot'], 'lunch');
      expect(json['servings'], 3);
      expect(json['estimatedCalories'], 350);
      expect(json['prepTimeMinutes'], 20);
      expect(json['isCooked'], true);
    });

    test('fromJson creates correct object', () {
      final json = {
        'id': 'meal-2',
        'recipeId': null,
        'title': 'Salad',
        'imageUrl': null,
        'slot': 'dinner',
        'servings': 1,
        'estimatedCalories': 200,
        'prepTimeMinutes': 10,
        'notes': 'Low carb',
        'isCooked': false,
      };
      final meal = PlannedMeal.fromJson(json);
      expect(meal.id, 'meal-2');
      expect(meal.title, 'Salad');
      expect(meal.slot, MealSlot.dinner);
      expect(meal.servings, 1);
      expect(meal.notes, 'Low carb');
    });

    test('fromJson with missing optional fields uses defaults', () {
      final json = {
        'id': 'meal-3',
        'title': 'Toast',
        'slot': 'breakfast',
      };
      final meal = PlannedMeal.fromJson(json);
      expect(meal.servings, 2);
      expect(meal.estimatedCalories, 0);
      expect(meal.prepTimeMinutes, 0);
      expect(meal.isCooked, false);
    });

    test('fromJson with invalid slot falls back to lunch', () {
      final json = {
        'id': 'meal-4',
        'title': 'Mystery Meal',
        'slot': 'invalid_slot',
      };
      final meal = PlannedMeal.fromJson(json);
      expect(meal.slot, MealSlot.lunch);
    });

    test('toJson/fromJson roundtrip', () {
      const original = PlannedMeal(
        id: 'rt-1',
        recipeId: 'recipe-x',
        title: 'Steak',
        slot: MealSlot.dinner,
        servings: 2,
        estimatedCalories: 800,
        prepTimeMinutes: 30,
        notes: 'Medium rare',
        isCooked: true,
      );
      final restored = PlannedMeal.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.recipeId, original.recipeId);
      expect(restored.title, original.title);
      expect(restored.slot, original.slot);
      expect(restored.servings, original.servings);
      expect(restored.estimatedCalories, original.estimatedCalories);
      expect(restored.prepTimeMinutes, original.prepTimeMinutes);
      expect(restored.notes, original.notes);
      expect(restored.isCooked, original.isCooked);
    });
  });

  group('DayPlan', () {
    final today = DateTime(2025, 6, 15);

    test('creation with empty meals', () {
      final plan = DayPlan(date: today);
      expect(plan.meals, isEmpty);
      expect(plan.totalCalories, 0);
      expect(plan.totalPrepTime, 0);
      expect(plan.cookedCount, 0);
    });

    test('totalCalories sums correctly', () {
      final plan = DayPlan(
        date: today,
        meals: const [
          PlannedMeal(id: '1', title: 'A', slot: MealSlot.breakfast, estimatedCalories: 300),
          PlannedMeal(id: '2', title: 'B', slot: MealSlot.lunch, estimatedCalories: 500),
          PlannedMeal(id: '3', title: 'C', slot: MealSlot.dinner, estimatedCalories: 700),
        ],
      );
      expect(plan.totalCalories, 1500);
    });

    test('totalPrepTime sums correctly', () {
      final plan = DayPlan(
        date: today,
        meals: const [
          PlannedMeal(id: '1', title: 'A', slot: MealSlot.breakfast, prepTimeMinutes: 10),
          PlannedMeal(id: '2', title: 'B', slot: MealSlot.lunch, prepTimeMinutes: 30),
        ],
      );
      expect(plan.totalPrepTime, 40);
    });

    test('cookedCount counts only cooked meals', () {
      final plan = DayPlan(
        date: today,
        meals: const [
          PlannedMeal(id: '1', title: 'A', slot: MealSlot.breakfast, isCooked: true),
          PlannedMeal(id: '2', title: 'B', slot: MealSlot.lunch, isCooked: false),
          PlannedMeal(id: '3', title: 'C', slot: MealSlot.dinner, isCooked: true),
        ],
      );
      expect(plan.cookedCount, 2);
    });

    test('toJson/fromJson roundtrip', () {
      final plan = DayPlan(
        date: today,
        meals: const [
          PlannedMeal(id: '1', title: 'Eggs', slot: MealSlot.breakfast),
        ],
      );
      final restored = DayPlan.fromJson(plan.toJson());
      expect(restored.date, today);
      expect(restored.meals.length, 1);
      expect(restored.meals.first.title, 'Eggs');
    });
  });

  group('WeekPlan', () {
    test('creation and serialization', () {
      final start = DateTime(2025, 6, 9);
      final plan = WeekPlan(
        id: 'wp-1',
        weekStart: start,
        days: [DayPlan(date: start)],
        theme: 'Italian Week',
      );
      expect(plan.id, 'wp-1');
      expect(plan.theme, 'Italian Week');

      final json = plan.toJson();
      expect(json['id'], 'wp-1');
      expect(json['theme'], 'Italian Week');
    });

    test('toJson/fromJson roundtrip', () {
      final start = DateTime(2025, 6, 9);
      final original = WeekPlan(
        id: 'wp-2',
        weekStart: start,
        days: List.generate(7, (i) => DayPlan(date: start.add(Duration(days: i)))),
      );
      final restored = WeekPlan.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.days.length, 7);
      expect(restored.theme, isNull);
    });
  });

  group('GroceryItemStatus', () {
    test('has correct values', () {
      expect(GroceryItemStatus.values.length, 3);
      expect(GroceryItemStatus.needed.name, 'needed');
      expect(GroceryItemStatus.inCart.name, 'inCart');
      expect(GroceryItemStatus.purchased.name, 'purchased');
    });
  });

  group('GroceryItem', () {
    test('creation with defaults', () {
      const item = GroceryItem(
        id: 'gi-1',
        name: 'Tomatoes',
        amount: '4',
        unit: 'pcs',
      );
      expect(item.status, GroceryItemStatus.needed);
      expect(item.fromRecipes, isEmpty);
      expect(item.isCustom, false);
      expect(item.emoji, isNull);
      expect(item.category, isNull);
      expect(item.aisle, isNull);
    });

    test('copyWith changes status', () {
      const item = GroceryItem(id: 'gi-1', name: 'Eggs', amount: '12', unit: 'pcs');
      final updated = item.copyWith(status: GroceryItemStatus.inCart);
      expect(updated.status, GroceryItemStatus.inCart);
      expect(updated.name, 'Eggs');
    });

    test('toJson/fromJson roundtrip', () {
      const original = GroceryItem(
        id: 'gi-2',
        name: 'Milk',
        emoji: '🥛',
        amount: '1',
        unit: 'L',
        category: 'dairy',
        status: GroceryItemStatus.purchased,
        fromRecipes: ['recipe-1'],
        isCustom: true,
      );
      final restored = GroceryItem.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.emoji, original.emoji);
      expect(restored.status, original.status);
      expect(restored.fromRecipes, original.fromRecipes);
      expect(restored.isCustom, original.isCustom);
    });

    test('fromJson with invalid status uses default', () {
      final json = {
        'id': 'gi-3',
        'name': 'Sugar',
        'amount': '1',
        'unit': 'kg',
        'status': 'unknown_status',
      };
      final item = GroceryItem.fromJson(json);
      expect(item.status, GroceryItemStatus.needed);
    });

    test('fromJson with missing amount defaults to empty string', () {
      final json = {
        'id': 'gi-4',
        'name': 'Salt',
        'unit': 'tsp',
      };
      final item = GroceryItem.fromJson(json);
      expect(item.amount, '');
    });
  });

  group('GroceryList', () {
    test('empty list has correct progress', () {
      final list = GroceryList(
        id: 'gl-1',
        name: 'Weekly',
        createdAt: DateTime(2025, 1, 1),
      );
      expect(list.items, isEmpty);
      expect(list.progress, 0);
      expect(list.neededCount, 0);
      expect(list.inCartCount, 0);
      expect(list.purchasedCount, 0);
    });

    test('counts by status are correct', () {
      final list = GroceryList(
        id: 'gl-2',
        name: 'Shop',
        createdAt: DateTime(2025, 1, 1),
        items: const [
          GroceryItem(id: '1', name: 'A', amount: '1', unit: 'pcs', status: GroceryItemStatus.needed),
          GroceryItem(id: '2', name: 'B', amount: '1', unit: 'pcs', status: GroceryItemStatus.inCart),
          GroceryItem(id: '3', name: 'C', amount: '1', unit: 'pcs', status: GroceryItemStatus.purchased),
          GroceryItem(id: '4', name: 'D', amount: '1', unit: 'pcs', status: GroceryItemStatus.purchased),
        ],
      );
      expect(list.neededCount, 1);
      expect(list.inCartCount, 1);
      expect(list.purchasedCount, 2);
      expect(list.progress, 0.5);
    });

    test('toJson/fromJson roundtrip', () {
      final original = GroceryList(
        id: 'gl-3',
        name: 'Test List',
        createdAt: DateTime(2025, 3, 15),
        items: const [
          GroceryItem(id: '1', name: 'Butter', amount: '200', unit: 'g'),
        ],
      );
      final restored = GroceryList.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.items.length, 1);
      expect(restored.items.first.name, 'Butter');
    });
  });
}
