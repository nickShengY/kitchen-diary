import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/nutrition_model.dart';

class NutritionProvider extends ChangeNotifier {
  static const String _boxName = 'nutrition_data';
  static const String _goalsKey = 'nutrition_goals';
  static const String _logsKey = 'nutrition_logs';
  static const String _streakKey = 'cooking_streak';
  static const String _achievementsKey = 'achievements';
  static const String _collectionsKey = 'recipe_collections';
  static const String _waterKey = 'water_intake';

  NutritionGoal _goal = const NutritionGoal();
  List<DailyNutritionLog> _logs = [];
  CookingStreak _streak = const CookingStreak();
  List<Achievement> _achievements = [];
  List<RecipeCollection> _collections = [];
  double _todayWaterMl = 0;
  bool _isLoading = true;

  NutritionGoal get goal => _goal;
  List<DailyNutritionLog> get logs => _logs;
  CookingStreak get streak => _streak;
  List<Achievement> get achievements => _achievements;
  List<RecipeCollection> get collections => _collections;
  double get todayWaterMl => _todayWaterMl;
  bool get isLoading => _isLoading;

  DailyNutritionLog? get todayLog {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _logs.cast<DailyNutritionLog?>().firstWhere(
          (l) =>
              l!.date.year == today.year &&
              l.date.month == today.month &&
              l.date.day == today.day,
          orElse: () => null,
        );
  }

  double get calorieProgress {
    if (todayLog == null) return 0;
    return (todayLog!.totals.calories / _goal.targetCalories).clamp(0.0, 1.5);
  }

  double get proteinProgress {
    if (todayLog == null) return 0;
    return (todayLog!.totals.protein / _goal.targetProtein).clamp(0.0, 1.5);
  }

  double get carbsProgress {
    if (todayLog == null) return 0;
    return (todayLog!.totals.carbs / _goal.targetCarbs).clamp(0.0, 1.5);
  }

  double get fatProgress {
    if (todayLog == null) return 0;
    return (todayLog!.totals.fat / _goal.targetFat).clamp(0.0, 1.5);
  }

  double get waterProgress =>
      (_todayWaterMl / 2500).clamp(0.0, 1.5); // 2.5L daily target

  List<Achievement> get unlockedAchievements =>
      _achievements.where((a) => a.isUnlocked).toList();

  List<Achievement> get inProgressAchievements =>
      _achievements.where((a) => !a.isUnlocked && a.currentValue > 0).toList();

  NutritionProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    try {
      final box = await Hive.openBox(_boxName);

      final goalsJson = box.get(_goalsKey);
      if (goalsJson != null) {
        _goal = NutritionGoal.fromJson(jsonDecode(goalsJson));
      }

      final logsJson = box.get(_logsKey);
      if (logsJson != null) {
        final List<dynamic> decoded = jsonDecode(logsJson);
        _logs = decoded.map((e) => DailyNutritionLog.fromJson(e)).toList();
      }

      final streakJson = box.get(_streakKey);
      if (streakJson != null) {
        _streak = CookingStreak.fromJson(jsonDecode(streakJson));
      }

      final achJson = box.get(_achievementsKey);
      if (achJson != null) {
        final List<dynamic> decoded = jsonDecode(achJson);
        _achievements = decoded.map((e) => Achievement.fromJson(e)).toList();
      } else {
        _achievements = _getDefaultAchievements();
        await _save();
      }

      final colJson = box.get(_collectionsKey);
      if (colJson != null) {
        final List<dynamic> decoded = jsonDecode(colJson);
        _collections =
            decoded.map((e) => RecipeCollection.fromJson(e)).toList();
      }

      final waterJson = box.get(_waterKey);
      if (waterJson != null) {
        _todayWaterMl = (jsonDecode(waterJson) as num).toDouble();
      }
    } catch (e) {
      debugPrint('Error loading nutrition data: $e');
      _achievements = _getDefaultAchievements();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_goalsKey, jsonEncode(_goal.toJson()));
      await box.put(
          _logsKey, jsonEncode(_logs.map((e) => e.toJson()).toList()));
      await box.put(_streakKey, jsonEncode(_streak.toJson()));
      await box.put(_achievementsKey,
          jsonEncode(_achievements.map((e) => e.toJson()).toList()));
      await box.put(_collectionsKey,
          jsonEncode(_collections.map((e) => e.toJson()).toList()));
      await box.put(_waterKey, jsonEncode(_todayWaterMl));
    } catch (e) {
      debugPrint('Error saving nutrition data: $e');
    }
  }

  Future<void> updateGoal(NutritionGoal goal) async {
    _goal = goal;
    await _save();
    notifyListeners();
  }

  Future<void> logMeal(NutritionInfo nutrition) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final idx = _logs.indexWhere((l) =>
        l.date.year == today.year &&
        l.date.month == today.month &&
        l.date.day == today.day);

    if (idx != -1) {
      final existing = _logs[idx];
      _logs[idx] = DailyNutritionLog(
        date: today,
        totals: existing.totals + nutrition,
        mealsLogged: existing.mealsLogged + 1,
        waterIntakeMl: existing.waterIntakeMl,
      );
    } else {
      _logs.add(DailyNutritionLog(
        date: today,
        totals: nutrition,
        mealsLogged: 1,
      ));
    }

    await _save();
    notifyListeners();
  }

  Future<void> addWater(double ml) async {
    _todayWaterMl += ml;
    await _save();
    notifyListeners();
  }

  Future<void> recordCook() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastCook = _streak.lastCookDate;

    int newStreak = _streak.currentStreak;
    if (lastCook == null) {
      newStreak = 1;
    } else {
      final lastDay = DateTime(lastCook.year, lastCook.month, lastCook.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 1) {
        newStreak++;
      } else if (diff > 1) {
        newStreak = 1;
      }
    }

    _streak = CookingStreak(
      currentStreak: newStreak,
      longestStreak:
          newStreak > _streak.longestStreak ? newStreak : _streak.longestStreak,
      lastCookDate: today,
      totalMealsCooked: _streak.totalMealsCooked + 1,
      totalRecipesCreated: _streak.totalRecipesCreated,
      cuisineBreakdown: _streak.cuisineBreakdown,
    );

    _checkAchievements();
    await _save();
    notifyListeners();
  }

  void _checkAchievements() {
    for (int i = 0; i < _achievements.length; i++) {
      final a = _achievements[i];
      if (a.isUnlocked) continue;

      int newVal = a.currentValue;
      switch (a.id) {
        case 'first_cook':
          newVal = _streak.totalMealsCooked;
          break;
        case 'streak_7':
          newVal = _streak.currentStreak;
          break;
        case 'streak_30':
          newVal = _streak.currentStreak;
          break;
        case 'meals_10':
          newVal = _streak.totalMealsCooked;
          break;
        case 'meals_50':
          newVal = _streak.totalMealsCooked;
          break;
        case 'meals_100':
          newVal = _streak.totalMealsCooked;
          break;
        case 'collections_3':
          newVal = _collections.length;
          break;
      }

      if (newVal >= a.requiredValue && !a.isUnlocked) {
        _achievements[i] = Achievement(
          id: a.id,
          title: a.title,
          description: a.description,
          emoji: a.emoji,
          category: a.category,
          requiredValue: a.requiredValue,
          currentValue: newVal,
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
      } else if (newVal != a.currentValue) {
        _achievements[i] = Achievement(
          id: a.id,
          title: a.title,
          description: a.description,
          emoji: a.emoji,
          category: a.category,
          requiredValue: a.requiredValue,
          currentValue: newVal,
          isUnlocked: false,
        );
      }
    }
  }

  // Collection management
  Future<void> addCollection(RecipeCollection collection) async {
    _collections.add(collection);
    _checkAchievements();
    await _save();
    notifyListeners();
  }

  Future<void> addRecipeToCollection(
      String collectionId, String recipeId) async {
    final idx = _collections.indexWhere((c) => c.id == collectionId);
    if (idx == -1) return;
    final col = _collections[idx];
    if (col.recipeIds.contains(recipeId)) return;
    _collections[idx] = col.copyWith(recipeIds: [...col.recipeIds, recipeId]);
    await _save();
    notifyListeners();
  }

  Future<void> removeRecipeFromCollection(
      String collectionId, String recipeId) async {
    final idx = _collections.indexWhere((c) => c.id == collectionId);
    if (idx == -1) return;
    final col = _collections[idx];
    _collections[idx] = col.copyWith(
        recipeIds: col.recipeIds.where((id) => id != recipeId).toList());
    await _save();
    notifyListeners();
  }

  Future<void> removeCollection(String id) async {
    _collections.removeWhere((c) => c.id == id);
    await _save();
    notifyListeners();
  }

  List<Achievement> _getDefaultAchievements() {
    return [
      const Achievement(
        id: 'first_cook',
        title: 'First Dish',
        description: 'Cook your first meal',
        emoji: '🍳',
        category: 'cooking',
        requiredValue: 1,
      ),
      const Achievement(
        id: 'streak_7',
        title: 'Week Warrior',
        description: '7-day cooking streak',
        emoji: '🔥',
        category: 'streak',
        requiredValue: 7,
      ),
      const Achievement(
        id: 'streak_30',
        title: 'Iron Chef',
        description: '30-day cooking streak',
        emoji: '🏆',
        category: 'streak',
        requiredValue: 30,
      ),
      const Achievement(
        id: 'meals_10',
        title: 'Home Cook',
        description: 'Cook 10 meals',
        emoji: '👨‍🍳',
        category: 'cooking',
        requiredValue: 10,
      ),
      const Achievement(
        id: 'meals_50',
        title: 'Kitchen Pro',
        description: 'Cook 50 meals',
        emoji: '⭐',
        category: 'cooking',
        requiredValue: 50,
      ),
      const Achievement(
        id: 'meals_100',
        title: 'Master Chef',
        description: 'Cook 100 meals',
        emoji: '👑',
        category: 'cooking',
        requiredValue: 100,
      ),
      const Achievement(
        id: 'collections_3',
        title: 'Curator',
        description: 'Create 3 recipe collections',
        emoji: '📚',
        category: 'social',
        requiredValue: 3,
      ),
    ];
  }
}
