import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart' show firebaseInitialized;
import '../models/recipe_model.dart';
import '../models/community_model.dart';
import '../services/gemini_service.dart';

class RecipeProvider extends ChangeNotifier {
  FirebaseFirestore? _firestoreInstance;
  final GeminiService _geminiService = geminiService;

  FirebaseFirestore get firestore {
    _firestoreInstance ??= FirebaseFirestore.instance;
    return _firestoreInstance!;
  }

  List<RecipeModel> _recipes = [];
  List<RecipeModel> _userRecipes = [];
  List<RecipeModel> _savedRecipes = [];
  List<RecipeModel> _featuredRecipes = [];
  List<RecipeSuggestion> _aiSuggestions = [];

  RecipeModel? _currentRecipe;
  bool _isLoading = false;
  bool _isSearching = false;
  String? _errorMessage;

  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;

  String? _lastTag;
  String? _lastCuisine;
  RecipeDifficulty? _lastDifficulty;
  MealType? _lastMealType;
  String? _lastSortBy;

  List<RecipeModel> get recipes => _recipes;
  List<RecipeModel> get userRecipes => _userRecipes;
  List<RecipeModel> get savedRecipes => _savedRecipes;
  List<RecipeModel> get featuredRecipes => _featuredRecipes;
  List<RecipeSuggestion> get aiSuggestions => _aiSuggestions;
  RecipeModel? get currentRecipe => _currentRecipe;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  // Load initial recipes
  Future<void> loadRecipes({
    String? tag,
    String? cuisine,
    RecipeDifficulty? difficulty,
    MealType? mealType,
    String? sortBy,
  }) async {
    _lastTag = tag;
    _lastCuisine = cuisine;
    _lastDifficulty = difficulty;
    _lastMealType = mealType;
    _lastSortBy = sortBy;

    if (!firebaseInitialized) {
      _recipes = [];
      _isLoading = false;
      _hasMore = false;
      _errorMessage =
          'Recipes are unavailable because Firebase is not configured.';
      Future.microtask(() => notifyListeners());
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    // Use Future.microtask to avoid calling notifyListeners during build
    Future.microtask(() => notifyListeners());

    try {
      Query query =
          firestore.collection('recipes').where('isPublic', isEqualTo: true);

      if (tag != null) {
        query = query.where('tags', arrayContains: tag);
      }
      if (cuisine != null) {
        query = query.where('cuisine', arrayContains: cuisine);
      }
      if (difficulty != null) {
        query = query.where('difficulty', isEqualTo: difficulty.name);
      }
      if (mealType != null) {
        query = query.where('mealType', isEqualTo: mealType.name);
      }

      // Sort
      switch (sortBy) {
        case 'popular':
          query = query.orderBy('likes', descending: true);
          break;
        case 'recent':
          query = query.orderBy('createdAt', descending: true);
          break;
        case 'views':
          query = query.orderBy('views', descending: true);
          break;
        default:
          query = query.orderBy('createdAt', descending: true);
      }

      query = query.limit(20);

      final snapshot = await query.get();

      _recipes =
          snapshot.docs.map((doc) => RecipeModel.fromFirestore(doc)).toList();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _hasMore = snapshot.docs.length == 20;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      _errorMessage = 'Failed to load recipes';
      debugPrint('Error loading recipes: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load more recipes (pagination)
  Future<void> loadMoreRecipes() async {
    if (!_hasMore || _isLoading || _lastDocument == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      Query query =
          firestore.collection('recipes').where('isPublic', isEqualTo: true);

      final tag = _lastTag;
      final cuisine = _lastCuisine;
      final difficulty = _lastDifficulty;
      final mealType = _lastMealType;
      final sortBy = _lastSortBy;

      if (tag != null) {
        query = query.where('tags', arrayContains: tag);
      }
      if (cuisine != null) {
        query = query.where('cuisine', arrayContains: cuisine);
      }
      if (difficulty != null) {
        query = query.where('difficulty', isEqualTo: difficulty.name);
      }
      if (mealType != null) {
        query = query.where('mealType', isEqualTo: mealType.name);
      }

      switch (sortBy) {
        case 'popular':
          query = query.orderBy('likes', descending: true);
          break;
        case 'views':
          query = query.orderBy('views', descending: true);
          break;
        case 'recent':
        default:
          query = query.orderBy('createdAt', descending: true);
      }

      final snapshot =
          await query.startAfterDocument(_lastDocument!).limit(20).get();

      final newRecipes =
          snapshot.docs.map((doc) => RecipeModel.fromFirestore(doc)).toList();

      _recipes.addAll(newRecipes);

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _hasMore = snapshot.docs.length == 20;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      _errorMessage = 'Failed to load more recipes';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load featured recipes
  Future<void> loadFeaturedRecipes() async {
    if (!firebaseInitialized) {
      _featuredRecipes = [];
      _errorMessage =
          'Featured recipes are unavailable because Firebase is not configured.';
      Future.microtask(() => notifyListeners());
      return;
    }

    try {
      final snapshot = await firestore
          .collection('recipes')
          .where('isFeatured', isEqualTo: true)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      _featuredRecipes =
          snapshot.docs.map((doc) => RecipeModel.fromFirestore(doc)).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading featured recipes: $e');
    }
  }

  // Load user's recipes
  Future<void> loadUserRecipes(String userId) async {
    try {
      final snapshot = await firestore
          .collection('recipes')
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _userRecipes =
          snapshot.docs.map((doc) => RecipeModel.fromFirestore(doc)).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user recipes: $e');
    }
  }

  // Load saved recipes
  Future<void> loadSavedRecipes(List<String> recipeIds) async {
    if (recipeIds.isEmpty) {
      _savedRecipes = [];
      notifyListeners();
      return;
    }

    try {
      // Firestore 'in' query limit is 30
      final chunks = <List<String>>[];
      for (var i = 0; i < recipeIds.length; i += 30) {
        chunks.add(recipeIds.sublist(
          i,
          i + 30 > recipeIds.length ? recipeIds.length : i + 30,
        ));
      }

      _savedRecipes = [];
      for (final chunk in chunks) {
        final snapshot = await firestore
            .collection('recipes')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        _savedRecipes.addAll(
          snapshot.docs.map((doc) => RecipeModel.fromFirestore(doc)),
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved recipes: $e');
    }
  }

  // Get single recipe
  Future<RecipeModel?> getRecipe(String recipeId) async {
    try {
      final doc = await firestore.collection('recipes').doc(recipeId).get();

      if (doc.exists) {
        _currentRecipe = RecipeModel.fromFirestore(doc);

        // Increment view count
        await firestore.collection('recipes').doc(recipeId).update({
          'views': FieldValue.increment(1),
        });

        notifyListeners();
        return _currentRecipe;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting recipe: $e');
      return null;
    }
  }

  // Create recipe
  Future<String?> createRecipe(RecipeModel recipe) async {
    try {
      final docRef = await firestore.collection('recipes').add(
            recipe.toFirestore(),
          );

      // Update user's recipe count
      await firestore.collection('users').doc(recipe.authorId).update({
        'recipesCount': FieldValue.increment(1),
      });

      // Create "new recipe" activities for the author's followers
      try {
        final userDoc =
            await firestore.collection('users').doc(recipe.authorId).get();
        final data = userDoc.data();
        if (data != null) {
          List<String> followers = [];

          followers = List<String>.from(data['followers'] ?? const []);

          final authorName = data['displayName'] as String?;
          final authorAvatar = data['avatarEmoji'] as String?;
          String? targetImage;
          if (recipe.imageUrl != null) {
            targetImage = recipe.imageUrl;
          } else if (recipe.imageUrls.isNotEmpty) {
            targetImage = recipe.imageUrls.first;
          }

          for (final followerId in followers) {
            if (followerId.isEmpty || followerId == recipe.authorId) continue;
            await _createActivity(
              userId: followerId,
              type: ActivityType.newRecipe,
              actorId: recipe.authorId,
              actorName: authorName,
              actorAvatar: authorAvatar,
              targetId: docRef.id,
              targetTitle: recipe.title,
              targetImage: targetImage,
            );
          }
        }
      } catch (e) {
        debugPrint('Error creating new-recipe activities: $e');
      }

      return docRef.id;
    } catch (e) {
      _errorMessage = 'Failed to create recipe';
      notifyListeners();
      return null;
    }
  }

  // Update recipe
  Future<bool> updateRecipe(RecipeModel recipe) async {
    try {
      await firestore.collection('recipes').doc(recipe.id).update(
            recipe.copyWith(updatedAt: DateTime.now()).toFirestore(),
          );

      // Update local list
      final index = _userRecipes.indexWhere((r) => r.id == recipe.id);
      if (index != -1) {
        _userRecipes[index] = recipe;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update recipe';
      notifyListeners();
      return false;
    }
  }

  // Delete recipe
  Future<bool> deleteRecipe(String recipeId, String authorId) async {
    try {
      await firestore.collection('recipes').doc(recipeId).delete();

      // Update user's recipe count
      await firestore.collection('users').doc(authorId).update({
        'recipesCount': FieldValue.increment(-1),
      });

      _userRecipes.removeWhere((r) => r.id == recipeId);
      _recipes.removeWhere((r) => r.id == recipeId);
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete recipe';
      notifyListeners();
      return false;
    }
  }

  // Like/unlike recipe
  Future<void> toggleLike(String recipeId, String userId, bool isLiked) async {
    try {
      final increment = isLiked ? -1 : 1;

      await firestore.collection('recipes').doc(recipeId).update({
        'likes': FieldValue.increment(increment),
      });

      // Update user's liked recipes
      await firestore.collection('users').doc(userId).update({
        'favoriteRecipes': isLiked
            ? FieldValue.arrayRemove([recipeId])
            : FieldValue.arrayUnion([recipeId]),
      });

      // Update local recipe
      final index = _recipes.indexWhere((r) => r.id == recipeId);
      if (index != -1) {
        _recipes[index] = _recipes[index].copyWith(
          likes: _recipes[index].likes + increment,
        );
        notifyListeners();
      }

      // Create activity only when the recipe is newly liked
      if (!isLiked) {
        try {
          final recipeDoc =
              await firestore.collection('recipes').doc(recipeId).get();
          final data = recipeDoc.data();
          if (data != null) {
            final authorId = data['authorId'] as String? ?? '';
            if (authorId.isNotEmpty && authorId != userId) {
              final title = data['title'] as String?;
              String? targetImage;
              if (data['imageUrl'] is String) {
                targetImage = data['imageUrl'] as String;
              } else if (data['imageUrls'] is List &&
                  (data['imageUrls'] as List).isNotEmpty) {
                final first = (data['imageUrls'] as List).first;
                if (first is String) {
                  targetImage = first;
                }
              }

              await _createActivity(
                userId: authorId,
                type: ActivityType.liked,
                actorId: userId,
                targetId: recipeId,
                targetTitle: title,
                targetImage: targetImage,
              );
            }
          }
        } catch (e) {
          debugPrint('Error creating like activity: $e');
        }
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  // Save/unsave recipe
  Future<void> toggleSave(String recipeId, String userId, bool isSaved) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'savedRecipes': isSaved
            ? FieldValue.arrayRemove([recipeId])
            : FieldValue.arrayUnion([recipeId]),
      });
    } catch (e) {
      debugPrint('Error toggling save: $e');
    }
  }

  // AI-powered recipe search
  Future<void> searchRecipesWithAI(String query) async {
    _isSearching = true;
    _aiSuggestions = [];
    notifyListeners();

    try {
      _aiSuggestions = await _geminiService.searchSmartRecipes(query);
    } catch (e) {
      debugPrint('Error searching with AI: $e');
    }

    _isSearching = false;
    notifyListeners();
  }

  Future<void> _createActivity({
    required String userId,
    required ActivityType type,
    required String actorId,
    String? actorName,
    String? actorAvatar,
    String? targetId,
    String? targetTitle,
    String? targetImage,
    String? message,
  }) async {
    try {
      await firestore.collection('activities').add({
        'userId': userId,
        'type': type.name,
        'actorId': actorId,
        if (actorName != null) 'actorName': actorName,
        if (actorAvatar != null) 'actorAvatar': actorAvatar,
        'targetId': targetId,
        'targetTitle': targetTitle,
        'targetImage': targetImage,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint('Error creating activity: $e');
    }
  }

  // Search recipes in Firestore
  Future<void> searchRecipes(String query) async {
    _isSearching = true;
    notifyListeners();

    try {
      // Simple search by title (for more advanced search, consider Algolia)
      final snapshot = await firestore
          .collection('recipes')
          .where('isPublic', isEqualTo: true)
          .orderBy('title')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(20)
          .get();

      _recipes =
          snapshot.docs.map((doc) => RecipeModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error searching recipes: $e');
    }

    _isSearching = false;
    notifyListeners();
  }

  void clearCurrentRecipe() {
    _currentRecipe = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear AI recipe suggestions generated by Gemini.
  void clearAiSuggestions() {
    _aiSuggestions = [];
    notifyListeners();
  }
}
