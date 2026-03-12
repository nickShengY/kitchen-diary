import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/meal_plan_model.dart';

class MealPlanProvider extends ChangeNotifier {
  static const String _boxName = 'meal_plan_data';
  static const String _weekPlanKey = 'week_plans';
  static const String _groceryListKey = 'grocery_lists';

  List<WeekPlan> _weekPlans = [];
  List<GroceryList> _groceryLists = [];
  DayPlan? _selectedDay;
  DateTime _focusedWeekStart = _getWeekStart(DateTime.now());
  bool _isLoading = true;

  List<WeekPlan> get weekPlans => _weekPlans;
  List<GroceryList> get groceryLists => _groceryLists;
  DayPlan? get selectedDay => _selectedDay;
  DateTime get focusedWeekStart => _focusedWeekStart;
  bool get isLoading => _isLoading;

  WeekPlan? get currentWeekPlan {
    final start = _getWeekStart(DateTime.now());
    return _weekPlans.cast<WeekPlan?>().firstWhere(
          (p) => p!.weekStart.isAtSameMomentAs(start),
          orElse: () => null,
        );
  }

  DayPlan? get todayPlan {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return currentWeekPlan?.days.cast<DayPlan?>().firstWhere(
          (d) => d!.date.isAtSameMomentAs(today),
          orElse: () => null,
        );
  }

  MealPlanProvider() {
    _loadData();
  }

  static DateTime _getWeekStart(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  Future<void> _loadData() async {
    _isLoading = true;
    try {
      final box = await Hive.openBox(_boxName);

      final plansJson = box.get(_weekPlanKey);
      if (plansJson != null) {
        final List<dynamic> decoded = jsonDecode(plansJson);
        _weekPlans = decoded.map((e) => WeekPlan.fromJson(e)).toList();
      }

      final listsJson = box.get(_groceryListKey);
      if (listsJson != null) {
        final List<dynamic> decoded = jsonDecode(listsJson);
        _groceryLists = decoded.map((e) => GroceryList.fromJson(e)).toList();
      }

      // Ensure current week plan exists
      if (currentWeekPlan == null) {
        await _createWeekPlan(_focusedWeekStart);
      }
    } catch (e) {
      debugPrint('Error loading meal plan data: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(
          _weekPlanKey, jsonEncode(_weekPlans.map((e) => e.toJson()).toList()));
      await box.put(_groceryListKey,
          jsonEncode(_groceryLists.map((e) => e.toJson()).toList()));
    } catch (e) {
      debugPrint('Error saving meal plan data: $e');
    }
  }

  Future<void> _createWeekPlan(DateTime weekStart) async {
    final days = List.generate(7, (i) {
      return DayPlan(date: weekStart.add(Duration(days: i)), meals: []);
    });
    final plan = WeekPlan(
      id: const Uuid().v4(),
      weekStart: weekStart,
      days: days,
    );
    _weekPlans.add(plan);
    await _save();
    notifyListeners();
  }

  void selectDay(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    _selectedDay = currentWeekPlan?.days.cast<DayPlan?>().firstWhere(
          (day) => day!.date.isAtSameMomentAs(d),
          orElse: () => null,
        );
    notifyListeners();
  }

  Future<void> navigateWeek(int direction) async {
    _focusedWeekStart = _focusedWeekStart.add(Duration(days: 7 * direction));
    final existing = _weekPlans.cast<WeekPlan?>().firstWhere(
          (p) => p!.weekStart.isAtSameMomentAs(_focusedWeekStart),
          orElse: () => null,
        );
    if (existing == null) {
      await _createWeekPlan(_focusedWeekStart);
    }
    notifyListeners();
  }

  Future<void> addMealToDay(DateTime date, PlannedMeal meal) async {
    final d = DateTime(date.year, date.month, date.day);
    final weekStart = _getWeekStart(d);

    final planIndex =
        _weekPlans.indexWhere((p) => p.weekStart.isAtSameMomentAs(weekStart));
    if (planIndex == -1) return;

    final plan = _weekPlans[planIndex];
    final dayIndex =
        plan.days.indexWhere((day) => day.date.isAtSameMomentAs(d));
    if (dayIndex == -1) return;

    final updatedMeals = [...plan.days[dayIndex].meals, meal];
    final updatedDay = DayPlan(date: d, meals: updatedMeals);
    final updatedDays = [...plan.days];
    updatedDays[dayIndex] = updatedDay;

    _weekPlans[planIndex] = WeekPlan(
      id: plan.id,
      weekStart: plan.weekStart,
      days: updatedDays,
      theme: plan.theme,
    );

    await _save();
    notifyListeners();
  }

  Future<void> removeMealFromDay(DateTime date, String mealId) async {
    final d = DateTime(date.year, date.month, date.day);
    final weekStart = _getWeekStart(d);

    final planIndex =
        _weekPlans.indexWhere((p) => p.weekStart.isAtSameMomentAs(weekStart));
    if (planIndex == -1) return;

    final plan = _weekPlans[planIndex];
    final dayIndex =
        plan.days.indexWhere((day) => day.date.isAtSameMomentAs(d));
    if (dayIndex == -1) return;

    final updatedMeals =
        plan.days[dayIndex].meals.where((m) => m.id != mealId).toList();
    final updatedDay = DayPlan(date: d, meals: updatedMeals);
    final updatedDays = [...plan.days];
    updatedDays[dayIndex] = updatedDay;

    _weekPlans[planIndex] = WeekPlan(
      id: plan.id,
      weekStart: plan.weekStart,
      days: updatedDays,
      theme: plan.theme,
    );

    await _save();
    notifyListeners();
  }

  Future<void> toggleMealCooked(DateTime date, String mealId) async {
    final d = DateTime(date.year, date.month, date.day);
    final weekStart = _getWeekStart(d);

    final planIndex =
        _weekPlans.indexWhere((p) => p.weekStart.isAtSameMomentAs(weekStart));
    if (planIndex == -1) return;

    final plan = _weekPlans[planIndex];
    final dayIndex =
        plan.days.indexWhere((day) => day.date.isAtSameMomentAs(d));
    if (dayIndex == -1) return;

    final updatedMeals = plan.days[dayIndex].meals.map((m) {
      if (m.id == mealId) return m.copyWith(isCooked: !m.isCooked);
      return m;
    }).toList();

    final updatedDay = DayPlan(date: d, meals: updatedMeals);
    final updatedDays = [...plan.days];
    updatedDays[dayIndex] = updatedDay;

    _weekPlans[planIndex] = WeekPlan(
      id: plan.id,
      weekStart: plan.weekStart,
      days: updatedDays,
      theme: plan.theme,
    );

    await _save();
    notifyListeners();
  }

  // Grocery List methods
  Future<GroceryList> createGroceryList(String name) async {
    final list = GroceryList(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now(),
      items: [],
    );
    _groceryLists.insert(0, list);
    await _save();
    notifyListeners();
    return list;
  }

  Future<void> addGroceryItem(String listId, GroceryItem item) async {
    final idx = _groceryLists.indexWhere((l) => l.id == listId);
    if (idx == -1) return;

    final list = _groceryLists[idx];
    _groceryLists[idx] = GroceryList(
      id: list.id,
      name: list.name,
      createdAt: list.createdAt,
      items: [...list.items, item],
    );
    await _save();
    notifyListeners();
  }

  Future<void> toggleGroceryItemStatus(String listId, String itemId) async {
    final idx = _groceryLists.indexWhere((l) => l.id == listId);
    if (idx == -1) return;

    final list = _groceryLists[idx];
    final updatedItems = list.items.map((item) {
      if (item.id != itemId) return item;
      final nextStatus = switch (item.status) {
        GroceryItemStatus.needed => GroceryItemStatus.inCart,
        GroceryItemStatus.inCart => GroceryItemStatus.purchased,
        GroceryItemStatus.purchased => GroceryItemStatus.needed,
      };
      return item.copyWith(status: nextStatus);
    }).toList();

    _groceryLists[idx] = GroceryList(
      id: list.id,
      name: list.name,
      createdAt: list.createdAt,
      items: updatedItems,
    );
    await _save();
    notifyListeners();
  }

  Future<void> generateGroceryListFromWeek() async {
    final plan = currentWeekPlan;
    if (plan == null) return;

    // Create a grocery list aggregating from planned meals
    await createGroceryList(
        'Week of ${plan.weekStart.month}/${plan.weekStart.day}');
  }
}
