import 'package:cloud_firestore/cloud_firestore.dart';

/// Canonical Firebase persistence for profile and social data.
class UserFirestoreService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> _user(String id) =>
      _db.collection('users').doc(id);
  Future<Map<String, dynamic>?> getUserProfile(String id) async =>
      (await _user(id).get()).data();
  Future<bool> updateUserProfile(String id, Map<String, dynamic> values) async {
    await _user(id).set(
        {...values, 'lastActiveAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true));
    return true;
  }

  Future<bool> followUser(String id, String target) async {
    final batch = _db.batch();
    batch.set(
        _user(id),
        {
          'following': FieldValue.arrayUnion([target])
        },
        SetOptions(merge: true));
    batch.set(
        _user(target),
        {
          'followers': FieldValue.arrayUnion([id])
        },
        SetOptions(merge: true));
    await batch.commit();
    return true;
  }

  Future<bool> unfollowUser(String id, String target) async {
    final batch = _db.batch();
    batch.set(
        _user(id),
        {
          'following': FieldValue.arrayRemove([target])
        },
        SetOptions(merge: true));
    batch.set(
        _user(target),
        {
          'followers': FieldValue.arrayRemove([id])
        },
        SetOptions(merge: true));
    await batch.commit();
    return true;
  }

  Future<bool> isFollowing(String id, String target) async => List<String>.from(
          (await _user(id).get()).data()?['following'] ?? const [])
      .contains(target);
  Future<List<Map<String, dynamic>>> _people(List<String> ids) async {
    if (ids.isEmpty) return [];
    final result = <Map<String, dynamic>>[];
    for (var start = 0; start < ids.length; start += 10) {
      final chunk =
          ids.sublist(start, start + 10 > ids.length ? ids.length : start + 10);
      final query = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      result.addAll(query.docs.map((d) => {'id': d.id, ...d.data()}));
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getFollowers(String id) async =>
      _people(List<String>.from(
          (await _user(id).get()).data()?['followers'] ?? const []));
  Future<List<Map<String, dynamic>>> getFollowing(String id) async =>
      _people(List<String>.from(
          (await _user(id).get()).data()?['following'] ?? const []));
  Future<bool> saveRecipe(String id, String recipeId) async {
    await _user(id).set({
      'savedRecipes': FieldValue.arrayUnion([recipeId])
    }, SetOptions(merge: true));
    return true;
  }

  Future<bool> unsaveRecipe(String id, String recipeId) async {
    await _user(id).set({
      'savedRecipes': FieldValue.arrayRemove([recipeId])
    }, SetOptions(merge: true));
    return true;
  }

  Future<List<String>> getSavedRecipeIds(String id) async => List<String>.from(
      (await _user(id).get()).data()?['savedRecipes'] ?? const []);
  Future<Map<String, dynamic>?> addXP(String id, int amount) async {
    await _user(id).update({'xp': FieldValue.increment(amount)});
    return getUserProfile(id);
  }

  Future<bool> updateStreak(String id) async => true;
  Future<bool> logCookedRecipe(String id, String recipeId,
      {int? rating, String? notes}) async {
    await _user(id).collection('cookingHistory').add({
      'recipeId': recipeId,
      'rating': rating,
      'notes': notes,
      'cookedAt': FieldValue.serverTimestamp()
    });
    return true;
  }

  Future<List<Map<String, dynamic>>> getCookingHistory(String id) async =>
      (await _user(id)
              .collection('cookingHistory')
              .orderBy('cookedAt', descending: true)
              .get())
          .docs
          .map((d) => d.data())
          .toList();
  Future<List<String>> getUserBadges(String id) async =>
      List<String>.from((await _user(id).get()).data()?['badges'] ?? const []);
  Future<bool> savePreferences(String id, Map<String, dynamic> values) async {
    await _user(id).set({'preferences': values}, SetOptions(merge: true));
    return true;
  }

  Future<Map<String, dynamic>?> getPreferences(String id) async =>
      ((await _user(id).get()).data()?['preferences'] as Map?)
          ?.cast<String, dynamic>();
}

final userFirestoreService = UserFirestoreService();
