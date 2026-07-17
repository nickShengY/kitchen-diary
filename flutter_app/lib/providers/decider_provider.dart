import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../data/kitchen_data_repository.dart';

/// Model for a cuisine category with dishes
class CuisineCategory {
  final String id;
  String name;
  String emoji;
  List<String> dishes;
  bool isCustom;

  CuisineCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.dishes,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'dishes': dishes,
        'isCustom': isCustom,
      };

  factory CuisineCategory.fromJson(Map<String, dynamic> json) =>
      CuisineCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        dishes: List<String>.from(json['dishes'] ?? []),
        isCustom: json['isCustom'] as bool? ?? false,
      );

  CuisineCategory copyWith({
    String? name,
    String? emoji,
    List<String>? dishes,
    bool? isCustom,
  }) =>
      CuisineCategory(
        id: id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        dishes: dishes ?? this.dishes,
        isCustom: isCustom ?? this.isCustom,
      );
}

/// Provider for managing wheel/decider customization
class DeciderProvider extends ChangeNotifier {
  static const String _boxName = 'decider_data';
  static const String _cuisinesKey = 'custom_cuisines';
  static const String _favoritesKey = 'favorite_dishes';
  static const String _historyKey = 'spin_history';

  List<CuisineCategory> _cuisines = [];
  List<String> _favoriteDishes = [];
  List<Map<String, dynamic>> _spinHistory = [];
  bool _isLoading = true;

  List<CuisineCategory> get cuisines => _cuisines;
  List<String> get favoriteDishes => _favoriteDishes;
  List<Map<String, dynamic>> get spinHistory => _spinHistory;
  bool get isLoading => _isLoading;

  DeciderProvider() {
    _loadData();
  }

  /// Load data from local storage.
  Future<void> _loadData() async {
    _isLoading = true;

    try {
      final box = await Hive.openBox(_boxName);

      final cuisinesJson = box.get(_cuisinesKey);
      if (cuisinesJson != null) {
        final List<dynamic> decoded = jsonDecode(cuisinesJson);
        _cuisines = decoded.map((e) => CuisineCategory.fromJson(e)).toList();
      } else {
        _cuisines = await _loadDefaultCuisines();
        await _saveCuisines();
      }

      if (_cuisines.isEmpty) {
        _cuisines = await _loadDefaultCuisines();
        await _saveCuisines();
      }

      final favoritesJson = box.get(_favoritesKey);
      if (favoritesJson != null) {
        _favoriteDishes = List<String>.from(jsonDecode(favoritesJson));
      }

      final historyJson = box.get(_historyKey);
      if (historyJson != null) {
        _spinHistory = List<Map<String, dynamic>>.from(jsonDecode(historyJson));
      }
    } catch (e) {
      debugPrint('Error loading decider data: $e');
      _cuisines = [];
      _favoriteDishes = [];
      _spinHistory = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<CuisineCategory>> _loadDefaultCuisines() async {
    try {
      final repo = await KitchenDataRepository.load();
      return repo.cuisineCategories
          .map(
            (item) => CuisineCategory(
              id: item['id'] as String,
              name: item['name'] as String,
              emoji: item['emoji'] as String? ?? '🍽️',
              dishes: List<String>.from(item['dishes'] as List? ?? const []),
              isCustom: false,
            ),
          )
          .toList(growable: false);
    } catch (e) {
      debugPrint('Error loading default cuisines: $e');
      return const [];
    }
  }

  Future<void> _saveCuisines() async {
    try {
      final box = await Hive.openBox(_boxName);
      final json = jsonEncode(_cuisines.map((c) => c.toJson()).toList());
      await box.put(_cuisinesKey, json);
    } catch (e) {
      debugPrint('Error saving cuisines: $e');
    }
  }

  Future<void> addCuisine({
    required String name,
    required String emoji,
    List<String>? dishes,
  }) async {
    final newId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final cuisine = CuisineCategory(
      id: newId,
      name: name,
      emoji: emoji,
      dishes: dishes ?? [],
      isCustom: true,
    );
    _cuisines.add(cuisine);
    await _saveCuisines();
    notifyListeners();
  }

  Future<void> updateCuisine(CuisineCategory cuisine) async {
    final index = _cuisines.indexWhere((c) => c.id == cuisine.id);
    if (index != -1) {
      _cuisines[index] = cuisine;
      await _saveCuisines();
      notifyListeners();
    }
  }

  Future<void> deleteCuisine(String id) async {
    _cuisines.removeWhere((c) => c.id == id);
    await _saveCuisines();
    notifyListeners();
  }

  Future<void> addDish(String cuisineId, String dish) async {
    final index = _cuisines.indexWhere((c) => c.id == cuisineId);
    if (index != -1 && !_cuisines[index].dishes.contains(dish)) {
      _cuisines[index].dishes.add(dish);
      await _saveCuisines();
      notifyListeners();
    }
  }

  Future<void> updateDish(
      String cuisineId, int dishIndex, String newDish) async {
    final index = _cuisines.indexWhere((c) => c.id == cuisineId);
    if (index != -1 && dishIndex < _cuisines[index].dishes.length) {
      _cuisines[index].dishes[dishIndex] = newDish;
      await _saveCuisines();
      notifyListeners();
    }
  }

  Future<void> deleteDish(String cuisineId, String dish) async {
    final index = _cuisines.indexWhere((c) => c.id == cuisineId);
    if (index != -1) {
      _cuisines[index].dishes.remove(dish);
      await _saveCuisines();
      notifyListeners();
    }
  }

  Future<void> reorderCuisines(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex--;
    final cuisine = _cuisines.removeAt(oldIndex);
    _cuisines.insert(newIndex, cuisine);
    await _saveCuisines();
    notifyListeners();
  }

  Future<void> reorderDishes(
      String cuisineId, int oldIndex, int newIndex) async {
    final index = _cuisines.indexWhere((c) => c.id == cuisineId);
    if (index != -1) {
      if (oldIndex < newIndex) newIndex--;
      final dish = _cuisines[index].dishes.removeAt(oldIndex);
      _cuisines[index].dishes.insert(newIndex, dish);
      await _saveCuisines();
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String dish) async {
    if (_favoriteDishes.contains(dish)) {
      _favoriteDishes.remove(dish);
    } else {
      _favoriteDishes.add(dish);
    }
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_favoritesKey, jsonEncode(_favoriteDishes));
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  Future<void> recordSpin({
    required String cuisineName,
    required String cuisineEmoji,
    required String dish,
  }) async {
    _spinHistory.insert(0, {
      'cuisineName': cuisineName,
      'cuisineEmoji': cuisineEmoji,
      'dish': dish,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (_spinHistory.length > 50) {
      _spinHistory = _spinHistory.sublist(0, 50);
    }

    await _saveHistory();
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_historyKey, jsonEncode(_spinHistory));
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  /// Reset the wheel configuration to an empty user-managed state.
  Future<void> resetToDefaults() async {
    _cuisines = [];
    await _saveCuisines();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _spinHistory.clear();
    await _saveHistory();
    notifyListeners();
  }
}
