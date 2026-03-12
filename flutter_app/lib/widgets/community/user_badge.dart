import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// User level and badge display
class UserLevelBadge extends StatelessWidget {
  final int level;
  final String levelName;
  final String badge;
  final bool showName;
  final double size;

  const UserLevelBadge({
    super.key,
    required this.level,
    required this.levelName,
    required this.badge,
    this.showName = true,
    this.size = 24,
  });

  factory UserLevelBadge.fromXP(int xp,
      {bool showName = true, double size = 24}) {
    final levelData = _getLevelFromXP(xp);
    return UserLevelBadge(
      level: levelData['level'] as int,
      levelName: levelData['name'] as String,
      badge: levelData['badge'] as String,
      showName: showName,
      size: size,
    );
  }

  static Map<String, dynamic> _getLevelFromXP(int xp) {
    final levels = [
      {'level': 1, 'name': 'Kitchen Newbie', 'minXP': 0, 'badge': '🌱'},
      {'level': 2, 'name': 'Apprentice Cook', 'minXP': 100, 'badge': '🍳'},
      {'level': 3, 'name': 'Home Chef', 'minXP': 300, 'badge': '👨‍🍳'},
      {'level': 4, 'name': 'Skilled Chef', 'minXP': 600, 'badge': '⭐'},
      {'level': 5, 'name': 'Expert Chef', 'minXP': 1000, 'badge': '🌟'},
      {'level': 6, 'name': 'Master Chef', 'minXP': 2000, 'badge': '👑'},
      {'level': 7, 'name': 'Culinary Legend', 'minXP': 5000, 'badge': '🏆'},
    ];

    for (int i = levels.length - 1; i >= 0; i--) {
      if (xp >= (levels[i]['minXP'] as int)) {
        return levels[i];
      }
    }
    return levels[0];
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(size * 0.15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _getLevelColors(level),
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _getLevelColors(level).first.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            badge,
            style: TextStyle(fontSize: size * 0.6),
          ),
        ),
        if (showName) ...[
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Level $level',
                style: TextStyle(
                  fontSize: size * 0.45,
                  fontWeight: FontWeight.w700,
                  color: _getLevelColors(level).first,
                ),
              ),
              Text(
                levelName,
                style: TextStyle(
                  fontSize: size * 0.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  List<Color> _getLevelColors(int level) {
    switch (level) {
      case 1:
        return [const Color(0xFF9CA3AF), const Color(0xFF6B7280)];
      case 2:
        return [const Color(0xFF60A5FA), const Color(0xFF3B82F6)];
      case 3:
        return [const Color(0xFF34D399), const Color(0xFF10B981)];
      case 4:
        return [const Color(0xFFFBBF24), const Color(0xFFF59E0B)];
      case 5:
        return [const Color(0xFFF472B6), const Color(0xFFEC4899)];
      case 6:
        return [const Color(0xFFA78BFA), const Color(0xFF8B5CF6)];
      case 7:
        return [const Color(0xFFFCD34D), const Color(0xFFF59E0B)];
      default:
        return [const Color(0xFF9CA3AF), const Color(0xFF6B7280)];
    }
  }
}

/// Community badge (verified, helper, etc.)
class CommunityBadge extends StatelessWidget {
  final String id;
  final String name;
  final String emoji;
  final String? description;
  final double size;
  final bool showTooltip;

  const CommunityBadge({
    super.key,
    required this.id,
    required this.name,
    required this.emoji,
    this.description,
    this.size = 20,
    this.showTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getBadgeColor(id).withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: _getBadgeColor(id).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: size * 0.55),
        ),
      ),
    );

    if (showTooltip && description != null) {
      return Tooltip(
        message: '$name\n$description',
        child: badge,
      );
    }

    return badge;
  }

  Color _getBadgeColor(String id) {
    switch (id) {
      case 'verified':
        return Colors.blue;
      case 'helpful':
        return Colors.green;
      case 'popular':
        return Colors.amber;
      case 'veteran':
        return Colors.purple;
      case 'influencer':
        return Colors.pink;
      case 'weekly_winner':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

/// User avatar with optional badge overlay
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? emoji;
  final Color? backgroundColor;
  final double size;
  final List<CommunityBadge>? badges;
  final bool showOnlineIndicator;
  final bool isOnline;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.emoji,
    this.backgroundColor,
    this.size = 48,
    this.badges,
    this.showOnlineIndicator = false,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Avatar
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color:
                    backgroundColor ?? AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? Center(
                      child: Text(
                        emoji ?? '👨‍🍳',
                        style: TextStyle(fontSize: size * 0.5),
                      ),
                    )
                  : null,
            ),

            // Online indicator
            if (showOnlineIndicator)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: size * 0.28,
                  height: size * 0.28,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),

            // Badge (show first badge only)
            if (badges != null && badges!.isNotEmpty)
              Positioned(
                right: -2,
                top: -2,
                child: badges!.first,
              ),
          ],
        ),
      ),
    );
  }
}

/// Row of badges with overflow indicator
class BadgeRow extends StatelessWidget {
  final List<CommunityBadge> badges;
  final int maxVisible;
  final double badgeSize;
  final double spacing;

  const BadgeRow({
    super.key,
    required this.badges,
    this.maxVisible = 3,
    this.badgeSize = 20,
    this.spacing = -6,
  });

  @override
  Widget build(BuildContext context) {
    final visibleBadges = badges.take(maxVisible).toList();
    final overflow = badges.length - maxVisible;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...visibleBadges.asMap().entries.map((entry) {
          return Transform.translate(
            offset: Offset(entry.key * spacing, 0),
            child: entry.value,
          );
        }),
        if (overflow > 0)
          Transform.translate(
            offset: Offset(visibleBadges.length * spacing, 0),
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider),
              ),
              child: Center(
                child: Text(
                  '+$overflow',
                  style: TextStyle(
                    fontSize: badgeSize * 0.4,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Verified badge inline
class VerifiedBadge extends StatelessWidget {
  final double size;

  const VerifiedBadge({
    super.key,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check,
        size: size * 0.7,
        color: Colors.white,
      ),
    );
  }
}

/// User info row with avatar, name, and badges
class UserInfoRow extends StatelessWidget {
  final String name;
  final String? username;
  final String? avatarUrl;
  final String? avatarEmoji;
  final Color? avatarBackground;
  final int level;
  final bool isVerified;
  final List<CommunityBadge>? badges;
  final String? subtitle;
  final VoidCallback? onTap;

  const UserInfoRow({
    super.key,
    required this.name,
    this.username,
    this.avatarUrl,
    this.avatarEmoji,
    this.avatarBackground,
    this.level = 1,
    this.isVerified = false,
    this.badges,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          UserAvatar(
            imageUrl: avatarUrl,
            emoji: avatarEmoji,
            backgroundColor: avatarBackground,
            size: 44,
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
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      const VerifiedBadge(size: 14),
                    ],
                  ],
                ),
                if (subtitle != null || username != null)
                  Text(
                    subtitle ?? '@$username',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (badges != null && badges!.isNotEmpty) BadgeRow(badges: badges!),
        ],
      ),
    );
  }
}
