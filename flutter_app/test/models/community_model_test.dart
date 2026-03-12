import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_diary/models/community_model.dart';

void main() {
  group('ForumPostModel', () {
    test('creation with required fields', () {
      final post = ForumPostModel(
        id: 'post-1',
        authorId: 'user-1',
        authorName: 'Chef Bob',
        authorAvatar: '👨‍🍳',
        title: 'Best pasta tips',
        content: 'Here are my best tips...',
        createdAt: DateTime(2025, 1, 1),
      );
      expect(post.id, 'post-1');
      expect(post.title, 'Best pasta tips');
      expect(post.category, 'discussion');
      expect(post.likes, 0);
      expect(post.commentsCount, 0);
      expect(post.views, 0);
      expect(post.isPinned, false);
      expect(post.isClosed, false);
      expect(post.tags, isEmpty);
      expect(post.imageUrls, isEmpty);
      expect(post.likedBy, isEmpty);
      expect(post.mentions, isEmpty);
      expect(post.editedAt, isNull);
      expect(post.linkedRecipeId, isNull);
      expect(post.authorPhotoUrl, isNull);
    });

    test('creation with all fields', () {
      final post = ForumPostModel(
        id: 'post-2',
        authorId: 'user-2',
        authorName: 'Chef Alice',
        authorAvatar: '👩‍🍳',
        authorPhotoUrl: 'https://example.com/photo.jpg',
        title: 'Weekly Challenge',
        content: 'This week we cook Italian!',
        tags: ['challenge', 'italian'],
        imageUrls: ['https://example.com/img1.jpg'],
        category: 'challenge',
        likes: 42,
        likedBy: ['user-3', 'user-4'],
        commentsCount: 10,
        views: 200,
        isPinned: true,
        isClosed: false,
        createdAt: DateTime(2025, 1, 1),
        editedAt: DateTime(2025, 1, 2),
        linkedRecipeId: 'recipe-1',
        mentions: ['user-5'],
      );
      expect(post.category, 'challenge');
      expect(post.likes, 42);
      expect(post.likedBy.length, 2);
      expect(post.isPinned, true);
      expect(post.linkedRecipeId, 'recipe-1');
      expect(post.mentions, ['user-5']);
    });

    test('toFirestore produces correct map', () {
      final post = ForumPostModel(
        id: 'post-1',
        authorId: 'user-1',
        authorName: 'Chef',
        authorAvatar: '👨‍🍳',
        title: 'Test',
        content: 'Content',
        category: 'tips',
        likes: 5,
        createdAt: DateTime(2025, 6, 1),
      );
      final map = post.toFirestore();
      expect(map['authorId'], 'user-1');
      expect(map['title'], 'Test');
      expect(map['category'], 'tips');
      expect(map['likes'], 5);
      expect(map['isPinned'], false);
    });

    test('creation can represent a backend-loaded starter post', () {
      final post = ForumPostModel(
        id: 'seed-1',
        authorId: 'user-1',
        authorName: 'Chef',
        authorAvatar: 'A',
        title: 'Starter Post',
        content: 'Loaded from backend',
        category: 'tips',
        createdAt: DateTime(2025, 1, 1),
      );
      expect(post.id, 'seed-1');
      expect(post.authorId, 'user-1');
      expect(post.authorName, 'Chef');
      expect(post.category, 'tips');
      expect(post.likes, 0);
      expect(post.commentsCount, 0);
      expect(post.isPinned, false);
    });

    test('default category is discussion when omitted', () {
      final post = ForumPostModel(
        id: 'post-default',
        authorId: 'user-2',
        authorName: 'Chef',
        authorAvatar: 'B',
        title: 'Default Category',
        content: 'Content',
        createdAt: DateTime(2025, 1, 1),
      );
      expect(post.category, 'discussion');
    });

    group('fromNeonJson', () {
      test('parses snake_case fields correctly', () {
        final json = {
          'id': 'neon-1',
          'author_id': 'user-a',
          'author_name': 'Neon Chef',
          'author_avatar': '🧑‍🍳',
          'title': 'Neon Post',
          'content': 'Content from Neon',
          'category': 'question',
          'likes': 10,
          'liked_by': ['u1', 'u2'],
          'comments_count': 3,
          'views': 50,
          'is_pinned': true,
          'is_closed': false,
          'created_at': '2025-06-01T00:00:00.000Z',
          'edited_at': null,
          'linked_recipe_id': 'r-1',
          'mentions': ['u3'],
          'tags': ['neon'],
          'image_urls': [],
        };
        final post = ForumPostModel.fromNeonJson(json);
        expect(post.id, 'neon-1');
        expect(post.authorId, 'user-a');
        expect(post.authorName, 'Neon Chef');
        expect(post.category, 'question');
        expect(post.likes, 10);
        expect(post.likedBy.length, 2);
        expect(post.isPinned, true);
        expect(post.linkedRecipeId, 'r-1');
      });

      test('handles missing/null fields gracefully', () {
        final json = <String, dynamic>{};
        final post = ForumPostModel.fromNeonJson(json);
        expect(post.id, '');
        expect(post.authorId, '');
        expect(post.authorName, 'Chef');
        expect(post.authorAvatar, '👨‍🍳');
        expect(post.title, '');
        expect(post.content, '');
        expect(post.category, 'discussion');
        expect(post.likes, 0);
        expect(post.views, 0);
        expect(post.isPinned, false);
        expect(post.isClosed, false);
      });

      test('handles string likes/views/comments_count', () {
        final json = {
          'id': '1',
          'likes': '25',
          'views': '100',
          'comments_count': '5',
          'created_at': '2025-01-01T00:00:00.000Z',
        };
        final post = ForumPostModel.fromNeonJson(json);
        expect(post.likes, 25);
        expect(post.views, 100);
        expect(post.commentsCount, 5);
      });

      test('handles invalid date gracefully', () {
        final json = {
          'id': '1',
          'created_at': 'not-a-date',
        };
        final post = ForumPostModel.fromNeonJson(json);
        // Should not throw, falls back to DateTime.now()
        expect(post.createdAt, isNotNull);
      });
    });

    group('toNeonJson', () {
      test('produces snake_case fields', () {
        final post = ForumPostModel(
          id: 'post-1',
          authorId: 'user-1',
          authorName: 'Chef',
          authorAvatar: '👨‍🍳',
          title: 'Test',
          content: 'Content',
          createdAt: DateTime.utc(2025, 1, 1),
        );
        final json = post.toNeonJson();
        expect(json['author_id'], 'user-1');
        expect(json['author_name'], 'Chef');
        expect(json['created_at'], '2025-01-01T00:00:00.000Z');
        expect(json['is_pinned'], false);
        expect(json['is_closed'], false);
        expect(json.containsKey('id'), true);
      });

      test('omits id when empty', () {
        final post = ForumPostModel(
          id: '',
          authorId: 'user-1',
          authorName: 'Chef',
          authorAvatar: '👨‍🍳',
          title: 'New Post',
          content: 'Content',
          createdAt: DateTime.utc(2025, 1, 1),
        );
        final json = post.toNeonJson();
        expect(json.containsKey('id'), false);
      });
    });

    test('Neon roundtrip: toNeonJson then fromNeonJson', () {
      final original = ForumPostModel(
        id: 'rt-1',
        authorId: 'user-rt',
        authorName: 'RT Chef',
        authorAvatar: '🧑‍🍳',
        title: 'Roundtrip',
        content: 'Testing roundtrip',
        category: 'tips',
        likes: 7,
        likedBy: ['u1'],
        commentsCount: 2,
        views: 30,
        isPinned: false,
        isClosed: true,
        createdAt: DateTime.utc(2025, 3, 15, 10, 30),
        tags: ['roundtrip'],
        mentions: ['u2'],
      );
      final restored = ForumPostModel.fromNeonJson(original.toNeonJson());
      expect(restored.id, original.id);
      expect(restored.authorId, original.authorId);
      expect(restored.title, original.title);
      expect(restored.category, original.category);
      expect(restored.likes, original.likes);
      expect(restored.isPinned, original.isPinned);
      expect(restored.isClosed, original.isClosed);
    });
  });

  group('ChallengeModel', () {
    test('creation with defaults', () {
      final challenge = ChallengeModel(
        id: 'ch-1',
        title: 'Pasta Week',
        description: 'Cook a pasta dish every day',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 7),
      );
      expect(challenge.id, 'ch-1');
      expect(challenge.participantsCount, 0);
      expect(challenge.difficulty, 'medium');
      expect(challenge.isActive, true);
      expect(challenge.requirements, isEmpty);
      expect(challenge.hashtags, isEmpty);
      expect(challenge.prizes, isEmpty);
      expect(challenge.imageUrl, isNull);
      expect(challenge.sponsorName, isNull);
      expect(challenge.sponsorLogo, isNull);
    });

    test('isOngoing returns true for current challenge', () {
      final challenge = ChallengeModel(
        id: 'ch-2',
        title: 'Active Challenge',
        description: 'Running now',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 6)),
      );
      expect(challenge.isOngoing, true);
    });

    test('isOngoing returns false for past challenge', () {
      final challenge = ChallengeModel(
        id: 'ch-3',
        title: 'Past Challenge',
        description: 'Already ended',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 7),
      );
      expect(challenge.isOngoing, false);
    });

    test('isOngoing returns false for future challenge', () {
      final challenge = ChallengeModel(
        id: 'ch-4',
        title: 'Future Challenge',
        description: 'Not started yet',
        startDate: DateTime.now().add(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 37)),
      );
      expect(challenge.isOngoing, false);
    });
  });

  group('ActivityType', () {
    test('has correct values', () {
      expect(ActivityType.values.length, 8);
      expect(ActivityType.liked.name, 'liked');
      expect(ActivityType.commented.name, 'commented');
      expect(ActivityType.followed.name, 'followed');
      expect(ActivityType.shared.name, 'shared');
      expect(ActivityType.mentioned.name, 'mentioned');
      expect(ActivityType.newRecipe.name, 'newRecipe');
      expect(ActivityType.challengeJoined.name, 'challengeJoined');
      expect(ActivityType.badgeEarned.name, 'badgeEarned');
    });
  });

  group('ActivityModel', () {
    test('creation with required fields', () {
      final activity = ActivityModel(
        id: 'act-1',
        userId: 'user-1',
        type: ActivityType.liked,
        actorId: 'user-2',
        actorName: 'Alice',
        actorAvatar: '👩‍🍳',
        createdAt: DateTime(2025, 1, 1),
      );
      expect(activity.id, 'act-1');
      expect(activity.type, ActivityType.liked);
      expect(activity.isRead, false);
      expect(activity.targetId, isNull);
      expect(activity.targetTitle, isNull);
      expect(activity.message, isNull);
    });

    test('creation with all fields', () {
      final activity = ActivityModel(
        id: 'act-2',
        userId: 'user-1',
        type: ActivityType.commented,
        actorId: 'user-3',
        actorName: 'Bob',
        actorAvatar: '👨‍🍳',
        targetId: 'recipe-1',
        targetTitle: 'Spaghetti',
        targetImage: 'https://example.com/img.jpg',
        message: 'Great recipe!',
        createdAt: DateTime(2025, 1, 1),
        isRead: true,
      );
      expect(activity.targetId, 'recipe-1');
      expect(activity.targetTitle, 'Spaghetti');
      expect(activity.message, 'Great recipe!');
      expect(activity.isRead, true);
    });
  });

  group('CollectionModel', () {
    test('creation with defaults', () {
      final col = CollectionModel(
        id: 'col-1',
        title: 'My Favorites',
        authorId: 'user-1',
        authorName: 'Chef Bob',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );
      expect(col.recipeIds, isEmpty);
      expect(col.isPublic, true);
      expect(col.likes, 0);
      expect(col.description, isNull);
      expect(col.coverImageUrl, isNull);
    });

    test('toFirestore produces correct map', () {
      final col = CollectionModel(
        id: 'col-2',
        title: 'Italian',
        description: 'Classic Italian recipes',
        authorId: 'user-1',
        authorName: 'Chef',
        recipeIds: ['r1', 'r2'],
        isPublic: true,
        likes: 10,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 6, 1),
      );
      final map = col.toFirestore();
      expect(map['title'], 'Italian');
      expect(map['description'], 'Classic Italian recipes');
      expect(map['recipeIds'], ['r1', 'r2']);
      expect(map['isPublic'], true);
      expect(map['likes'], 10);
    });
  });

  group('CommentModel', () {
    test('creation with required fields', () {
      final comment = CommentModel(
        id: 'c-1',
        recipeId: 'r-1',
        authorId: 'u-1',
        authorName: 'Chef',
        authorAvatar: '👨‍🍳',
        content: 'Great recipe!',
        createdAt: DateTime(2025, 1, 1),
      );
      expect(comment.id, 'c-1');
      expect(comment.content, 'Great recipe!');
      expect(comment.likes, 0);
      expect(comment.likedBy, isEmpty);
      expect(comment.parentCommentId, isNull);
      expect(comment.repliesCount, 0);
      expect(comment.isDeleted, false);
      expect(comment.editedAt, isNull);
    });

    test('toFirestore produces correct map', () {
      final comment = CommentModel(
        id: 'c-2',
        recipeId: 'r-1',
        authorId: 'u-1',
        authorName: 'Chef',
        authorAvatar: '👨‍🍳',
        content: 'Love it!',
        likes: 3,
        likedBy: ['u-2', 'u-3', 'u-4'],
        parentCommentId: 'c-1',
        createdAt: DateTime(2025, 1, 1),
      );
      final map = comment.toFirestore();
      expect(map['recipeId'], 'r-1');
      expect(map['content'], 'Love it!');
      expect(map['likes'], 3);
      expect(map['likedBy'].length, 3);
      expect(map['parentCommentId'], 'c-1');
      expect(map['isDeleted'], false);
    });
  });
}
