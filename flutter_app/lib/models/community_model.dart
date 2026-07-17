import 'package:cloud_firestore/cloud_firestore.dart';

// Comment model for recipe discussions
class CommentModel {
  final String id;
  final String recipeId;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String? authorPhotoUrl;
  final String content;
  final int likes;
  final List<String> likedBy;
  final String? parentCommentId;
  final int repliesCount;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool isDeleted;

  CommentModel({
    required this.id,
    required this.recipeId,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    this.authorPhotoUrl,
    required this.content,
    this.likes = 0,
    this.likedBy = const [],
    this.parentCommentId,
    this.repliesCount = 0,
    required this.createdAt,
    this.editedAt,
    this.isDeleted = false,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      recipeId: data['recipeId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Chef',
      authorAvatar: data['authorAvatar'] ?? '👨‍🍳',
      authorPhotoUrl: data['authorPhotoUrl'],
      content: data['content'] ?? '',
      likes: data['likes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      parentCommentId: data['parentCommentId'],
      repliesCount: data['repliesCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      editedAt: data['editedAt'] != null
          ? (data['editedAt'] as Timestamp).toDate()
          : null,
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'recipeId': recipeId,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'authorPhotoUrl': authorPhotoUrl,
      'content': content,
      'likes': likes,
      'likedBy': likedBy,
      'parentCommentId': parentCommentId,
      'repliesCount': repliesCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'isDeleted': isDeleted,
    };
  }
}

// Forum post for community discussions
class ForumPostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String? authorPhotoUrl;
  final String title;
  final String content;
  final List<String> tags;
  final List<String> imageUrls;
  final String category; // tips, question, discussion, challenge
  final int likes;
  final List<String> likedBy;
  final int commentsCount;
  final int views;
  final bool isPinned;
  final bool isClosed;
  final DateTime createdAt;
  final DateTime? editedAt;
  final String? linkedRecipeId;
  final List<String> mentions;

  ForumPostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    this.authorPhotoUrl,
    required this.title,
    required this.content,
    this.tags = const [],
    this.imageUrls = const [],
    this.category = 'discussion',
    this.likes = 0,
    this.likedBy = const [],
    this.commentsCount = 0,
    this.views = 0,
    this.isPinned = false,
    this.isClosed = false,
    required this.createdAt,
    this.editedAt,
    this.linkedRecipeId,
    this.mentions = const [],
  });

  factory ForumPostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ForumPostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Chef',
      authorAvatar: data['authorAvatar'] ?? '👨‍🍳',
      authorPhotoUrl: data['authorPhotoUrl'],
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      category: data['category'] ?? 'discussion',
      likes: data['likes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      commentsCount: data['commentsCount'] ?? 0,
      views: data['views'] ?? 0,
      isPinned: data['isPinned'] ?? false,
      isClosed: data['isClosed'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      editedAt: data['editedAt'] != null
          ? (data['editedAt'] as Timestamp).toDate()
          : null,
      linkedRecipeId: data['linkedRecipeId'],
      mentions: List<String>.from(data['mentions'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'authorPhotoUrl': authorPhotoUrl,
      'title': title,
      'content': content,
      'tags': tags,
      'imageUrls': imageUrls,
      'category': category,
      'likes': likes,
      'likedBy': likedBy,
      'commentsCount': commentsCount,
      'views': views,
      'isPinned': isPinned,
      'isClosed': isClosed,
      'createdAt': Timestamp.fromDate(createdAt),
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'linkedRecipeId': linkedRecipeId,
      'mentions': mentions,
    };
  }

  /// Create a ForumPostModel from a snake_case API payload.
  factory ForumPostModel.fromApiJson(Map<String, dynamic> data) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return ForumPostModel(
      id: data['id']?.toString() ?? '',
      authorId: data['author_id']?.toString() ?? '',
      authorName: data['author_name']?.toString() ?? 'Chef',
      authorAvatar: data['author_avatar']?.toString() ?? '👨‍🍳',
      authorPhotoUrl: data['author_photo_url'] as String?,
      title: data['title']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      tags: List<String>.from(data['tags'] ?? const []),
      imageUrls: List<String>.from(data['image_urls'] ?? const []),
      category: data['category']?.toString() ?? 'discussion',
      likes: data['likes'] is int
          ? data['likes'] as int
          : int.tryParse('${data['likes']}') ?? 0,
      likedBy: List<String>.from(data['liked_by'] ?? const []),
      commentsCount: data['comments_count'] is int
          ? data['comments_count'] as int
          : int.tryParse('${data['comments_count']}') ?? 0,
      views: data['views'] is int
          ? data['views'] as int
          : int.tryParse('${data['views']}') ?? 0,
      isPinned: data['is_pinned'] as bool? ?? false,
      isClosed: data['is_closed'] as bool? ?? false,
      createdAt: parseDate(data['created_at']),
      editedAt: data['edited_at'] != null ? parseDate(data['edited_at']) : null,
      linkedRecipeId: data['linked_recipe_id'] as String?,
      mentions: List<String>.from(data['mentions'] ?? const []),
    );
  }

  /// Convert this post to a snake_case API payload.
  Map<String, dynamic> toApiJson() {
    final map = <String, dynamic>{
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'author_photo_url': authorPhotoUrl,
      'title': title,
      'content': content,
      'tags': tags,
      'image_urls': imageUrls,
      'category': category,
      'likes': likes,
      'liked_by': likedBy,
      'comments_count': commentsCount,
      'views': views,
      'is_pinned': isPinned,
      'is_closed': isClosed,
      'created_at': createdAt.toUtc().toIso8601String(),
      'edited_at': editedAt?.toUtc().toIso8601String(),
      'linked_recipe_id': linkedRecipeId,
      'mentions': mentions,
    };

    if (id.isNotEmpty) {
      map['id'] = id;
    }

    return map;
  }
}

// Cooking challenge
class ChallengeModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? sponsorName;
  final String? sponsorLogo;
  final List<String> requirements;
  final List<String> hashtags;
  final DateTime startDate;
  final DateTime endDate;
  final int participantsCount;
  final List<String> prizes;
  final String difficulty;
  final bool isActive;

  ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.sponsorName,
    this.sponsorLogo,
    this.requirements = const [],
    this.hashtags = const [],
    required this.startDate,
    required this.endDate,
    this.participantsCount = 0,
    this.prizes = const [],
    this.difficulty = 'medium',
    this.isActive = true,
  });

  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  factory ChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      sponsorName: data['sponsorName'],
      sponsorLogo: data['sponsorLogo'],
      requirements: List<String>.from(data['requirements'] ?? []),
      hashtags: List<String>.from(data['hashtags'] ?? []),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      participantsCount: data['participantsCount'] ?? 0,
      prizes: List<String>.from(data['prizes'] ?? []),
      difficulty: data['difficulty'] ?? 'medium',
      isActive: data['isActive'] ?? true,
    );
  }
}

// Activity feed item
enum ActivityType {
  liked,
  commented,
  followed,
  shared,
  mentioned,
  newRecipe,
  challengeJoined,
  badgeEarned,
}

class ActivityModel {
  final String id;
  final String userId;
  final ActivityType type;
  final String actorId;
  final String actorName;
  final String actorAvatar;
  final String? targetId;
  final String? targetTitle;
  final String? targetImage;
  final String? message;
  final DateTime createdAt;
  final bool isRead;

  ActivityModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.actorId,
    required this.actorName,
    required this.actorAvatar,
    this.targetId,
    this.targetTitle,
    this.targetImage,
    this.message,
    required this.createdAt,
    this.isRead = false,
  });

  factory ActivityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: ActivityType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ActivityType.liked,
      ),
      actorId: data['actorId'] ?? '',
      actorName: data['actorName'] ?? '',
      actorAvatar: data['actorAvatar'] ?? '👨‍🍳',
      targetId: data['targetId'],
      targetTitle: data['targetTitle'],
      targetImage: data['targetImage'],
      message: data['message'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
    );
  }
}

// Collection of curated recipes
class CollectionModel {
  final String id;
  final String title;
  final String? description;
  final String authorId;
  final String authorName;
  final String? coverImageUrl;
  final List<String> recipeIds;
  final bool isPublic;
  final int likes;
  final DateTime createdAt;
  final DateTime updatedAt;

  CollectionModel({
    required this.id,
    required this.title,
    this.description,
    required this.authorId,
    required this.authorName,
    this.coverImageUrl,
    this.recipeIds = const [],
    this.isPublic = true,
    this.likes = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CollectionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CollectionModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      coverImageUrl: data['coverImageUrl'],
      recipeIds: List<String>.from(data['recipeIds'] ?? []),
      isPublic: data['isPublic'] ?? true,
      likes: data['likes'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'authorId': authorId,
      'authorName': authorName,
      'coverImageUrl': coverImageUrl,
      'recipeIds': recipeIds,
      'isPublic': isPublic,
      'likes': likes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
