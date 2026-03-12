import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../main.dart' show firebaseInitialized;
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../services/user_neon_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = authService;
  final UserNeonService _neonService = userNeonService;

  AuthStatus _status = AuthStatus.initial;
  User? _firebaseUser;
  UserModel? _userModel;
  Map<String, dynamic>? _neonProfile;
  String? _errorMessage;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserModel?>? _userSubscription;

  AuthStatus get status => _status;
  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _userModel;
  Map<String, dynamic>? get neonProfile => _neonProfile;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isVip => _userModel?.hasValidVip ?? false;

  int get xp => _neonProfile?['xp'] as int? ?? 0;
  int get level => _neonProfile?['level'] as int? ?? 1;
  int get streakDays => _neonProfile?['streak_days'] as int? ?? 0;
  int get followersCount => _neonProfile?['followers_count'] as int? ?? 0;
  int get followingCount => _neonProfile?['following_count'] as int? ?? 0;

  AuthProvider() {
    _init();
  }

  void _init() {
    if (firebaseInitialized) {
      _authSubscription =
          _authService.authStateChanges.listen(_onAuthStateChanged);
      return;
    }

    _status = AuthStatus.unauthenticated;
    _errorMessage =
        'Authentication is unavailable because Firebase is not configured.';
    notifyListeners();
  }

  void _onAuthStateChanged(User? user) async {
    _firebaseUser = user;

    if (user != null) {
      _userSubscription?.cancel();
      _userSubscription =
          _authService.streamUserDocument(user.uid).listen(_onUserDocumentChanged);

      await _syncNeonProfile(user.uid);
      await _neonService.updateStreak(user.uid);
      subscriptionService.loginUser(user.uid);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
    } else {
      _userModel = null;
      _neonProfile = null;
      _status = AuthStatus.unauthenticated;
      subscriptionService.logoutUser();
    }

    notifyListeners();
  }

  Future<void> _syncNeonProfile(String userId) async {
    try {
      _neonProfile = await _neonService.getUserProfile(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error syncing Neon profile: $e');
    }
  }

  Future<void> refreshNeonProfile() async {
    if (_firebaseUser != null) {
      await _syncNeonProfile(_firebaseUser!.uid);
    }
  }

  void _onUserDocumentChanged(UserModel? userModel) {
    _userModel = userModel;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    try {
      if (!firebaseInitialized) {
        _errorMessage =
            'Google sign-in is unavailable because Firebase is not configured.';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }

      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final result = await _authService.signInWithGoogle();
      if (result == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithEmailPassword(String email, String password) async {
    try {
      if (!firebaseInitialized) {
        _errorMessage =
            'Email sign-in is unavailable because Firebase is not configured.';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }

      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      await _authService.signInWithEmailPassword(email, password);
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithEmailPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      if (!firebaseInitialized) {
        _errorMessage =
            'Registration is unavailable because Firebase is not configured.';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }

      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      await _authService.registerWithEmailPassword(
        email,
        password,
        displayName,
      );
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();
      await _authService.signOut();
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _status = AuthStatus.error;
      notifyListeners();
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    String? displayName,
    String? photoUrl,
    String? bio,
    String? avatarEmoji,
  }) async {
    try {
      if (_firebaseUser == null) return false;

      await _authService.updateProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );

      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (bio != null) updates['bio'] = bio;
      if (avatarEmoji != null) updates['avatarEmoji'] = avatarEmoji;

      if (updates.isNotEmpty) {
        await _neonService.updateUserProfile(_firebaseUser!.uid, updates);
        await _syncNeonProfile(_firebaseUser!.uid);
      }

      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> addXP(int amount) async {
    if (_firebaseUser == null) return null;

    final result = await _neonService.addXP(_firebaseUser!.uid, amount);
    if (result != null) {
      await _syncNeonProfile(_firebaseUser!.uid);
    }
    return result;
  }

  Future<bool> followUser(String targetUserId) async {
    if (_firebaseUser == null) return false;

    final success =
        await _neonService.followUser(_firebaseUser!.uid, targetUserId);
    if (success) {
      await _syncNeonProfile(_firebaseUser!.uid);
    }
    return success;
  }

  Future<bool> unfollowUser(String targetUserId) async {
    if (_firebaseUser == null) return false;

    final success =
        await _neonService.unfollowUser(_firebaseUser!.uid, targetUserId);
    if (success) {
      await _syncNeonProfile(_firebaseUser!.uid);
    }
    return success;
  }

  Future<bool> isFollowing(String targetUserId) async {
    if (_firebaseUser == null) return false;
    return _neonService.isFollowing(_firebaseUser!.uid, targetUserId);
  }

  Future<List<Map<String, dynamic>>> getFollowers() async {
    if (_firebaseUser == null) return [];
    return _neonService.getFollowers(_firebaseUser!.uid);
  }

  Future<List<Map<String, dynamic>>> getFollowing() async {
    if (_firebaseUser == null) return [];
    return _neonService.getFollowing(_firebaseUser!.uid);
  }

  Future<bool> saveRecipe(String recipeId) async {
    if (_firebaseUser == null) return false;
    return _neonService.saveRecipe(_firebaseUser!.uid, recipeId);
  }

  Future<bool> unsaveRecipe(String recipeId) async {
    if (_firebaseUser == null) return false;
    return _neonService.unsaveRecipe(_firebaseUser!.uid, recipeId);
  }

  Future<List<String>> getSavedRecipeIds() async {
    if (_firebaseUser == null) return [];
    return _neonService.getSavedRecipeIds(_firebaseUser!.uid);
  }

  Future<bool> logCookedRecipe(
    String recipeId, {
    int? rating,
    String? notes,
  }) async {
    if (_firebaseUser == null) return false;

    final success = await _neonService.logCookedRecipe(
      _firebaseUser!.uid,
      recipeId,
      rating: rating,
      notes: notes,
    );

    if (success) {
      await _syncNeonProfile(_firebaseUser!.uid);
    }
    return success;
  }

  Future<List<Map<String, dynamic>>> getCookingHistory() async {
    if (_firebaseUser == null) return [];
    return _neonService.getCookingHistory(_firebaseUser!.uid);
  }

  Future<List<String>> getUserBadges() async {
    if (_firebaseUser == null) return [];
    return _neonService.getUserBadges(_firebaseUser!.uid);
  }

  Future<bool> savePreferences(Map<String, dynamic> preferences) async {
    if (_firebaseUser == null) return false;
    return _neonService.savePreferences(_firebaseUser!.uid, preferences);
  }

  Future<Map<String, dynamic>?> getPreferences() async {
    if (_firebaseUser == null) return null;
    return _neonService.getPreferences(_firebaseUser!.uid);
  }

  Future<bool> deleteAccount() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();
      await _authService.deleteAccount();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = _firebaseUser != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password should be at least 6 characters.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled.';
        case 'network-request-failed':
          return 'Network error. Please check your connection.';
        default:
          return 'An error occurred. Please try again.';
      }
    }
    return error.toString();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }
}
