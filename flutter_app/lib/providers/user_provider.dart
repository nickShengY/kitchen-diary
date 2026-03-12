import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart' show firebaseInitialized;
import '../models/user_model.dart';
import '../services/user_neon_service.dart';

class UserProvider extends ChangeNotifier {
  FirebaseFirestore? _firestoreInstance;
  final UserNeonService _neonService = userNeonService;

  FirebaseFirestore get _firestore {
    _firestoreInstance ??= FirebaseFirestore.instance;
    return _firestoreInstance!;
  }

  UserModel? _viewedUser;
  Map<String, dynamic>? _viewedUserNeonProfile; // Extended data from Neon
  List<UserModel> _searchResults = [];
  List<UserModel> _topChefs = [];
  bool _isLoading = false;

  UserModel? get viewedUser => _viewedUser;
  Map<String, dynamic>? get viewedUserNeonProfile => _viewedUserNeonProfile;
  List<UserModel> get searchResults => _searchResults;
  List<UserModel> get topChefs => _topChefs;
  bool get isLoading => _isLoading;

  // Extended Neon profile getters for viewed user
  int get viewedUserXP => _viewedUserNeonProfile?['xp'] as int? ?? 0;
  int get viewedUserLevel => _viewedUserNeonProfile?['level'] as int? ?? 1;
  int get viewedUserStreak =>
      _viewedUserNeonProfile?['streak_days'] as int? ?? 0;
  int get viewedUserFollowersCount =>
      _viewedUserNeonProfile?['followers_count'] as int? ?? 0;
  int get viewedUserFollowingCount =>
      _viewedUserNeonProfile?['following_count'] as int? ?? 0;

  // Get user by ID (Firestore + Neon)
  Future<UserModel?> getUser(String userId) async {
    if (!firebaseInitialized) {
      _isLoading = false;
      _viewedUser = null;
      _viewedUserNeonProfile = null;
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _viewedUserNeonProfile = null;
    notifyListeners();

    try {
      // Get basic profile from Firestore
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        _viewedUser = UserModel.fromFirestore(doc);

        // Also fetch extended profile from Neon
        _viewedUserNeonProfile = await _neonService.getUserProfile(userId);

        _isLoading = false;
        notifyListeners();
        return _viewedUser;
      }
    } catch (e) {
      debugPrint('Error getting user: $e');
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  /// Get only the Neon profile for a user (for quick stats)
  Future<Map<String, dynamic>?> getNeonProfile(String userId) async {
    return await _neonService.getUserProfile(userId);
  }

  /// Check if current user is following the viewed user
  Future<bool> isFollowingViewedUser(String currentUserId) async {
    if (_viewedUser == null) return false;
    return await _neonService.isFollowing(currentUserId, _viewedUser!.id);
  }

  /// Get followers of viewed user
  Future<List<Map<String, dynamic>>> getViewedUserFollowers() async {
    if (_viewedUser == null) return [];
    return await _neonService.getFollowers(_viewedUser!.id);
  }

  /// Get following of viewed user
  Future<List<Map<String, dynamic>>> getViewedUserFollowing() async {
    if (_viewedUser == null) return [];
    return await _neonService.getFollowing(_viewedUser!.id);
  }

  /// Get cooking history of viewed user
  Future<List<Map<String, dynamic>>> getViewedUserCookingHistory() async {
    if (_viewedUser == null) return [];
    return await _neonService.getCookingHistory(_viewedUser!.id);
  }

  /// Get badges of viewed user
  Future<List<String>> getViewedUserBadges() async {
    if (_viewedUser == null) return [];
    return await _neonService.getUserBadges(_viewedUser!.id);
  }

  // Search users
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    if (!firebaseInitialized) {
      _isLoading = false;
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('displayName')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(20)
          .get();

      _searchResults =
          snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load top chefs (users with most followers/recipes)
  Future<void> loadTopChefs() async {
    if (!firebaseInitialized) {
      _topChefs = [];
      notifyListeners();
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('recipesCount', descending: true)
          .limit(10)
          .get();

      _topChefs =
          snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading top chefs: $e');
    }
  }

  // Update user profile (Firestore + Neon)
  Future<bool> updateUserProfile(
      String userId, Map<String, dynamic> data) async {
    if (!firebaseInitialized) {
      return false;
    }

    try {
      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        ...data,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

      // Also update Neon for extended data sync
      await _neonService.updateUserProfile(userId, data);

      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  // Get followers
  Future<List<UserModel>> getFollowers(String userId) async {
    if (!firebaseInitialized) {
      return [];
    }

    try {
      List<String> followerIds = [];

      if (NeonUserConfig.isConfigured) {
        try {
          final neonFollowers = await _neonService.getFollowers(userId);
          followerIds = neonFollowers
              .map((f) => f['id'] as String?)
              .whereType<String>()
              .toList();
        } catch (e) {
          debugPrint('Error getting Neon followers: $e');
        }
      } else {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        followerIds = List<String>.from(userDoc.data()?['followers'] ?? []);
      }

      if (followerIds.isEmpty) return [];

      final chunks = <List<String>>[];
      for (var i = 0; i < followerIds.length; i += 10) {
        chunks.add(followerIds.sublist(
          i,
          i + 10 > followerIds.length ? followerIds.length : i + 10,
        ));
      }

      final List<UserModel> followers = [];
      for (final chunk in chunks) {
        final snapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        followers.addAll(
          snapshot.docs.map((doc) => UserModel.fromFirestore(doc)),
        );
      }

      return followers;
    } catch (e) {
      debugPrint('Error getting followers: $e');
      return [];
    }
  }

  // Get following
  Future<List<UserModel>> getFollowing(String userId) async {
    if (!firebaseInitialized) {
      return [];
    }

    try {
      List<String> followingIds = [];

      if (NeonUserConfig.isConfigured) {
        try {
          final neonFollowing = await _neonService.getFollowing(userId);
          followingIds = neonFollowing
              .map((f) => f['id'] as String?)
              .whereType<String>()
              .toList();
        } catch (e) {
          debugPrint('Error getting Neon following: $e');
        }
      } else {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        followingIds = List<String>.from(userDoc.data()?['following'] ?? []);
      }

      if (followingIds.isEmpty) return [];

      final chunks = <List<String>>[];
      for (var i = 0; i < followingIds.length; i += 10) {
        chunks.add(followingIds.sublist(
          i,
          i + 10 > followingIds.length ? followingIds.length : i + 10,
        ));
      }

      final List<UserModel> following = [];
      for (final chunk in chunks) {
        final snapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        following.addAll(
          snapshot.docs.map((doc) => UserModel.fromFirestore(doc)),
        );
      }

      return following;
    } catch (e) {
      debugPrint('Error getting following: $e');
      return [];
    }
  }

  void clearViewedUser() {
    _viewedUser = null;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }
}
