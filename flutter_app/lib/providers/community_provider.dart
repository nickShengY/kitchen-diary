import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart' show firebaseInitialized;
import '../models/community_model.dart';
import '../models/recipe_model.dart';

class CommunityProvider extends ChangeNotifier {
  FirebaseFirestore? _firestoreInstance;

  FirebaseFirestore get _firestore {
    _firestoreInstance ??= FirebaseFirestore.instance;
    return _firestoreInstance!;
  }

  List<ForumPostModel> _forumPosts = [];
  List<CommentModel> _comments = [];
  List<ChallengeModel> _challenges = [];
  List<ActivityModel> _activities = [];
  List<CollectionModel> _collections = [];
  List<RecipeModel> _trendingRecipes = [];

  bool _isLoading = false;
  String? _errorMessage;

  DocumentSnapshot? _lastForumPost;
  bool _hasMorePosts = true;

  List<ForumPostModel> get forumPosts => _forumPosts;
  List<CommentModel> get comments => _comments;
  List<ChallengeModel> get challenges => _challenges;
  List<ActivityModel> get activities => _activities;
  List<CollectionModel> get collections => _collections;
  List<RecipeModel> get trendingRecipes => _trendingRecipes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMorePosts => _hasMorePosts;

  // Load forum posts
  Future<void> loadForumPosts({String? category}) async {
    _isLoading = true;
    notifyListeners();

    if (!firebaseInitialized) {
      _forumPosts = [];
      _challenges = [];
      _isLoading = false;
      _errorMessage =
          'Community is unavailable because the backend is not configured.';
      notifyListeners();
      return;
    }

    // Default: Firestore-backed forum
    try {
      Query query = _firestore
          .collection('forum_posts')
          .orderBy('isPinned', descending: true)
          .orderBy('createdAt', descending: true);

      if (category != null && category != 'all') {
        query = query.where('category', isEqualTo: category);
      }

      query = query.limit(20);

      final snapshot = await query.get();

      _forumPosts = snapshot.docs
          .map((doc) => ForumPostModel.fromFirestore(doc))
          .toList();

      if (snapshot.docs.isNotEmpty) {
        _lastForumPost = snapshot.docs.last;
        _hasMorePosts = snapshot.docs.length == 20;
      } else {
        _hasMorePosts = false;
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load posts';
      debugPrint('Error loading forum posts: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load more forum posts
  Future<void> loadMoreForumPosts() async {
    if (!_hasMorePosts || _isLoading || _lastForumPost == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('forum_posts')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastForumPost!)
          .limit(20)
          .get();

      final newPosts = snapshot.docs
          .map((doc) => ForumPostModel.fromFirestore(doc))
          .toList();

      _forumPosts.addAll(newPosts);

      if (snapshot.docs.isNotEmpty) {
        _lastForumPost = snapshot.docs.last;
        _hasMorePosts = snapshot.docs.length == 20;
      } else {
        _hasMorePosts = false;
      }
    } catch (e) {
      _errorMessage = 'Failed to load more posts';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Create forum post
  Future<String?> createForumPost(ForumPostModel post) async {
    // Firestore-backed forum
    try {
      final docRef = await _firestore.collection('forum_posts').add(
            post.toFirestore(),
          );

      // Add to local list
      _forumPosts.insert(
          0,
          ForumPostModel(
            id: docRef.id,
            authorId: post.authorId,
            authorName: post.authorName,
            authorAvatar: post.authorAvatar,
            authorPhotoUrl: post.authorPhotoUrl,
            title: post.title,
            content: post.content,
            tags: post.tags,
            imageUrls: post.imageUrls,
            category: post.category,
            createdAt: DateTime.now(),
          ));

      _errorMessage = null;
      notifyListeners();
      return docRef.id;
    } catch (e) {
      _errorMessage = 'Failed to create post';
      notifyListeners();
      return null;
    }
  }

  // Load comments for a recipe or forum post
  Future<void> loadComments(String parentId, {bool isForumPost = false}) async {
    try {
      final collection = isForumPost ? 'forum_comments' : 'comments';

      final snapshot = await _firestore
          .collection(collection)
          .where('recipeId', isEqualTo: parentId)
          .where('parentCommentId', isNull: true)
          .orderBy('createdAt', descending: true)
          .get();

      _comments =
          snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading comments: $e');
    }
  }

  // Add comment
  Future<String?> addComment(CommentModel comment,
      {bool isForumPost = false}) async {
    try {
      final collection = isForumPost ? 'forum_comments' : 'comments';

      final docRef = await _firestore.collection(collection).add(
            comment.toFirestore(),
          );

      // Update comment count on parent (recipe or forum post)
      final parentCollection = isForumPost ? 'forum_posts' : 'recipes';
      final parentId = comment.recipeId;

      await _firestore.collection(parentCollection).doc(parentId).update({
        'commentsCount': FieldValue.increment(1),
      });

      // Create activity for parent author (only when commenting on
      // someone else's content)
      try {
        final parentDoc =
            await _firestore.collection(parentCollection).doc(parentId).get();
        final parentData = parentDoc.data();
        if (parentData != null) {
          final parentAuthorId = parentData['authorId'] as String? ?? '';
          if (parentAuthorId.isNotEmpty && parentAuthorId != comment.authorId) {
            final targetTitle = parentData['title'] as String?;
            String? targetImage;
            if (parentData['imageUrl'] is String) {
              targetImage = parentData['imageUrl'] as String;
            } else if (parentData['imageUrls'] is List &&
                (parentData['imageUrls'] as List).isNotEmpty) {
              final first = (parentData['imageUrls'] as List).first;
              if (first is String) {
                targetImage = first;
              }
            }

            await _createActivity(
              userId: parentAuthorId,
              type: ActivityType.commented,
              actorId: comment.authorId,
              actorName: comment.authorName,
              actorAvatar: comment.authorAvatar,
              targetId: parentId,
              targetTitle: targetTitle,
              targetImage: targetImage,
              message: comment.content,
            );
          }
        }
      } catch (e) {
        debugPrint('Error creating comment activity: $e');
      }

      // Add to local list
      _comments.insert(
          0,
          CommentModel(
            id: docRef.id,
            recipeId: comment.recipeId,
            authorId: comment.authorId,
            authorName: comment.authorName,
            authorAvatar: comment.authorAvatar,
            content: comment.content,
            createdAt: DateTime.now(),
          ));

      notifyListeners();
      return docRef.id;
    } catch (e) {
      _errorMessage = 'Failed to add comment';
      notifyListeners();
      return null;
    }
  }

  // Load replies for a comment
  Future<List<CommentModel>> loadReplies(String commentId,
      {bool isForumPost = false}) async {
    try {
      final collection = isForumPost ? 'forum_comments' : 'comments';

      final snapshot = await _firestore
          .collection(collection)
          .where('parentCommentId', isEqualTo: commentId)
          .orderBy('createdAt')
          .get();

      return snapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error loading replies: $e');
      return [];
    }
  }

  // Load challenges
  Future<void> loadChallenges() async {
    try {
      final snapshot = await _firestore
          .collection('challenges')
          .where('isActive', isEqualTo: true)
          .orderBy('endDate')
          .get();

      _challenges = snapshot.docs
          .map((doc) => ChallengeModel.fromFirestore(doc))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading challenges: $e');
    }
  }

  // Load user activities
  Future<void> loadActivities(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      _activities =
          snapshot.docs.map((doc) => ActivityModel.fromFirestore(doc)).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading activities: $e');
    }
  }

  // Mark activities as read
  Future<void> markActivitiesAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final unreadActivities = _activities.where((a) => !a.isRead);

      for (final activity in unreadActivities) {
        batch.update(
          _firestore.collection('activities').doc(activity.id),
          {'isRead': true},
        );
      }

      await batch.commit();

      _activities = _activities
          .map((a) => ActivityModel(
                id: a.id,
                userId: a.userId,
                type: a.type,
                actorId: a.actorId,
                actorName: a.actorName,
                actorAvatar: a.actorAvatar,
                targetId: a.targetId,
                targetTitle: a.targetTitle,
                targetImage: a.targetImage,
                message: a.message,
                createdAt: a.createdAt,
                isRead: true,
              ))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error marking activities as read: $e');
    }
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
      await _firestore.collection('activities').add({
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

  // Load collections
  Future<void> loadCollections(
      {String? userId, bool publicOnly = false}) async {
    try {
      Query query = _firestore.collection('collections');

      if (userId != null) {
        query = query.where('authorId', isEqualTo: userId);
      }
      if (publicOnly) {
        query = query.where('isPublic', isEqualTo: true);
      }

      query = query.orderBy('updatedAt', descending: true);

      final snapshot = await query.get();

      _collections = snapshot.docs
          .map((doc) => CollectionModel.fromFirestore(doc))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading collections: $e');
    }
  }

  // Create collection
  Future<String?> createCollection(CollectionModel collection) async {
    try {
      final docRef = await _firestore.collection('collections').add(
            collection.toFirestore(),
          );

      _collections.insert(
          0,
          CollectionModel(
            id: docRef.id,
            title: collection.title,
            description: collection.description,
            authorId: collection.authorId,
            authorName: collection.authorName,
            coverImageUrl: collection.coverImageUrl,
            recipeIds: collection.recipeIds,
            isPublic: collection.isPublic,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));

      notifyListeners();
      return docRef.id;
    } catch (e) {
      _errorMessage = 'Failed to create collection';
      notifyListeners();
      return null;
    }
  }

  // Add recipe to collection
  Future<bool> addRecipeToCollection(
      String collectionId, String recipeId) async {
    try {
      await _firestore.collection('collections').doc(collectionId).update({
        'recipeIds': FieldValue.arrayUnion([recipeId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final index = _collections.indexWhere((c) => c.id == collectionId);
      if (index != -1) {
        final collection = _collections[index];
        _collections[index] = CollectionModel(
          id: collection.id,
          title: collection.title,
          description: collection.description,
          authorId: collection.authorId,
          authorName: collection.authorName,
          coverImageUrl: collection.coverImageUrl,
          recipeIds: [...collection.recipeIds, recipeId],
          isPublic: collection.isPublic,
          likes: collection.likes,
          createdAt: collection.createdAt,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to add recipe to collection';
      notifyListeners();
      return false;
    }
  }

  // Load trending recipes
  Future<void> loadTrendingRecipes() async {
    try {
      final snapshot = await _firestore
          .collection('recipes')
          .where('isPublic', isEqualTo: true)
          .orderBy('likes', descending: true)
          .limit(10)
          .get();

      _trendingRecipes =
          snapshot.docs.map((doc) => RecipeModel.fromFirestore(doc)).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading trending recipes: $e');
    }
  }

  // Follow/unfollow user
  Future<void> toggleFollow(
      String currentUserId, String targetUserId, bool isFollowing) async {
    try {
      final batch = _firestore.batch();

      // Update current user's following
      batch.update(
        _firestore.collection('users').doc(currentUserId),
        {
          'following': isFollowing
              ? FieldValue.arrayRemove([targetUserId])
              : FieldValue.arrayUnion([targetUserId]),
        },
      );

      // Update target user's followers
      batch.update(
        _firestore.collection('users').doc(targetUserId),
        {
          'followers': isFollowing
              ? FieldValue.arrayRemove([currentUserId])
              : FieldValue.arrayUnion([currentUserId]),
        },
      );

      await batch.commit();

      // Create activity if following
      if (!isFollowing) {
        await _createActivity(
          userId: targetUserId,
          type: ActivityType.followed,
          actorId: currentUserId,
        );
      }
    } catch (e) {
      debugPrint('Error toggling follow: $e');
    }
  }

  // Like forum post
  Future<void> togglePostLike(
      String postId, String userId, bool isLiked) async {
    // Firestore-backed forum
    try {
      await _firestore.collection('forum_posts').doc(postId).update({
        'likes': FieldValue.increment(isLiked ? -1 : 1),
        'likedBy': isLiked
            ? FieldValue.arrayRemove([userId])
            : FieldValue.arrayUnion([userId]),
      });

      // Update local
      final index = _forumPosts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final post = _forumPosts[index];
        _forumPosts[index] = ForumPostModel(
          id: post.id,
          authorId: post.authorId,
          authorName: post.authorName,
          authorAvatar: post.authorAvatar,
          authorPhotoUrl: post.authorPhotoUrl,
          title: post.title,
          content: post.content,
          tags: post.tags,
          imageUrls: post.imageUrls,
          category: post.category,
          likes: post.likes + (isLiked ? -1 : 1),
          likedBy: isLiked
              ? post.likedBy.where((id) => id != userId).toList()
              : [...post.likedBy, userId],
          commentsCount: post.commentsCount,
          views: post.views,
          isPinned: post.isPinned,
          isClosed: post.isClosed,
          createdAt: post.createdAt,
          editedAt: post.editedAt,
          linkedRecipeId: post.linkedRecipeId,
          mentions: post.mentions,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling post like: $e');
    }
  }

  int get unreadActivityCount => _activities.where((a) => !a.isRead).length;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
