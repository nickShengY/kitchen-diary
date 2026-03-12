import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_theme.dart';
import 'user_badge.dart';
import 'reaction_bar.dart';

/// Forum post category tag
class CategoryTag extends StatelessWidget {
  final String category;
  final String emoji;
  final Color color;
  final bool compact;

  const CategoryTag({
    super.key,
    required this.category,
    required this.emoji,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: compact ? 12 : 14)),
          const SizedBox(width: 4),
          Text(
            category,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Enhanced forum post card
class ForumPostCard extends StatelessWidget {
  final String id;
  final String title;
  final String content;
  final String authorName;
  final String? authorAvatar;
  final String? authorEmoji;
  final int authorLevel;
  final bool isAuthorVerified;
  final String category;
  final String categoryEmoji;
  final Color categoryColor;
  final DateTime createdAt;
  final List<String>? images;
  final int likes;
  final int comments;
  final bool isLiked;
  final bool isBookmarked;
  final List<Reaction>? reactions;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onBookmark;
  final VoidCallback? onAuthorTap;

  const ForumPostCard({
    super.key,
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    this.authorAvatar,
    this.authorEmoji,
    this.authorLevel = 1,
    this.isAuthorVerified = false,
    required this.category,
    required this.categoryEmoji,
    required this.categoryColor,
    required this.createdAt,
    this.images,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    this.reactions,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onBookmark,
    this.onAuthorTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Author info
                  GestureDetector(
                    onTap: onAuthorTap,
                    child: UserAvatar(
                      imageUrl: authorAvatar,
                      emoji: authorEmoji ?? '👨‍🍳',
                      size: 44,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                authorName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isAuthorVerified) ...[
                              const SizedBox(width: 4),
                              const VerifiedBadge(size: 14),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTimeAgo(createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CategoryTag(
                    category: category,
                    emoji: categoryEmoji,
                    color: categoryColor,
                    compact: true,
                  ),
                ],
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 8),

            // Content preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Images (if any)
            if (images != null && images!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildImageGrid(),
            ],

            const SizedBox(height: 16),

            // Reactions
            if (reactions != null && reactions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ReactionBar(
                  reactions: reactions!,
                  compact: true,
                ),
              ),

            const Divider(height: 24),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SocialActionBar(
                likes: likes,
                comments: comments,
                isLiked: isLiked,
                isBookmarked: isBookmarked,
                onLike: onLike,
                onComment: onComment,
                onShare: onShare,
                onBookmark: onBookmark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    if (images == null || images!.isEmpty) return const SizedBox.shrink();

    final imageCount = images!.length;

    if (imageCount == 1) {
      return _buildImage(images![0], aspectRatio: 16 / 9);
    }

    if (imageCount == 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(child: _buildImage(images![0], height: 150)),
            const SizedBox(width: 4),
            Expanded(child: _buildImage(images![1], height: 150)),
          ],
        ),
      );
    }

    // 3+ images
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildImage(images![0], height: 200),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              children: [
                _buildImage(images![1], height: 98),
                const SizedBox(height: 4),
                Stack(
                  children: [
                    _buildImage(images![2], height: 98),
                    if (imageCount > 3)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '+${imageCount - 3}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String url, {double? height, double? aspectRatio}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: aspectRatio ?? (height != null ? 1 : 16 / 9),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          height: height,
          placeholder: (_, __) => Container(
            color: AppColors.divider,
          ),
          errorWidget: (_, __, ___) => Container(
            color: AppColors.divider,
            child: const Icon(Icons.image),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}

/// Compact post card for lists
class CompactPostCard extends StatelessWidget {
  final String title;
  final String authorName;
  final String? authorEmoji;
  final String category;
  final String categoryEmoji;
  final Color categoryColor;
  final int likes;
  final int comments;
  final VoidCallback? onTap;

  const CompactPostCard({
    super.key,
    required this.title,
    required this.authorName,
    this.authorEmoji,
    required this.category,
    required this.categoryEmoji,
    required this.categoryColor,
    this.likes = 0,
    this.comments = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            // Category indicator
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: categoryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        authorEmoji ?? '👨‍🍳',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        authorName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.favorite_outline,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$likes',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$comments',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
