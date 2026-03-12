import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kitchen_diary/models/pantry_model.dart';
import 'package:kitchen_diary/providers/pantry_provider.dart';

void main() {
  late PantryProvider provider;
  late Directory tempDir;

  final now = DateTime(2026, 3, 11);

  PantryItem eggsItem() => PantryItem(
        id: 'eggs',
        name: 'Eggs',
        category: PantryCategory.dairy,
        quantity: 12,
        unit: 'pcs',
        purchaseDate: now.subtract(const Duration(days: 2)),
        expiryDate: now.add(const Duration(days: 10)),
        isStaple: true,
      );

  PantryItem milkItem() => PantryItem(
        id: 'milk',
        name: 'Milk',
        category: PantryCategory.dairy,
        quantity: 1,
        unit: 'L',
        purchaseDate: now.subtract(const Duration(days: 1)),
        expiryDate: now.add(const Duration(days: 5)),
        isStaple: true,
      );

  PantryItem riceItem() => PantryItem(
        id: 'rice',
        name: 'Rice',
        category: PantryCategory.grains,
        quantity: 2,
        unit: 'kg',
        purchaseDate: now.subtract(const Duration(days: 7)),
        expiryDate: now.add(const Duration(days: 180)),
      );

  Future<PantryProvider> createProvider() async {
    final value = PantryProvider();
    await Future.delayed(const Duration(milliseconds: 200));
    return value;
  }

  Future<void> seedPantry(PantryProvider target) async {
    await target.addItem(eggsItem());
    await target.addItem(milkItem());
    await target.addItem(riceItem());
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_pantry_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('PantryProvider initialization', () {
    test('starts empty on first run', () async {
      provider = await createProvider();
      expect(provider.isLoading, false);
      expect(provider.allItems, isEmpty);
    });

    test('items reflect saved data when present', () async {
      provider = await createProvider();
      await seedPantry(provider);
      final categories = provider.allItems.map((item) => item.category).toSet();
      expect(categories.length, greaterThan(1));
    });

    test('totalItems returns correct count', () async {
      provider = await createProvider();
      await seedPantry(provider);
      expect(provider.totalItems, provider.allItems.length);
    });
  });

  group('filtering', () {
    test('setCategory filters items', () async {
      provider = await createProvider();
      await seedPantry(provider);
      provider.setCategory(PantryCategory.dairy);
      expect(provider.selectedCategory, PantryCategory.dairy);
      for (final item in provider.items) {
        expect(item.category, PantryCategory.dairy);
      }
    });

    test('setCategory to null shows all items', () async {
      provider = await createProvider();
      await seedPantry(provider);
      provider.setCategory(PantryCategory.dairy);
      provider.setCategory(null);
      expect(provider.items.length, provider.allItems.length);
    });

    test('setSearchQuery filters by name', () async {
      provider = await createProvider();
      await seedPantry(provider);
      provider.setSearchQuery('Eggs');
      expect(provider.items, isNotEmpty);
      for (final item in provider.items) {
        expect(item.name.toLowerCase().contains('eggs'), true);
      }
    });

    test('setSearchQuery with non-matching term returns empty', () async {
      provider = await createProvider();
      await seedPantry(provider);
      provider.setSearchQuery('xyznonexistent');
      expect(provider.items, isEmpty);
    });

    test('setSearchQuery is case-insensitive', () async {
      provider = await createProvider();
      await seedPantry(provider);
      provider.setSearchQuery('eggs');
      final lower = provider.items.length;
      provider.setSearchQuery('EGGS');
      final upper = provider.items.length;
      expect(lower, upper);
    });

    test('combined category and search filters', () async {
      provider = await createProvider();
      await seedPantry(provider);
      provider.setCategory(PantryCategory.dairy);
      provider.setSearchQuery('milk');
      for (final item in provider.items) {
        expect(item.category, PantryCategory.dairy);
        expect(item.name.toLowerCase().contains('milk'), true);
      }
    });
  });

  group('sorting', () {
    test('setSortBy changes sort', () async {
      provider = await createProvider();
      await seedPantry(provider);
      provider.setSortBy('name');
      expect(provider.sortBy, 'name');
      final names = provider.items.map((item) => item.name).toList();
      final sorted = List<String>.from(names)..sort();
      expect(names, sorted);
    });

    test('sort by expiry puts expiring items first', () async {
      provider = await createProvider();
      await seedPantry(provider);
      provider.setSortBy('expiry');
      final days = provider.items.map((item) => item.daysUntilExpiry).toList();
      for (int index = 1; index < days.length; index++) {
        expect(days[index], greaterThanOrEqualTo(days[index - 1]));
      }
    });

    test('sort by category groups by category index', () async {
      provider = await createProvider();
      await seedPantry(provider);
      provider.setSortBy('category');
      final indices = provider.items.map((item) => item.category.index).toList();
      for (int index = 1; index < indices.length; index++) {
        expect(indices[index], greaterThanOrEqualTo(indices[index - 1]));
      }
    });
  });

  group('CRUD operations', () {
    test('addItem increases total', () async {
      provider = await createProvider();
      final before = provider.totalItems;
      await provider.addItem(const PantryItem(
        id: 'new-item',
        name: 'New Item',
        category: PantryCategory.other,
        quantity: 1,
        unit: 'pcs',
      ));
      expect(provider.totalItems, before + 1);
    });

    test('updateItem changes item properties', () async {
      provider = await createProvider();
      await seedPantry(provider);
      final firstItem = provider.allItems.first;
      final updated = firstItem.copyWith(name: 'Updated Name');
      await provider.updateItem(updated);
      expect(
        provider.allItems.firstWhere((item) => item.id == firstItem.id).name,
        'Updated Name',
      );
    });

    test('updateItem does nothing for nonexistent id', () async {
      provider = await createProvider();
      final before = provider.totalItems;
      await provider.updateItem(const PantryItem(
        id: 'nonexistent',
        name: 'Ghost',
        category: PantryCategory.other,
        quantity: 1,
        unit: 'pcs',
      ));
      expect(provider.totalItems, before);
    });

    test('removeItem decreases total', () async {
      provider = await createProvider();
      await seedPantry(provider);
      final before = provider.totalItems;
      final id = provider.allItems.first.id;
      await provider.removeItem(id);
      expect(provider.totalItems, before - 1);
    });

    test('removeItem does nothing for nonexistent id', () async {
      provider = await createProvider();
      final before = provider.totalItems;
      await provider.removeItem('nonexistent');
      expect(provider.totalItems, before);
    });
  });

  group('useItem', () {
    test('reduces quantity', () async {
      provider = await createProvider();
      await seedPantry(provider);
      final eggs = provider.allItems.firstWhere((item) => item.name == 'Eggs');
      await provider.useItem(eggs.id, 3);
      final updated =
          provider.allItems.firstWhere((item) => item.id == eggs.id);
      expect(updated.quantity, 9);
    });

    test('removes item when quantity reaches zero', () async {
      provider = await createProvider();
      await seedPantry(provider);
      final eggs = provider.allItems.firstWhere((item) => item.name == 'Eggs');
      await provider.useItem(eggs.id, 12);
      expect(provider.allItems.where((item) => item.id == eggs.id), isEmpty);
    });

    test('removes item when usage exceeds quantity', () async {
      provider = await createProvider();
      await seedPantry(provider);
      final eggs = provider.allItems.firstWhere((item) => item.name == 'Eggs');
      await provider.useItem(eggs.id, 100);
      expect(provider.allItems.where((item) => item.id == eggs.id), isEmpty);
    });

    test('does nothing for nonexistent item', () async {
      provider = await createProvider();
      final before = provider.totalItems;
      await provider.useItem('nonexistent', 5);
      expect(provider.totalItems, before);
    });
  });

  group('computed properties', () {
    test('stapleItems returns only staple items', () async {
      provider = await createProvider();
      await seedPantry(provider);
      for (final item in provider.stapleItems) {
        expect(item.isStaple, true);
      }
    });

    test('categoryCount returns correct counts', () async {
      provider = await createProvider();
      await seedPantry(provider);
      final counts = provider.categoryCount;
      int total = 0;
      for (final count in counts.values) {
        total += count;
      }
      expect(total, provider.totalItems);
    });

    test('availableIngredientNames returns lowercase names', () async {
      provider = await createProvider();
      await seedPantry(provider);
      final names = provider.availableIngredientNames;
      expect(names, isNotEmpty);
      for (final name in names) {
        expect(name, name.toLowerCase());
      }
    });
  });

  group('persistence', () {
    test('data survives provider recreation', () async {
      provider = await createProvider();
      await provider.addItem(const PantryItem(
        id: 'persist-test',
        name: 'Persist Item',
        category: PantryCategory.snacks,
        quantity: 5,
        unit: 'pcs',
      ));

      final provider2 = PantryProvider();
      await Future.delayed(const Duration(milliseconds: 200));
      expect(provider2.allItems.any((item) => item.id == 'persist-test'), true);
    });
  });
}
