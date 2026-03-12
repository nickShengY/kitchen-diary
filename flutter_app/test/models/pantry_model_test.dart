import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_diary/models/pantry_model.dart';

void main() {
  group('PantryCategory', () {
    test('has correct number of values', () {
      expect(PantryCategory.values.length, 13);
    });

    test('labels are correct', () {
      expect(PantryCategory.produce.label, 'Produce');
      expect(PantryCategory.dairy.label, 'Dairy');
      expect(PantryCategory.meat.label, 'Meat');
      expect(PantryCategory.seafood.label, 'Seafood');
      expect(PantryCategory.grains.label, 'Grains & Pasta');
      expect(PantryCategory.spices.label, 'Spices & Herbs');
      expect(PantryCategory.condiments.label, 'Condiments');
      expect(PantryCategory.canned.label, 'Canned Goods');
      expect(PantryCategory.frozen.label, 'Frozen');
      expect(PantryCategory.beverages.label, 'Beverages');
      expect(PantryCategory.snacks.label, 'Snacks');
      expect(PantryCategory.baking.label, 'Baking');
      expect(PantryCategory.other.label, 'Other');
    });

    test('emojis are correct', () {
      expect(PantryCategory.produce.emoji, '🥬');
      expect(PantryCategory.dairy.emoji, '🧀');
      expect(PantryCategory.meat.emoji, '🥩');
      expect(PantryCategory.seafood.emoji, '🐟');
      expect(PantryCategory.grains.emoji, '🌾');
      expect(PantryCategory.spices.emoji, '🌶️');
      expect(PantryCategory.condiments.emoji, '🫙');
      expect(PantryCategory.canned.emoji, '🥫');
      expect(PantryCategory.frozen.emoji, '🧊');
      expect(PantryCategory.beverages.emoji, '🥤');
      expect(PantryCategory.snacks.emoji, '🍿');
      expect(PantryCategory.baking.emoji, '🧁');
      expect(PantryCategory.other.emoji, '📦');
    });
  });

  group('FreshnessStatus', () {
    test('has correct values', () {
      expect(FreshnessStatus.values.length, 4);
      expect(FreshnessStatus.fresh.name, 'fresh');
      expect(FreshnessStatus.good.name, 'good');
      expect(FreshnessStatus.expiringSoon.name, 'expiringSoon');
      expect(FreshnessStatus.expired.name, 'expired');
    });
  });

  group('PantryItem', () {
    test('creation with required fields', () {
      const item = PantryItem(
        id: 'p1',
        name: 'Eggs',
        category: PantryCategory.dairy,
        quantity: 12,
        unit: 'pcs',
      );
      expect(item.id, 'p1');
      expect(item.name, 'Eggs');
      expect(item.category, PantryCategory.dairy);
      expect(item.quantity, 12);
      expect(item.unit, 'pcs');
      expect(item.emoji, isNull);
      expect(item.purchaseDate, isNull);
      expect(item.expiryDate, isNull);
      expect(item.location, isNull);
      expect(item.brand, isNull);
      expect(item.notes, isNull);
      expect(item.barcode, isNull);
      expect(item.isStaple, false);
    });

    test('creation with all fields', () {
      final now = DateTime.now();
      final expiry = now.add(const Duration(days: 10));
      final item = PantryItem(
        id: 'p2',
        name: 'Organic Milk',
        emoji: '🥛',
        category: PantryCategory.dairy,
        quantity: 1.5,
        unit: 'L',
        purchaseDate: now,
        expiryDate: expiry,
        location: 'Fridge',
        brand: 'Organic Farm',
        notes: 'Whole milk',
        barcode: '1234567890',
        isStaple: true,
      );
      expect(item.emoji, '🥛');
      expect(item.location, 'Fridge');
      expect(item.brand, 'Organic Farm');
      expect(item.notes, 'Whole milk');
      expect(item.barcode, '1234567890');
      expect(item.isStaple, true);
    });

    group('freshnessStatus', () {
      test('returns good when no expiry date', () {
        const item = PantryItem(
          id: 'p1', name: 'Rice', category: PantryCategory.grains,
          quantity: 1, unit: 'kg',
        );
        expect(item.freshnessStatus, FreshnessStatus.good);
      });

      test('returns expired when past expiry', () {
        final item = PantryItem(
          id: 'p2', name: 'Milk', category: PantryCategory.dairy,
          quantity: 1, unit: 'L',
          expiryDate: DateTime.now().subtract(const Duration(days: 2)),
        );
        expect(item.freshnessStatus, FreshnessStatus.expired);
      });

      test('returns expiringSoon when 1-3 days left', () {
        final item = PantryItem(
          id: 'p3', name: 'Yogurt', category: PantryCategory.dairy,
          quantity: 1, unit: 'cup',
          expiryDate: DateTime.now().add(const Duration(days: 2)),
        );
        expect(item.freshnessStatus, FreshnessStatus.expiringSoon);
      });

      test('returns good when 4-7 days left', () {
        final item = PantryItem(
          id: 'p4', name: 'Cheese', category: PantryCategory.dairy,
          quantity: 200, unit: 'g',
          expiryDate: DateTime.now().add(const Duration(days: 5)),
        );
        expect(item.freshnessStatus, FreshnessStatus.good);
      });

      test('returns fresh when more than 7 days left', () {
        final item = PantryItem(
          id: 'p5', name: 'Canned Beans', category: PantryCategory.canned,
          quantity: 2, unit: 'cans',
          expiryDate: DateTime.now().add(const Duration(days: 30)),
        );
        expect(item.freshnessStatus, FreshnessStatus.fresh);
      });
    });

    group('daysUntilExpiry', () {
      test('returns 999 when no expiry date', () {
        const item = PantryItem(
          id: 'p1', name: 'Salt', category: PantryCategory.spices,
          quantity: 500, unit: 'g',
        );
        expect(item.daysUntilExpiry, 999);
      });

      test('returns negative for expired items', () {
        final item = PantryItem(
          id: 'p2', name: 'Old Milk', category: PantryCategory.dairy,
          quantity: 1, unit: 'L',
          expiryDate: DateTime.now().subtract(const Duration(days: 5)),
        );
        expect(item.daysUntilExpiry, lessThan(0));
      });

      test('returns positive for fresh items', () {
        final item = PantryItem(
          id: 'p3', name: 'Fresh Eggs', category: PantryCategory.dairy,
          quantity: 6, unit: 'pcs',
          expiryDate: DateTime.now().add(const Duration(days: 14)),
        );
        expect(item.daysUntilExpiry, greaterThan(0));
      });
    });

    test('copyWith preserves unchanged values', () {
      const original = PantryItem(
        id: 'p1', name: 'Butter', category: PantryCategory.dairy,
        quantity: 200, unit: 'g', isStaple: true,
      );
      final updated = original.copyWith(quantity: 100);
      expect(updated.id, 'p1');
      expect(updated.name, 'Butter');
      expect(updated.quantity, 100);
      expect(updated.isStaple, true);
    });

    test('copyWith changes multiple fields', () {
      const original = PantryItem(
        id: 'p1', name: 'Butter', category: PantryCategory.dairy,
        quantity: 200, unit: 'g',
      );
      final updated = original.copyWith(
        name: 'Margarine',
        quantity: 250,
        brand: 'Flora',
      );
      expect(updated.name, 'Margarine');
      expect(updated.quantity, 250);
      expect(updated.brand, 'Flora');
    });

    test('toJson produces correct map', () {
      final item = PantryItem(
        id: 'p1',
        name: 'Eggs',
        emoji: '🥚',
        category: PantryCategory.dairy,
        quantity: 12,
        unit: 'pcs',
        purchaseDate: DateTime(2025, 1, 1),
        expiryDate: DateTime(2025, 1, 15),
        location: 'Fridge',
        isStaple: true,
      );
      final json = item.toJson();
      expect(json['id'], 'p1');
      expect(json['name'], 'Eggs');
      expect(json['emoji'], '🥚');
      expect(json['category'], 'dairy');
      expect(json['quantity'], 12);
      expect(json['unit'], 'pcs');
      expect(json['location'], 'Fridge');
      expect(json['isStaple'], true);
    });

    test('fromJson creates correct object', () {
      final json = {
        'id': 'p2',
        'name': 'Chicken',
        'emoji': '🍗',
        'category': 'meat',
        'quantity': 500,
        'unit': 'g',
        'purchaseDate': '2025-01-10T00:00:00.000',
        'expiryDate': '2025-01-15T00:00:00.000',
        'location': 'Fridge',
        'isStaple': false,
      };
      final item = PantryItem.fromJson(json);
      expect(item.id, 'p2');
      expect(item.name, 'Chicken');
      expect(item.category, PantryCategory.meat);
      expect(item.quantity, 500);
      expect(item.location, 'Fridge');
    });

    test('fromJson with invalid category falls back to other', () {
      final json = {
        'id': 'p3',
        'name': 'Mystery',
        'category': 'unknown_category',
        'quantity': 1,
        'unit': 'pcs',
      };
      final item = PantryItem.fromJson(json);
      expect(item.category, PantryCategory.other);
    });

    test('fromJson with null optional fields', () {
      final json = {
        'id': 'p4',
        'name': 'Sugar',
        'category': 'baking',
        'quantity': 1,
        'unit': 'kg',
        'purchaseDate': null,
        'expiryDate': null,
        'location': null,
        'brand': null,
        'notes': null,
        'barcode': null,
      };
      final item = PantryItem.fromJson(json);
      expect(item.purchaseDate, isNull);
      expect(item.expiryDate, isNull);
      expect(item.location, isNull);
      expect(item.brand, isNull);
    });

    test('toJson/fromJson roundtrip', () {
      final original = PantryItem(
        id: 'rt-1',
        name: 'Olive Oil',
        emoji: '🫒',
        category: PantryCategory.condiments,
        quantity: 500,
        unit: 'ml',
        purchaseDate: DateTime(2025, 1, 1),
        expiryDate: DateTime(2025, 7, 1),
        location: 'Pantry',
        brand: 'Extra Virgin',
        notes: 'Cold pressed',
        barcode: '9876543210',
        isStaple: true,
      );
      final restored = PantryItem.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.emoji, original.emoji);
      expect(restored.category, original.category);
      expect(restored.quantity, original.quantity);
      expect(restored.unit, original.unit);
      expect(restored.location, original.location);
      expect(restored.brand, original.brand);
      expect(restored.notes, original.notes);
      expect(restored.barcode, original.barcode);
      expect(restored.isStaple, original.isStaple);
    });
  });
}
