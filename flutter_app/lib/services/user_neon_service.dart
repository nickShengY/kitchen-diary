import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;


/// Neon Database configuration for user data.
///
/// Set these at build time:
/// flutter run --dart-define=NEON_USER_API_URL=https://YOUR-PROJECT.neon.tech/rest/v1
///              --dart-define=NEON_USER_API_KEY=YOUR_SERVICE_ROLE_KEY
///
/// For production, use a backend service to proxy requests and issue per-user JWTs.
class NeonUserConfig {
  static const String baseUrl = String.fromEnvironment(
    'NEON_USER_API_URL',
    defaultValue: '',
  );

  static const String apiKey = String.fromEnvironment(
    'NEON_USER_API_KEY',
    defaultValue: '',
  );

  static bool get isConfigured => baseUrl.isNotEmpty && apiKey.isNotEmpty;
}

/// Service for managing user data in Neon PostgreSQL.
class UserNeonService {
  UserNeonService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _buildUri(String path, [Map<String, String>? query]) {
    final normalizedBase = NeonUserConfig.baseUrl.endsWith('/')
        ? NeonUserConfig.baseUrl.substring(0, NeonUserConfig.baseUrl.length - 1)
        : NeonUserConfig.baseUrl;
    return Uri.parse('$normalizedBase$path').replace(queryParameters: query);
  }

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${NeonUserConfig.apiKey}',
        'apikey': NeonUserConfig.apiKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ============================================================
  // USER PROFILE OPERATIONS
  // ============================================================

  /// Create a new user profile in Neon.
  Future<bool> createUserProfile({
    required String id,
    required String email,
    required String displayName,
    String? photoUrl,
    String avatarEmoji = '👨‍🍳',
  }) async {
    if (!NeonUserConfig.isConfigured) {
      debugPrint('Neon not configured, skipping createUserProfile');
      return false;
    }

    final now = DateTime.now().toIso8601String();
    final body = jsonEncode([
      {
        'id': id,
        'email': email,
        'display_name': displayName,
        'photo_url': photoUrl,
        'avatar_emoji': avatarEmoji,
        'is_vip': false,
        'recipes_count': 0,
        'likes_received': 0,
        'followers_count': 0,
        'following_count': 0,
        'xp': 0,
        'level': 1,
        'streak_days': 0,
        'created_at': now,
        'last_active_at': now,
      }
    ]);

    try {
      final response = await _client.post(
        _buildUri('/users'),
        headers: {..._headers, 'Prefer': 'return=minimal'},
        body: body,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }

      debugPrint('Neon createUserProfile error: ${response.statusCode} ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Neon createUserProfile exception: $e');
      return false;
    }
  }

  /// Get user profile by ID.
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    if (!NeonUserConfig.isConfigured) return null;

    try {
      final response = await _client.get(
        _buildUri('/users', {'id': 'eq.$userId', 'select': '*'}),
        headers: _headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data.first as Map<String, dynamic>;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Neon getUserProfile exception: $e');
      return null;
    }
  }

  /// Update user profile.
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    if (!NeonUserConfig.isConfigured) return false;

    // Convert to snake_case for PostgreSQL
    final snakeCaseUpdates = <String, dynamic>{};
    updates.forEach((key, value) {
      snakeCaseUpdates[_toSnakeCase(key)] = value;
    });
    snakeCaseUpdates['last_active_at'] = DateTime.now().toIso8601String();

    try {
      final response = await _client.patch(
        _buildUri('/users', {'id': 'eq.$userId'}),
        headers: {..._headers, 'Prefer': 'return=minimal'},
        body: jsonEncode(snakeCaseUpdates),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Neon updateUserProfile exception: $e');
      return false;
    }
  }

  /// Update last active timestamp.
  Future<void> updateLastActive(String userId) async {
    await updateUserProfile(userId, {'lastActiveAt': DateTime.now().toIso8601String()});
  }

  // ============================================================
  // FOLLOWERS / FOLLOWING
  // ============================================================

  /// Follow a user.
  Future<bool> followUser(String followerId, String followingId) async {
    if (!NeonUserConfig.isConfigured) return false;

    try {
      final response = await _client.post(
        _buildUri('/user_follows'),
        headers: {..._headers, 'Prefer': 'return=minimal'},
        body: jsonEncode([
          {
            'follower_id': followerId,
            'following_id': followingId,
            'created_at': DateTime.now().toIso8601String(),
          }
        ]),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Update counts
        await _incrementFollowersCount(followingId);
        await _incrementFollowingCount(followerId);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Neon followUser exception: $e');
      return false;
    }
  }

  /// Unfollow a user.
  Future<bool> unfollowUser(String followerId, String followingId) async {
    if (!NeonUserConfig.isConfigured) return false;

    try {
      final response = await _client.delete(
        _buildUri('/user_follows', {
          'follower_id': 'eq.$followerId',
          'following_id': 'eq.$followingId',
        }),
        headers: _headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _decrementFollowersCount(followingId);
        await _decrementFollowingCount(followerId);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Neon unfollowUser exception: $e');
      return false;
    }
  }

  /// Check if user A follows user B.
  Future<bool> isFollowing(String followerId, String followingId) async {
    if (!NeonUserConfig.isConfigured) return false;

    try {
      final response = await _client.get(
        _buildUri('/user_follows', {
          'follower_id': 'eq.$followerId',
          'following_id': 'eq.$followingId',
          'select': 'id',
        }),
        headers: _headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.isNotEmpty;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get followers list.
  Future<List<Map<String, dynamic>>> getFollowers(String userId, {int limit = 50}) async {
    if (!NeonUserConfig.isConfigured) return [];

    try {
      final response = await _client.get(
        _buildUri('/user_follows', {
          'following_id': 'eq.$userId',
          'select': 'follower:users!follower_id(id,display_name,photo_url,avatar_emoji)',
          'limit': '$limit',
        }),
        headers: _headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e['follower'] as Map<String, dynamic>).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Neon getFollowers exception: $e');
      return [];
    }
  }

  /// Get following list.
  Future<List<Map<String, dynamic>>> getFollowing(String userId, {int limit = 50}) async {
    if (!NeonUserConfig.isConfigured) return [];

    try {
      final response = await _client.get(
        _buildUri('/user_follows', {
          'follower_id': 'eq.$userId',
          'select': 'following:users!following_id(id,display_name,photo_url,avatar_emoji)',
          'limit': '$limit',
        }),
        headers: _headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e['following'] as Map<String, dynamic>).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Neon getFollowing exception: $e');
      return [];
    }
  }

  // ============================================================
  // FAVORITES & SAVED RECIPES
  // ============================================================

  /// Save a recipe to favorites.
  Future<bool> saveRecipe(String userId, String recipeId) async {
    if (!NeonUserConfig.isConfigured) return false;

    try {
      final response = await _client.post(
        _buildUri('/user_saved_recipes'),
        headers: {..._headers, 'Prefer': 'return=minimal'},
        body: jsonEncode([
          {
            'user_id': userId,
            'recipe_id': recipeId,
            'saved_at': DateTime.now().toIso8601String(),
          }
        ]),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Neon saveRecipe exception: $e');
      return false;
    }
  }

  /// Remove a recipe from favorites.
  Future<bool> unsaveRecipe(String userId, String recipeId) async {
    if (!NeonUserConfig.isConfigured) return false;

    try {
      final response = await _client.delete(
        _buildUri('/user_saved_recipes', {
          'user_id': 'eq.$userId',
          'recipe_id': 'eq.$recipeId',
        }),
        headers: _headers,
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Neon unsaveRecipe exception: $e');
      return false;
    }
  }

  /// Get saved recipes.
  Future<List<String>> getSavedRecipeIds(String userId) async {
    if (!NeonUserConfig.isConfigured) return [];

    try {
      final response = await _client.get(
        _buildUri('/user_saved_recipes', {
          'user_id': 'eq.$userId',
          'select': 'recipe_id',
          'order': 'saved_at.desc',
        }),
        headers: _headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e['recipe_id'] as String).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Neon getSavedRecipeIds exception: $e');
      return [];
    }
  }

  // ============================================================
  // GAMIFICATION: XP, LEVELS, STREAKS
  // ============================================================

  /// Add XP to user and check for level up.
  Future<Map<String, dynamic>?> addXP(String userId, int amount) async {
    if (!NeonUserConfig.isConfigured) return null;

    try {
      // Get current user data
      final profile = await getUserProfile(userId);
      if (profile == null) return null;

      final currentXP = profile['xp'] as int? ?? 0;
      final currentLevel = profile['level'] as int? ?? 1;
      final newXP = currentXP + amount;

      // Calculate new level (simple formula: level = sqrt(xp / 100) + 1)
      final newLevel = (newXP / 100).floor() + 1;
      final leveledUp = newLevel > currentLevel;

      await updateUserProfile(userId, {
        'xp': newXP,
        'level': newLevel,
      });

      return {
        'previousXP': currentXP,
        'newXP': newXP,
        'previousLevel': currentLevel,
        'newLevel': newLevel,
        'leveledUp': leveledUp,
      };
    } catch (e) {
      debugPrint('Neon addXP exception: $e');
      return null;
    }
  }

  /// Update streak.
  Future<int> updateStreak(String userId) async {
    if (!NeonUserConfig.isConfigured) return 0;

    try {
      final profile = await getUserProfile(userId);
      if (profile == null) return 0;

      final lastActive = DateTime.tryParse(profile['last_active_at'] ?? '');
      final currentStreak = profile['streak_days'] as int? ?? 0;

      final now = DateTime.now();
      int newStreak;

      if (lastActive == null) {
        newStreak = 1;
      } else {
        final daysDiff = now.difference(lastActive).inDays;
        if (daysDiff == 0) {
          // Same day, no change
          newStreak = currentStreak;
        } else if (daysDiff == 1) {
          // Consecutive day
          newStreak = currentStreak + 1;
        } else {
          // Streak broken
          newStreak = 1;
        }
      }

      await updateUserProfile(userId, {'streakDays': newStreak});
      return newStreak;
    } catch (e) {
      debugPrint('Neon updateStreak exception: $e');
      return 0;
    }
  }

  // ============================================================
  // ACHIEVEMENTS & BADGES
  // ============================================================

  /// Award a badge to user.
  Future<bool> awardBadge(String userId, String badgeId) async {
    if (!NeonUserConfig.isConfigured) return false;

    try {
      final response = await _client.post(
        _buildUri('/user_badges'),
        headers: {..._headers, 'Prefer': 'return=minimal'},
        body: jsonEncode([
          {
            'user_id': userId,
            'badge_id': badgeId,
            'awarded_at': DateTime.now().toIso8601String(),
          }
        ]),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Neon awardBadge exception: $e');
      return false;
    }
  }

  /// Get user badges.
  Future<List<String>> getUserBadges(String userId) async {
    if (!NeonUserConfig.isConfigured) return [];

    try {
      final response = await _client.get(
        _buildUri('/user_badges', {
          'user_id': 'eq.$userId',
          'select': 'badge_id',
        }),
        headers: _headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e['badge_id'] as String).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Neon getUserBadges exception: $e');
      return [];
    }
  }

  // ============================================================
  // USER PREFERENCES
  // ============================================================

  /// Save user preferences.
  Future<bool> savePreferences(String userId, Map<String, dynamic> preferences) async {
    if (!NeonUserConfig.isConfigured) return false;

    try {
      final response = await _client.post(
        _buildUri('/user_preferences', {'on_conflict': 'user_id'}),
        headers: {..._headers, 'Prefer': 'resolution=merge-duplicates'},
        body: jsonEncode([
          {
            'user_id': userId,
            'preferences': preferences,
            'updated_at': DateTime.now().toIso8601String(),
          }
        ]),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Neon savePreferences exception: $e');
      return false;
    }
  }

  /// Get user preferences.
  Future<Map<String, dynamic>?> getPreferences(String userId) async {
    if (!NeonUserConfig.isConfigured) return null;

    try {
      final response = await _client.get(
        _buildUri('/user_preferences', {
          'user_id': 'eq.$userId',
          'select': 'preferences',
        }),
        headers: _headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data.first['preferences'] as Map<String, dynamic>?;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Neon getPreferences exception: $e');
      return null;
    }
  }

  // ============================================================
  // COOKING HISTORY
  // ============================================================

  /// Log a cooked recipe.
  Future<bool> logCookedRecipe(String userId, String recipeId, {int? rating, String? notes}) async {
    if (!NeonUserConfig.isConfigured) return false;

    try {
      final response = await _client.post(
        _buildUri('/cooking_history'),
        headers: {..._headers, 'Prefer': 'return=minimal'},
        body: jsonEncode([
          {
            'user_id': userId,
            'recipe_id': recipeId,
            'cooked_at': DateTime.now().toIso8601String(),
            'rating': rating,
            'notes': notes,
          }
        ]),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Increment recipes count
        await _incrementRecipesCount(userId);
        // Add XP for cooking
        await addXP(userId, 10);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Neon logCookedRecipe exception: $e');
      return false;
    }
  }

  /// Get cooking history.
  Future<List<Map<String, dynamic>>> getCookingHistory(String userId, {int limit = 50}) async {
    if (!NeonUserConfig.isConfigured) return [];

    try {
      final response = await _client.get(
        _buildUri('/cooking_history', {
          'user_id': 'eq.$userId',
          'select': '*',
          'order': 'cooked_at.desc',
          'limit': '$limit',
        }),
        headers: _headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }

      return [];
    } catch (e) {
      debugPrint('Neon getCookingHistory exception: $e');
      return [];
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  String _toSnakeCase(String input) {
    return input.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }

  Future<void> _incrementFollowersCount(String userId) async {
    // Use PostgreSQL RPC for atomic increment
    await _client.post(
      _buildUri('/rpc/increment_followers'),
      headers: _headers,
      body: jsonEncode({'user_id': userId}),
    );
  }

  Future<void> _decrementFollowersCount(String userId) async {
    await _client.post(
      _buildUri('/rpc/decrement_followers'),
      headers: _headers,
      body: jsonEncode({'user_id': userId}),
    );
  }

  Future<void> _incrementFollowingCount(String userId) async {
    await _client.post(
      _buildUri('/rpc/increment_following'),
      headers: _headers,
      body: jsonEncode({'user_id': userId}),
    );
  }

  Future<void> _decrementFollowingCount(String userId) async {
    await _client.post(
      _buildUri('/rpc/decrement_following'),
      headers: _headers,
      body: jsonEncode({'user_id': userId}),
    );
  }

  Future<void> _incrementRecipesCount(String userId) async {
    await _client.post(
      _buildUri('/rpc/increment_recipes_count'),
      headers: _headers,
      body: jsonEncode({'user_id': userId}),
    );
  }
}

/// Singleton instance
final userNeonService = UserNeonService();
