import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Lazy initialization of GoogleSignIn to avoid crash on web without client ID
  GoogleSignIn? _googleSignIn;
  bool _googleSignInInitialized = false;

  GoogleSignIn? get googleSignIn {
    if (!_googleSignInInitialized) {
      _googleSignInInitialized = true;
      // On web, GoogleSignIn requires a client ID configured via meta tag or parameter
      // Skip initialization if not configured to avoid assertion errors
      if (kIsWeb) {
        // For web, only initialize if we have a proper OAuth client ID configured
        // For now, skip Google Sign-In on web in demo mode
        debugPrint('Google Sign-In skipped on web (no client ID configured)');
        _googleSignIn = null;
      } else {
        try {
          _googleSignIn = GoogleSignIn();
        } catch (e) {
          debugPrint('Google Sign-In not available: $e');
          _googleSignIn = null;
        }
      }
    }
    return _googleSignIn;
  }

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Check if Google Sign-In is available
      final gSignIn = googleSignIn;
      if (gSignIn == null) {
        debugPrint('Google Sign-In not configured');
        return null;
      }

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await gSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Create or update user document in Firestore
      await _createOrUpdateUserDocument(userCredential.user!);

      return userCredential;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await googleSignIn?.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }
        if (photoUrl != null) {
          await user.updatePhotoURL(photoUrl);
        }

        // Update Firestore document
        await _firestore.collection('users').doc(user.uid).update({
          if (displayName != null) 'displayName': displayName,
          if (photoUrl != null) 'photoUrl': photoUrl,
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user document
        await _firestore.collection('users').doc(user.uid).delete();

        // Delete user recipes (or mark as deleted)
        final recipesQuery = await _firestore
            .collection('recipes')
            .where('authorId', isEqualTo: user.uid)
            .get();

        for (var doc in recipesQuery.docs) {
          await doc.reference.delete();
        }

        // Delete the user account
        await user.delete();
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }

  // Get user document
  Future<UserModel?> getUserDocument(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user document: $e');
      return null;
    }
  }

  // Stream user document
  Stream<UserModel?> streamUserDocument(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Create or update user document
  Future<void> _createOrUpdateUserDocument(
    User user, {
    String? displayName,
  }) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    final avatarEmoji = _getRandomAvatarEmoji();
    final name = displayName ?? user.displayName ?? 'Chef';

    if (!docSnapshot.exists) {
      // Create new user document in Firestore
      final now = DateTime.now();
      final userData = UserModel(
        id: user.uid,
        email: user.email ?? '',
        displayName: name,
        photoUrl: user.photoURL,
        avatarEmoji: avatarEmoji,
        createdAt: now,
        lastActiveAt: now,
      );

      await userDoc.set(userData.toFirestore());
    } else {
      // Update last active timestamp
      await _updateLastActive(user.uid);
    }
  }

  // Update last active timestamp
  Future<void> _updateLastActive(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
  }

  // Get random avatar emoji for new users
  String _getRandomAvatarEmoji() {
    final emojis = [
      '👨‍🍳',
      '👩‍🍳',
      '🧑‍🍳',
      '🍳',
      '🥘',
      '🍲',
      '🥗',
      '🍝',
      '🍜',
      '🍛',
      '🍕',
      '🍔',
      '🌮',
      '🥙',
      '🧁',
      '🍰',
    ];
    return emojis[DateTime.now().millisecond % emojis.length];
  }

  // Re-authenticate user (needed for sensitive operations)
  Future<bool> reauthenticateWithGoogle() async {
    try {
      final gSignIn = googleSignIn;
      if (gSignIn == null) return false;

      final googleUser = await gSignIn.signIn();
      if (googleUser == null) return false;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.currentUser?.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      debugPrint('Error reauthenticating: $e');
      return false;
    }
  }
}

// Singleton instance
final authService = AuthService();
