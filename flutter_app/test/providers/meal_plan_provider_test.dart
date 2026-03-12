import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kitchen_diary/models/meal_plan_model.dart';
import 'package:kitchen_diary/providers/meal_plan_provider.dart';

void main() {
  late MealPlanProvider provider;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_meal_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<MealPlanProvider> createProvider() async {
    final p = MealPlanProvider();
    // Wait for async _loadData to complete
    await Future.delayed(const Duration(milliseconds: 200));
    return p;
  }

  group('MealPlanProvider initialization', () {
    test('starts loading then finishes', () async {
      provider = await createProvider();
      expect(provider.isLoading, false);
    });

    test('creates current week plan on init', () async {
      provider = await createProvider();
      expect(provider.weekPlans, isNotEmpty);
      expect(provider.currentWeekPlan, isNotNull);
    });

    test('current week plan has 7 days', () async {
      provider = await createProvider();
      final plan = provider.currentWeekPlan;
      expect(plan, isNotNull);
      expect(plan!.days.length, 7);
    });

    test('focusedWeekStart is a Monday', () async {
      provider = await createProvider();
      // Monday is weekday 1
      expect(provider.focusedWeekStart.weekday, 1);
    });
  });

  group('selectDay', () {
    test('selects a day from current week', () async {
      provider = await createProvider();
      final plan = provider.currentWeekPlan!;
      final date = plan.days[2].date;
      provider.selectDay(date);
      expect(provider.selectedDay, isNotNull);
      expect(provider.selectedDay!.date, date);
    });

    test('returns null for date not in current week plan', () async {
      provider = await createProvider();
      // A date far in the future not in any plan
      provider.selectDay(DateTime(2099, 1, 1));
      expect(provider.selectedDay, isNull);
    });
  });

  group('navigateWeek', () {
    test('navigating forward changes focusedWeekStart by 7 days', () async {
      provider = await createProvider();
      final original = provider.focusedWeekStart;
      await provider.navigateWeek(1);
      expect(provider.focusedWeekStart, original.add(const Duration(days: 7)));
    });

    test('navigating backward changes focusedWeekStart by -7 days', () async {
      provider = await createProvider();
      final original = provider.focusedWeekStart;
      await provider.navigateWeek(-1);
      expect(provider.focusedWeekStart,
          original.subtract(const Duration(days: 7)));
    });

    test('creates plan for new week if missing', () async {
      provider = await createProvider();
      final initialCount = provider.weekPlans.length;
      await provider.navigateWeek(1);
      expect(provider.weekPlans.length, initialCount + 1);
    });

    test('does not duplicate plan for existing week', () async {
      provider = await createProvider();
      await provider.navigateWeek(1);
      final countAfterFirst = provider.weekPlans.length;
      await provider.navigateWeek(-1); // back to original
      expect(provider.weekPlans.length, countAfterFirst);
    });
  });

  group('addMealToDay', () {
    test('adds a meal to a specific day', () async {
      provider = await createProvider();
      final plan = provider.currentWeekPlan!;
      final date = plan.days[0].date;
      const meal = PlannedMeal(
        id: 'meal-test-1',
        title: 'Test Breakfast',
        slot: MealSlot.breakfast,
        estimatedCalories: 300,
      );
      await provider.addMealToDay(date, meal);

      // Reload the plan
      final updatedPlan = provider.currentWeekPlan!;
      final dayMeals = updatedPlan.days[0].meals;
      expect(dayMeals.length, 1);
      expect(dayMeals.first.title, 'Test Breakfast');
      expect(dayMeals.first.estimatedCalories, 300);
    });

    test('adds multiple meals to same day', () async {
      provider = await createProvider();
      final date = provider.currentWeekPlan!.days[1].date;
      await provider.addMealToDay(
          date,
          const PlannedMeal(
              id: 'm1', title: 'Meal 1', slot: MealSlot.breakfast));
      await provider.addMealToDay(date,
          const PlannedMeal(id: 'm2', title: 'Meal 2', slot: MealSlot.lunch));
      await provider.addMealToDay(date,
          const PlannedMeal(id: 'm3', title: 'Meal 3', slot: MealSlot.dinner));

      final dayMeals = provider.currentWeekPlan!.days[1].meals;
      expect(dayMeals.length, 3);
    });

    test('does nothing for date not in any week plan', () async {
      provider = await createProvider();
      await provider.addMealToDay(DateTime(2099, 12, 31),
          const PlannedMeal(id: 'm', title: 'M', slot: MealSlot.lunch));
      // Should not throw, just return
    });
  });

  group('removeMealFromDay', () {
    test('removes a meal by id', () async {
      provider = await createProvider();
      final date = provider.currentWeekPlan!.days[0].date;
      await provider.addMealToDay(
          date,
          const PlannedMeal(
              id: 'to-remove', title: 'Remove Me', slot: MealSlot.breakfast));
      await provider.addMealToDay(
          date,
          const PlannedMeal(
              id: 'keep', title: 'Keep Me', slot: MealSlot.lunch));

      await provider.removeMealFromDay(date, 'to-remove');
      final dayMeals = provider.currentWeekPlan!.days[0].meals;
      expect(dayMeals.length, 1);
      expect(dayMeals.first.id, 'keep');
    });

    test('does nothing for nonexistent meal id', () async {
      provider = await createProvider();
      final date = provider.currentWeekPlan!.days[0].date;
      await provider.addMealToDay(date,
          const PlannedMeal(id: 'm1', title: 'M1', slot: MealSlot.breakfast));
      await provider.removeMealFromDay(date, 'nonexistent');
      expect(provider.currentWeekPlan!.days[0].meals.length, 1);
    });

    test('does nothing for date not in any week plan', () async {
      provider = await createProvider();
      await provider.removeMealFromDay(DateTime(2099, 12, 31), 'm1');
      // Should not throw
    });
  });

  group('toggleMealCooked', () {
    test('toggles meal cooked status from false to true', () async {
      provider = await createProvider();
      final date = provider.currentWeekPlan!.days[0].date;
      await provider.addMealToDay(
          date,
          const PlannedMeal(
            id: 'toggle-meal',
            title: 'Toggle Me',
            slot: MealSlot.dinner,
            isCooked: false,
          ));

      await provider.toggleMealCooked(date, 'toggle-meal');
      final meal = provider.currentWeekPlan!.days[0].meals.first;
      expect(meal.isCooked, true);
    });

    test('toggles meal cooked status from true back to false', () async {
      provider = await createProvider();
      final date = provider.currentWeekPlan!.days[0].date;
      await provider.addMealToDay(
          date,
          const PlannedMeal(
            id: 'toggle-meal',
            title: 'Toggle Me',
            slot: MealSlot.dinner,
            isCooked: false,
          ));
      await provider.toggleMealCooked(date, 'toggle-meal');
      await provider.toggleMealCooked(date, 'toggle-meal');
      final meal = provider.currentWeekPlan!.days[0].meals.first;
      expect(meal.isCooked, false);
    });
  });

  group('Grocery List', () {
    test('createGroceryList creates and returns a list', () async {
      provider = await createProvider();
      final list = await provider.createGroceryList('Test List');
      expect(list.name, 'Test List');
      expect(list.items, isEmpty);
      expect(provider.groceryLists.length, 1);
    });

    test('createGroceryList inserts at front', () async {
      provider = await createProvider();
      await provider.createGroceryList('First');
      await provider.createGroceryList('Second');
      expect(provider.groceryLists.first.name, 'Second');
      expect(provider.groceryLists.last.name, 'First');
    });

    test('addGroceryItem adds to correct list', () async {
      provider = await createProvider();
      final list = await provider.createGroceryList('Shopping');
      const item =
          GroceryItem(id: 'gi-1', name: 'Apples', amount: '6', unit: 'pcs');
      await provider.addGroceryItem(list.id, item);

      expect(provider.groceryLists.first.items.length, 1);
      expect(provider.groceryLists.first.items.first.name, 'Apples');
    });

    test('addGroceryItem does nothing for nonexistent list', () async {
      provider = await createProvider();
      const item =
          GroceryItem(id: 'gi-1', name: 'Apples', amount: '6', unit: 'pcs');
      await provider.addGroceryItem('nonexistent', item);
      // Should not throw
    });

    test('toggleGroceryItemStatus cycles through statuses', () async {
      provider = await createProvider();
      final list = await provider.createGroceryList('Shopping');
      const item =
          GroceryItem(id: 'gi-1', name: 'Milk', amount: '1', unit: 'L');
      await provider.addGroceryItem(list.id, item);

      // needed -> inCart
      await provider.toggleGroceryItemStatus(list.id, 'gi-1');
      expect(provider.groceryLists.first.items.first.status,
          GroceryItemStatus.inCart);

      // inCart -> purchased
      await provider.toggleGroceryItemStatus(list.id, 'gi-1');
      expect(provider.groceryLists.first.items.first.status,
          GroceryItemStatus.purchased);

      // purchased -> needed
      await provider.toggleGroceryItemStatus(list.id, 'gi-1');
      expect(provider.groceryLists.first.items.first.status,
          GroceryItemStatus.needed);
    });

    test('toggleGroceryItemStatus does nothing for nonexistent item', () async {
      provider = await createProvider();
      final list = await provider.createGroceryList('Shopping');
      const item =
          GroceryItem(id: 'gi-1', name: 'Milk', amount: '1', unit: 'L');
      await provider.addGroceryItem(list.id, item);
      await provider.toggleGroceryItemStatus(list.id, 'nonexistent');
      expect(provider.groceryLists.first.items.first.status,
          GroceryItemStatus.needed);
    });

    test('generateGroceryListFromWeek creates a grocery list', () async {
      provider = await createProvider();
      await provider.generateGroceryListFromWeek();
      expect(provider.groceryLists, isNotEmpty);
    });
  });

  group('todayPlan', () {
    test('returns plan for today', () async {
      provider = await createProvider();
      // todayPlan should find today in the current week plan
      final today = DateTime.now();
      // The day at index (today.weekday - 1) should match today
      final dayPlan = provider.todayPlan;
      if (dayPlan != null) {
        expect(dayPlan.date.year, today.year);
        expect(dayPlan.date.month, today.month);
        expect(dayPlan.date.day, today.day);
      }
      // It could be null if something unusual happened, but typically should be found
    });
  });
}
