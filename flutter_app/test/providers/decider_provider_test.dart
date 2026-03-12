import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kitchen_diary/providers/decider_provider.dart';

void main() {
  late DeciderProvider provider;
  late Directory tempDir;

  Future<DeciderProvider> createProvider() async {
    final value = DeciderProvider();
    await Future.delayed(const Duration(milliseconds: 200));
    return value;
  }

  Future<void> seedCuisine() async {
    await provider.addCuisine(
      name: 'Italian',
      emoji: 'IT',
      dishes: ['Pizza', 'Pasta'],
    );
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_decider_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('DeciderProvider initialization', () {
    test('starts with an empty wheel', () async {
      provider = await createProvider();
      expect(provider.isLoading, false);
      expect(provider.cuisines, isEmpty);
    });

    test('starts with empty favorites', () async {
      provider = await createProvider();
      expect(provider.favoriteDishes, isEmpty);
    });

    test('starts with empty spin history', () async {
      provider = await createProvider();
      expect(provider.spinHistory, isEmpty);
    });
  });

  group('CuisineCategory model', () {
    test('creation', () {
      final cuisine = CuisineCategory(
        id: 'test',
        name: 'Test',
        emoji: 'T',
        dishes: ['Dish 1', 'Dish 2'],
      );
      expect(cuisine.id, 'test');
      expect(cuisine.dishes.length, 2);
      expect(cuisine.isCustom, false);
    });

    test('toJson/fromJson roundtrip', () {
      final original = CuisineCategory(
        id: 'c1',
        name: 'Italian',
        emoji: 'IT',
        dishes: ['Pizza', 'Pasta'],
        isCustom: true,
      );
      final restored = CuisineCategory.fromJson(original.toJson());
      expect(restored.id, 'c1');
      expect(restored.name, 'Italian');
      expect(restored.emoji, 'IT');
      expect(restored.dishes, ['Pizza', 'Pasta']);
      expect(restored.isCustom, true);
    });

    test('copyWith', () {
      final original = CuisineCategory(
        id: 'c1',
        name: 'Italian',
        emoji: 'IT',
        dishes: ['Pizza'],
      );
      final updated = original.copyWith(name: 'Italian Cuisine', emoji: 'IC');
      expect(updated.id, 'c1');
      expect(updated.name, 'Italian Cuisine');
      expect(updated.emoji, 'IC');
      expect(updated.dishes, ['Pizza']);
    });
  });

  group('addCuisine', () {
    test('adds a custom cuisine', () async {
      provider = await createProvider();
      final before = provider.cuisines.length;
      await provider.addCuisine(name: 'Custom', emoji: 'CU', dishes: ['Dish A']);
      expect(provider.cuisines.length, before + 1);
      final added = provider.cuisines.last;
      expect(added.name, 'Custom');
      expect(added.isCustom, true);
      expect(added.dishes, ['Dish A']);
    });

    test('generates unique id', () async {
      provider = await createProvider();
      await provider.addCuisine(name: 'A', emoji: 'A');
      await Future.delayed(const Duration(milliseconds: 2));
      await provider.addCuisine(name: 'B', emoji: 'B');
      final ids = provider.cuisines.map((cuisine) => cuisine.id).toSet();
      expect(ids.length, provider.cuisines.length);
    });

    test('adds cuisine with empty dishes', () async {
      provider = await createProvider();
      await provider.addCuisine(name: 'Empty', emoji: 'E');
      final added = provider.cuisines.last;
      expect(added.dishes, isEmpty);
    });
  });

  group('updateCuisine', () {
    test('updates an existing cuisine', () async {
      provider = await createProvider();
      await seedCuisine();
      final first = provider.cuisines.first;
      final updated = first.copyWith(name: 'Updated Name');
      await provider.updateCuisine(updated);
      expect(provider.cuisines.first.name, 'Updated Name');
    });

    test('does nothing for nonexistent cuisine', () async {
      provider = await createProvider();
      final before = provider.cuisines.length;
      final fake = CuisineCategory(
        id: 'nonexistent',
        name: 'Fake',
        emoji: 'F',
        dishes: const [],
      );
      await provider.updateCuisine(fake);
      expect(provider.cuisines.length, before);
    });
  });

  group('deleteCuisine', () {
    test('removes a cuisine', () async {
      provider = await createProvider();
      await seedCuisine();
      final before = provider.cuisines.length;
      final id = provider.cuisines.first.id;
      await provider.deleteCuisine(id);
      expect(provider.cuisines.length, before - 1);
    });

    test('does nothing for nonexistent id', () async {
      provider = await createProvider();
      final before = provider.cuisines.length;
      await provider.deleteCuisine('nonexistent');
      expect(provider.cuisines.length, before);
    });
  });

  group('dish management', () {
    test('addDish adds to cuisine', () async {
      provider = await createProvider();
      await seedCuisine();
      final id = provider.cuisines.first.id;
      final before = provider.cuisines.first.dishes.length;
      await provider.addDish(id, 'New Dish');
      expect(provider.cuisines.first.dishes.length, before + 1);
      expect(provider.cuisines.first.dishes.last, 'New Dish');
    });

    test('addDish does not duplicate', () async {
      provider = await createProvider();
      await seedCuisine();
      final id = provider.cuisines.first.id;
      final existing = provider.cuisines.first.dishes.first;
      final before = provider.cuisines.first.dishes.length;
      await provider.addDish(id, existing);
      expect(provider.cuisines.first.dishes.length, before);
    });

    test('addDish does nothing for nonexistent cuisine', () async {
      provider = await createProvider();
      await provider.addDish('nonexistent', 'Dish');
      expect(provider.cuisines, isEmpty);
    });

    test('updateDish changes dish text', () async {
      provider = await createProvider();
      await seedCuisine();
      final id = provider.cuisines.first.id;
      await provider.updateDish(id, 0, 'Updated Dish');
      expect(provider.cuisines.first.dishes[0], 'Updated Dish');
    });

    test('updateDish does nothing for out-of-range index', () async {
      provider = await createProvider();
      await seedCuisine();
      final id = provider.cuisines.first.id;
      final before = List<String>.from(provider.cuisines.first.dishes);
      await provider.updateDish(id, 999, 'Out of Range');
      expect(provider.cuisines.first.dishes, before);
    });

    test('deleteDish removes from cuisine', () async {
      provider = await createProvider();
      await seedCuisine();
      final id = provider.cuisines.first.id;
      final dish = provider.cuisines.first.dishes.first;
      final before = provider.cuisines.first.dishes.length;
      await provider.deleteDish(id, dish);
      expect(provider.cuisines.first.dishes.length, before - 1);
    });
  });

  group('reorder', () {
    test('reorderCuisines swaps positions', () async {
      provider = await createProvider();
      await provider.addCuisine(name: 'Italian', emoji: 'IT', dishes: ['Pizza']);
      await provider.addCuisine(name: 'Japanese', emoji: 'JP', dishes: ['Ramen']);
      final first = provider.cuisines[0].id;
      final second = provider.cuisines[1].id;
      await provider.reorderCuisines(0, 2);
      expect(provider.cuisines[0].id, second);
      expect(provider.cuisines[1].id, first);
    });

    test('reorderDishes swaps positions', () async {
      provider = await createProvider();
      await seedCuisine();
      final cuisineId = provider.cuisines.first.id;
      final dishes = provider.cuisines.first.dishes;
      final first = dishes[0];
      final second = dishes[1];
      await provider.reorderDishes(cuisineId, 0, 2);
      expect(provider.cuisines.first.dishes[0], second);
      expect(provider.cuisines.first.dishes[1], first);
    });
  });

  group('favorites', () {
    test('toggleFavorite adds dish', () async {
      provider = await createProvider();
      await provider.toggleFavorite('Pizza');
      expect(provider.favoriteDishes, contains('Pizza'));
    });

    test('toggleFavorite removes dish on second call', () async {
      provider = await createProvider();
      await provider.toggleFavorite('Pizza');
      await provider.toggleFavorite('Pizza');
      expect(provider.favoriteDishes, isNot(contains('Pizza')));
    });

    test('multiple favorites', () async {
      provider = await createProvider();
      await provider.toggleFavorite('Pizza');
      await provider.toggleFavorite('Pasta');
      await provider.toggleFavorite('Sushi');
      expect(provider.favoriteDishes.length, 3);
    });
  });

  group('spin history', () {
    test('recordSpin adds to history', () async {
      provider = await createProvider();
      await provider.recordSpin(
        cuisineName: 'Italian',
        cuisineEmoji: 'IT',
        dish: 'Pizza',
      );
      expect(provider.spinHistory.length, 1);
      expect(provider.spinHistory.first['dish'], 'Pizza');
    });

    test('recordSpin inserts at front', () async {
      provider = await createProvider();
      await provider.recordSpin(cuisineName: 'A', cuisineEmoji: 'A', dish: 'First');
      await provider.recordSpin(cuisineName: 'B', cuisineEmoji: 'B', dish: 'Second');
      expect(provider.spinHistory.first['dish'], 'Second');
    });

    test('recordSpin includes timestamp', () async {
      provider = await createProvider();
      await provider.recordSpin(cuisineName: 'X', cuisineEmoji: 'X', dish: 'Y');
      expect(provider.spinHistory.first.containsKey('timestamp'), true);
    });

    test('history caps at 50 entries', () async {
      provider = await createProvider();
      for (int index = 0; index < 55; index++) {
        await provider.recordSpin(
          cuisineName: 'C',
          cuisineEmoji: 'C',
          dish: 'Dish $index',
        );
      }
      expect(provider.spinHistory.length, 50);
      expect(provider.spinHistory.first['dish'], 'Dish 54');
    });

    test('clearHistory empties the list', () async {
      provider = await createProvider();
      await provider.recordSpin(cuisineName: 'X', cuisineEmoji: 'X', dish: 'Y');
      await provider.clearHistory();
      expect(provider.spinHistory, isEmpty);
    });
  });

  group('resetToDefaults', () {
    test('clears saved cuisines', () async {
      provider = await createProvider();
      await provider.addCuisine(name: 'Custom A', emoji: 'A');
      await provider.addCuisine(name: 'Custom B', emoji: 'B');
      expect(provider.cuisines.length, 2);

      await provider.resetToDefaults();
      expect(provider.cuisines, isEmpty);
    });
  });

  group('persistence', () {
    test('cuisines persist across instances', () async {
      provider = await createProvider();
      await provider.addCuisine(name: 'Persist', emoji: 'P', dishes: ['Test']);

      final provider2 = DeciderProvider();
      await Future.delayed(const Duration(milliseconds: 200));
      expect(provider2.cuisines.any((cuisine) => cuisine.name == 'Persist'), true);
    });

    test('favorites persist across instances', () async {
      provider = await createProvider();
      await provider.toggleFavorite('Sushi');

      final provider2 = DeciderProvider();
      await Future.delayed(const Duration(milliseconds: 200));
      expect(provider2.favoriteDishes, contains('Sushi'));
    });

    test('history persists across instances', () async {
      provider = await createProvider();
      await provider.recordSpin(
        cuisineName: 'Test',
        cuisineEmoji: 'T',
        dish: 'Persist Dish',
      );

      final provider2 = DeciderProvider();
      await Future.delayed(const Duration(milliseconds: 200));
      expect(provider2.spinHistory.length, 1);
    });
  });
}
