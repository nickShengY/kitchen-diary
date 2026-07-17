import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../main.dart' show firebaseInitialized;
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_firestore_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = authService;
  final UserFirestoreService _profileService = userFirestoreService;
  AuthStatus _status = AuthStatus.initial;
  User? _firebaseUser;
  UserModel? _userModel;
  Map<String, dynamic>? _profile;
  String? _errorMessage;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserModel?>? _userSubscription;
  AuthStatus get status => _status;
  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _userModel;
  Map<String, dynamic>? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isVip => _userModel?.hasValidVip ?? false;
  int get xp => _profile?['xp'] as int? ?? 0;
  int get level => _profile?['level'] as int? ?? 1;
  int get streakDays => _profile?['streakDays'] as int? ?? 0;
  int get followersCount => (_profile?['followers'] as List?)?.length ?? 0;
  int get followingCount => (_profile?['following'] as List?)?.length ?? 0;
  AuthProvider() {
    if (firebaseInitialized) {
      _authSubscription =
          _authService.authStateChanges.listen(_onAuthStateChanged);
    } else {
      _status = AuthStatus.unauthenticated;
      _errorMessage =
          'Authentication is unavailable because Firebase is not configured.';
    }
  }
  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    if (user == null) {
      _userModel = null;
      _profile = null;
      _status = AuthStatus.unauthenticated;
    } else {
      _userSubscription?.cancel();
      _userSubscription =
          _authService.streamUserDocument(user.uid).listen((value) {
        _userModel = value;
        notifyListeners();
      });
      _profile = await _profileService.getUserProfile(user.uid);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
    }
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    if (!firebaseInitialized) {
      _status = AuthStatus.error;
      _errorMessage =
          'Google sign-in is unavailable because Firebase is not configured.';
      notifyListeners();
      return false;
    }
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();
      final result = await _authService.signInWithGoogle();
      if (result == null) _status = AuthStatus.unauthenticated;
      notifyListeners();
      return result != null;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _message(e);
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
      _status = AuthStatus.error;
      _errorMessage = _message(e);
      notifyListeners();
    }
  }

  Future<bool> updateProfile(
      {String? displayName,
      String? photoUrl,
      String? bio,
      String? avatarEmoji}) async {
    if (_firebaseUser == null) return false;
    try {
      await _authService.updateProfile(
          displayName: displayName, photoUrl: photoUrl);
      final values = <String, dynamic>{
        if (displayName != null) 'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (bio != null) 'bio': bio,
        if (avatarEmoji != null) 'avatarEmoji': avatarEmoji
      };
      if (values.isNotEmpty)
        _profile = (await _profileService.updateUserProfile(
                _firebaseUser!.uid, values))
            ? await _profileService.getUserProfile(_firebaseUser!.uid)
            : _profile;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _message(e);
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> addXP(int amount) async {
    if (_firebaseUser == null) return null;
    _profile = await _profileService.addXP(_firebaseUser!.uid, amount);
    notifyListeners();
    return _profile;
  }

  Future<bool> followUser(String id) async =>
      _firebaseUser != null &&
      await _profileService.followUser(_firebaseUser!.uid, id);
  Future<bool> unfollowUser(String id) async =>
      _firebaseUser != null &&
      await _profileService.unfollowUser(_firebaseUser!.uid, id);
  Future<bool> isFollowing(String id) async =>
      _firebaseUser != null &&
      await _profileService.isFollowing(_firebaseUser!.uid, id);
  Future<List<Map<String, dynamic>>> getFollowers() async =>
      _firebaseUser == null
          ? []
          : await _profileService.getFollowers(_firebaseUser!.uid);
  Future<List<Map<String, dynamic>>> getFollowing() async =>
      _firebaseUser == null
          ? []
          : await _profileService.getFollowing(_firebaseUser!.uid);
  Future<bool> saveRecipe(String id) async =>
      _firebaseUser != null &&
      await _profileService.saveRecipe(_firebaseUser!.uid, id);
  Future<bool> unsaveRecipe(String id) async =>
      _firebaseUser != null &&
      await _profileService.unsaveRecipe(_firebaseUser!.uid, id);
  Future<List<String>> getSavedRecipeIds() async => _firebaseUser == null
      ? []
      : await _profileService.getSavedRecipeIds(_firebaseUser!.uid);
  Future<bool> logCookedRecipe(String id, {int? rating, String? notes}) async =>
      _firebaseUser != null &&
      await _profileService.logCookedRecipe(_firebaseUser!.uid, id,
          rating: rating, notes: notes);
  Future<List<Map<String, dynamic>>> getCookingHistory() async =>
      _firebaseUser == null
          ? []
          : await _profileService.getCookingHistory(_firebaseUser!.uid);
  Future<List<String>> getUserBadges() async => _firebaseUser == null
      ? []
      : await _profileService.getUserBadges(_firebaseUser!.uid);
  Future<bool> savePreferences(Map<String, dynamic> values) async =>
      _firebaseUser != null &&
      await _profileService.savePreferences(_firebaseUser!.uid, values);
  Future<Map<String, dynamic>?> getPreferences() async => _firebaseUser == null
      ? null
      : _profileService.getPreferences(_firebaseUser!.uid);
  Future<bool> deleteAccount() async {
    try {
      await _authService.deleteAccount();
      return true;
    } catch (e) {
      _errorMessage = _message(e);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error)
      _status = _firebaseUser == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated;
    notifyListeners();
  }

  String _message(Object e) => e is FirebaseAuthException
      ? 'Google sign-in failed: ${e.message ?? e.code}'
      : e.toString();
  @override
  void dispose() {
    _authSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }
}
