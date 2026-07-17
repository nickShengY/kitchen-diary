import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart' show firebaseInitialized;
import '../models/user_model.dart';
import '../services/user_firestore_service.dart';

class UserProvider extends ChangeNotifier {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  final UserFirestoreService _profiles = userFirestoreService;
  UserModel? _viewedUser;
  Map<String, dynamic>? _viewedUserProfile;
  List<UserModel> _searchResults = [], _topChefs = [];
  bool _isLoading = false;
  UserModel? get viewedUser => _viewedUser;
  Map<String, dynamic>? get viewedUserProfile => _viewedUserProfile;
  List<UserModel> get searchResults => _searchResults;
  List<UserModel> get topChefs => _topChefs;
  bool get isLoading => _isLoading;
  int get viewedUserXP => _viewedUserProfile?['xp'] as int? ?? 0;
  int get viewedUserLevel => _viewedUserProfile?['level'] as int? ?? 1;
  int get viewedUserStreak => _viewedUserProfile?['streakDays'] as int? ?? 0;
  int get viewedUserFollowersCount =>
      (_viewedUserProfile?['followers'] as List?)?.length ?? 0;
  int get viewedUserFollowingCount =>
      (_viewedUserProfile?['following'] as List?)?.length ?? 0;
  Future<UserModel?> getUser(String id) async {
    if (!firebaseInitialized) return null;
    _isLoading = true;
    notifyListeners();
    try {
      final doc = await _db.collection('users').doc(id).get();
      _viewedUser = doc.exists ? UserModel.fromFirestore(doc) : null;
      _viewedUserProfile = await _profiles.getUserProfile(id);
      return _viewedUser;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> isFollowingViewedUser(String id) async =>
      _viewedUser != null && await _profiles.isFollowing(id, _viewedUser!.id);
  Future<List<Map<String, dynamic>>> getViewedUserFollowers() async =>
      _viewedUser == null ? [] : await _profiles.getFollowers(_viewedUser!.id);
  Future<List<Map<String, dynamic>>> getViewedUserFollowing() async =>
      _viewedUser == null ? [] : await _profiles.getFollowing(_viewedUser!.id);
  Future<List<Map<String, dynamic>>> getViewedUserCookingHistory() async =>
      _viewedUser == null
          ? []
          : await _profiles.getCookingHistory(_viewedUser!.id);
  Future<List<String>> getViewedUserBadges() async =>
      _viewedUser == null ? [] : await _profiles.getUserBadges(_viewedUser!.id);
  Future<void> searchUsers(String query) async {
    if (query.isEmpty || !firebaseInitialized) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    final data = await _db
        .collection('users')
        .orderBy('displayName')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(20)
        .get();
    _searchResults = data.docs.map(UserModel.fromFirestore).toList();
    notifyListeners();
  }

  Future<void> loadTopChefs() async {
    if (!firebaseInitialized) return;
    final data = await _db
        .collection('users')
        .orderBy('recipesCount', descending: true)
        .limit(10)
        .get();
    _topChefs = data.docs.map(UserModel.fromFirestore).toList();
    notifyListeners();
  }

  Future<bool> updateUserProfile(String id, Map<String, dynamic> data) =>
      _profiles.updateUserProfile(id, data);
  Future<List<UserModel>> _people(List<Map<String, dynamic>> records) async =>
      records
          .map((data) => UserModel(
              id: data['id'] as String? ?? '',
              email: data['email'] as String? ?? '',
              displayName: data['displayName'] as String? ?? 'Chef',
              photoUrl: data['photoUrl'] as String?,
              bio: data['bio'] as String?,
              avatarEmoji: data['avatarEmoji'] as String? ?? '🍳',
              followers: List<String>.from(data['followers'] ?? const []),
              following: List<String>.from(data['following'] ?? const []),
              savedRecipes: List<String>.from(data['savedRecipes'] ?? const []),
              favoriteRecipes:
                  List<String>.from(data['favoriteRecipes'] ?? const []),
              badges: List<String>.from(data['badges'] ?? const []),
              recipesCount: data['recipesCount'] as int? ?? 0,
              likesReceived: data['likesReceived'] as int? ?? 0,
              createdAt:
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate() ??
                  DateTime.now()))
          .toList();
  Future<List<UserModel>> getFollowers(String id) async =>
      _people(await _profiles.getFollowers(id));
  Future<List<UserModel>> getFollowing(String id) async =>
      _people(await _profiles.getFollowing(id));
  void clearViewedUser() {
    _viewedUser = null;
    _viewedUserProfile = null;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }
}
