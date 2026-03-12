import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_theme.dart';

/// Story ring with gradient border
class StoryRing extends StatelessWidget {
  final String? imageUrl;
  final String? emoji;
  final double size;
  final bool hasUnseenStory;
  final bool isLive;
  final VoidCallback? onTap;

  const StoryRing({
    super.key,
    this.imageUrl,
    this.emoji,
    this.size = 64,
    this.hasUnseenStory = false,
    this.isLive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Gradient ring
            if (hasUnseenStory || isLive)
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: isLive
                        ? [Colors.red, Colors.redAccent, Colors.red]
                        : [
                            const Color(0xFFFF6B6B),
                            const Color(0xFFFFE66D),
                            const Color(0xFF4ECDC4),
                            const Color(0xFFFF6B6B),
                          ],
                  ),
                ),
              )
            else
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.divider,
                    width: 2,
                  ),
                ),
              ),

            // White gap
            Container(
              width: size - 4,
              height: size - 4,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),

            // Avatar
            Container(
              width: size - 8,
              height: size - 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
                image: imageUrl != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? Center(
                      child: Text(
                        emoji ?? '👨‍🍳',
                        style: TextStyle(fontSize: size * 0.4),
                      ),
                    )
                  : null,
            ),

            // Live badge
            if (isLive)
              Positioned(
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal story list
class StoryList extends StatelessWidget {
  final List<StoryUser> users;
  final bool showAddStory;
  final VoidCallback? onAddStory;
  final Function(String userId)? onStoryTap;

  const StoryList({
    super.key,
    required this.users,
    this.showAddStory = true,
    this.onAddStory,
    this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: users.length + (showAddStory ? 1 : 0),
        itemBuilder: (context, index) {
          if (showAddStory && index == 0) {
            return _AddStoryButton(onTap: onAddStory);
          }

          final user = users[showAddStory ? index - 1 : index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _StoryItem(
              user: user,
              onTap: () => onStoryTap?.call(user.id),
            ),
          );
        },
      ),
    );
  }
}

class _AddStoryButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _AddStoryButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.divider, width: 2),
              ),
              child: const Icon(
                Icons.add,
                size: 28,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your Story',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  final StoryUser user;
  final VoidCallback? onTap;

  const _StoryItem({
    required this.user,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StoryRing(
          imageUrl: user.avatarUrl,
          emoji: user.avatarEmoji,
          hasUnseenStory: user.hasUnseenStory,
          isLive: user.isLive,
          onTap: onTap,
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 64,
          child: Text(
            user.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  user.hasUnseenStory ? FontWeight.w600 : FontWeight.normal,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

/// Story user data
class StoryUser {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? avatarEmoji;
  final bool hasUnseenStory;
  final bool isLive;
  final int storyCount;

  const StoryUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.avatarEmoji,
    this.hasUnseenStory = false,
    this.isLive = false,
    this.storyCount = 0,
  });
}

/// Story progress bar
class StoryProgressBar extends StatelessWidget {
  final int totalStories;
  final int currentIndex;
  final double progress;

  const StoryProgressBar({
    super.key,
    required this.totalStories,
    required this.currentIndex,
    this.progress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalStories, (index) {
        return Expanded(
          child: Container(
            height: 2,
            margin: EdgeInsets.only(right: index < totalStories - 1 ? 4 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              color: Colors.white.withValues(alpha: 0.3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: index < currentIndex
                  ? 1.0
                  : (index == currentIndex ? progress : 0.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Story viewer overlay
class StoryViewerHeader extends StatelessWidget {
  final String userName;
  final String? userAvatar;
  final String? userEmoji;
  final DateTime postedAt;
  final VoidCallback? onClose;
  final VoidCallback? onMore;

  const StoryViewerHeader({
    super.key,
    required this.userName,
    this.userAvatar,
    this.userEmoji,
    required this.postedAt,
    this.onClose,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.2),
            image: userAvatar != null
                ? DecorationImage(
                    image: CachedNetworkImageProvider(userAvatar!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: userAvatar == null
              ? Center(
                  child: Text(
                    userEmoji ?? '👨‍🍳',
                    style: const TextStyle(fontSize: 18),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 10),

        // Name and time
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                _formatTimeAgo(postedAt),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Actions
        IconButton(
          icon: const Icon(Icons.more_horiz, color: Colors.white),
          onPressed: onMore,
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: onClose,
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

/// Story reply input
class StoryReplyInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSend;
  final VoidCallback? onReaction;

  const StoryReplyInput({
    super.key,
    required this.controller,
    this.onSend,
    this.onReaction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Reply to story...',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onReaction,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('❤️', style: TextStyle(fontSize: 20)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
