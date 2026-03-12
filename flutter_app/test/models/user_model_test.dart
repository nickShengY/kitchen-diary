import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_diary/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('creation with required fields', () {
      final user = UserModel(
        id: 'u1',
        email: 'test@test.com',
        displayName: 'Chef Test',
        createdAt: DateTime(2025, 1, 1),
        lastActiveAt: DateTime(2025, 6, 1),
      );
      expect(user.id, 'u1');
      expect(user.email, 'test@test.com');
      expect(user.displayName, 'Chef Test');
      expect(user.avatarEmoji, '👨‍🍳');
      expect(user.isVip, false);
      expect(user.hasValidVip, false);
      expect(user.followers, isEmpty);
      expect(user.following, isEmpty);
      expect(user.favoriteRecipes, isEmpty);
      expect(user.savedRecipes, isEmpty);
      expect(user.recipesCount, 0);
      expect(user.likesReceived, 0);
      expect(user.preferences, isNull);
      expect(user.badges, isEmpty);
      expect(user.photoUrl, isNull);
      expect(user.bio, isNull);
      expect(user.vipExpiresAt, isNull);
    });

    test('creation with all fields', () {
      final user = UserModel(
        id: 'u2',
        email: 'vip@test.com',
        displayName: 'VIP Chef',
        photoUrl: 'https://example.com/photo.jpg',
        bio: 'I love cooking!',
        avatarEmoji: '🧑‍🍳',
        isVip: true,
        vipExpiresAt: DateTime(2026, 1, 1),
        followers: ['u3', 'u4'],
        following: ['u5'],
        favoriteRecipes: ['r1'],
        savedRecipes: ['r2', 'r3'],
        recipesCount: 10,
        likesReceived: 100,
        createdAt: DateTime(2024, 1, 1),
        lastActiveAt: DateTime(2025, 6, 1),
        preferences: {'theme': 'dark'},
        badges: ['first_cook', 'week_warrior'],
      );
      expect(user.photoUrl, 'https://example.com/photo.jpg');
      expect(user.bio, 'I love cooking!');
      expect(user.avatarEmoji, '🧑‍🍳');
      expect(user.isVip, true);
      expect(user.followers.length, 2);
      expect(user.following.length, 1);
      expect(user.recipesCount, 10);
      expect(user.likesReceived, 100);
      expect(user.badges.length, 2);
    });

    group('hasValidVip', () {
      test('returns true when VIP and not expired', () {
        final user = UserModel(
          id: 'u1', email: 'a@b.com', displayName: 'A',
          isVip: true,
          vipExpiresAt: DateTime.now().add(const Duration(days: 30)),
          createdAt: DateTime.now(), lastActiveAt: DateTime.now(),
        );
        expect(user.hasValidVip, true);
      });

      test('returns false when VIP but expired', () {
        final user = UserModel(
          id: 'u1', email: 'a@b.com', displayName: 'A',
          isVip: true,
          vipExpiresAt: DateTime.now().subtract(const Duration(days: 1)),
          createdAt: DateTime.now(), lastActiveAt: DateTime.now(),
        );
        expect(user.hasValidVip, false);
      });

      test('returns false when VIP but no expiry date', () {
        final user = UserModel(
          id: 'u1', email: 'a@b.com', displayName: 'A',
          isVip: true, vipExpiresAt: null,
          createdAt: DateTime.now(), lastActiveAt: DateTime.now(),
        );
        expect(user.hasValidVip, false);
      });

      test('returns false when not VIP even with future expiry', () {
        final user = UserModel(
          id: 'u1', email: 'a@b.com', displayName: 'A',
          isVip: false,
          vipExpiresAt: DateTime.now().add(const Duration(days: 30)),
          createdAt: DateTime.now(), lastActiveAt: DateTime.now(),
        );
        expect(user.hasValidVip, false);
      });

      test('returns false for default user', () {
        final user = UserModel(
          id: 'u1', email: 'a@b.com', displayName: 'A',
          createdAt: DateTime.now(), lastActiveAt: DateTime.now(),
        );
        expect(user.hasValidVip, false);
      });

      test('edge case: VIP expires exactly now', () {
        final now = DateTime.now();
        final user = UserModel(
          id: 'u1', email: 'a@b.com', displayName: 'A',
          isVip: true, vipExpiresAt: now,
          createdAt: now, lastActiveAt: now,
        );
        // isAfter is strict, so exactly now returns false
        expect(user.hasValidVip, false);
      });
    });

    group('copyWith', () {
      test('preserves unchanged values', () {
        final original = UserModel(
          id: 'u1', email: 'a@b.com', displayName: 'Original',
          createdAt: DateTime(2025, 1, 1), lastActiveAt: DateTime(2025, 6, 1),
        );
        final updated = original.copyWith(displayName: 'Updated');
        expect(updated.id, 'u1');
        expect(updated.email, 'a@b.com');
        expect(updated.displayName, 'Updated');
      });

      test('changes multiple fields', () {
        final original = UserModel(
          id: 'u1', email: 'a@b.com', displayName: 'A',
          createdAt: DateTime(2025, 1, 1), lastActiveAt: DateTime(2025, 1, 1),
        );
        final updated = original.copyWith(
          bio: 'New bio',
          isVip: true,
          recipesCount: 5,
          badges: ['badge1'],
        );
        expect(updated.bio, 'New bio');
        expect(updated.isVip, true);
        expect(updated.recipesCount, 5);
        expect(updated.badges, ['badge1']);
      });

      test('changes followers and following', () {
        final original = UserModel(
          id: 'u1', email: 'a@b.com', displayName: 'A',
          followers: ['u2'], following: ['u3'],
          createdAt: DateTime(2025, 1, 1), lastActiveAt: DateTime(2025, 1, 1),
        );
        final updated = original.copyWith(
          followers: ['u2', 'u4'],
          following: ['u3', 'u5', 'u6'],
        );
        expect(updated.followers.length, 2);
        expect(updated.following.length, 3);
      });
    });

    group('toFirestore', () {
      test('produces correct map', () {
        final user = UserModel(
          id: 'u1',
          email: 'test@test.com',
          displayName: 'Chef',
          avatarEmoji: '👨‍🍳',
          isVip: false,
          followers: ['u2'],
          following: [],
          favoriteRecipes: ['r1'],
          savedRecipes: [],
          recipesCount: 5,
          likesReceived: 20,
          createdAt: DateTime(2025, 1, 1),
          lastActiveAt: DateTime(2025, 6, 1),
          badges: ['first_cook'],
        );
        final map = user.toFirestore();
        expect(map['email'], 'test@test.com');
        expect(map['displayName'], 'Chef');
        expect(map['avatarEmoji'], '👨‍🍳');
        expect(map['isVip'], false);
        expect(map['followers'], ['u2']);
        expect(map['favoriteRecipes'], ['r1']);
        expect(map['recipesCount'], 5);
        expect(map['likesReceived'], 20);
        expect(map['badges'], ['first_cook']);
        expect(map['vipExpiresAt'], isNull);
      });

      test('includes vipExpiresAt when set', () {
        final user = UserModel(
          id: 'u1', email: 'a@b.com', displayName: 'A',
          isVip: true, vipExpiresAt: DateTime(2026, 1, 1),
          createdAt: DateTime(2025, 1, 1), lastActiveAt: DateTime(2025, 1, 1),
        );
        final map = user.toFirestore();
        expect(map['vipExpiresAt'], isNotNull);
      });
    });
  });
}
