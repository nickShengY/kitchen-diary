import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// Profile stats grid
class ProfileStatsGrid extends StatelessWidget {
  final List<ProfileStat> stats;
  final int columns;
  final VoidCallback? onStatTap;

  const ProfileStatsGrid({
    super.key,
    required this.stats,
    this.columns = 3,
    this.onStatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: stats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          final isLast = index == stats.length - 1;

          return Expanded(
            child: GestureDetector(
              onTap: onStatTap,
              child: Container(
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(
                          right: BorderSide(color: AppColors.divider),
                        ),
                ),
                child: Column(
                  children: [
                    Text(stat.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 6),
                    Text(
                      _formatNumber(stat.value),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stat.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toString();
  }
}

class ProfileStat {
  final String id;
  final String label;
  final String emoji;
  final int value;

  const ProfileStat({
    required this.id,
    required this.label,
    required this.emoji,
    required this.value,
  });
}

/// Achievement showcase
class AchievementShowcase extends StatelessWidget {
  final List<Achievement> achievements;
  final int maxDisplay;
  final VoidCallback? onSeeAll;

  const AchievementShowcase({
    super.key,
    required this.achievements,
    this.maxDisplay = 5,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final displayAchievements = achievements.take(maxDisplay).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text(
                'Achievements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: Text(
                    'See All (${achievements.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: displayAchievements.length,
            itemBuilder: (context, index) {
              final achievement = displayAchievements[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _AchievementBadge(achievement: achievement),
              )
                  .animate(delay: Duration(milliseconds: index * 100))
                  .fadeIn()
                  .scale(begin: const Offset(0.8, 0.8));
            },
          ),
        ),
      ],
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final Achievement achievement;

  const _AchievementBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: achievement.isUnlocked
              ? [achievement.color, achievement.color.withValues(alpha: 0.7)]
              : [Colors.grey.shade300, Colors.grey.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: achievement.isUnlocked
            ? [
                BoxShadow(
                  color: achievement.color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            achievement.isUnlocked ? achievement.emoji : '🔒',
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 4),
          Text(
            achievement.name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color:
                  achievement.isUnlocked ? Colors.white : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class Achievement {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final bool isUnlocked;
  final double? progress;

  const Achievement({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    this.isUnlocked = false,
    this.progress,
  });
}

/// Activity feed item
class ActivityFeedItem extends StatelessWidget {
  final String type;
  final String emoji;
  final String description;
  final DateTime timestamp;
  final String? imageUrl;
  final VoidCallback? onTap;

  const ActivityFeedItem({
    super.key,
    required this.type,
    required this.emoji,
    required this.description,
    required this.timestamp,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTimeAgo(timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: Image.network(imageUrl!, fit: BoxFit.cover),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.month}/${dateTime.day}';
  }
}

/// Cooking stats chart placeholder
class CookingStatsCard extends StatelessWidget {
  final String title;
  final String emoji;
  final String period;
  final Widget chart;
  final VoidCallback? onPeriodChange;

  const CookingStatsCard({
    super.key,
    required this.title,
    required this.emoji,
    required this.period,
    required this.chart,
    this.onPeriodChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onPeriodChange,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        period,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          chart,
        ],
      ),
    );
  }
}

/// Simple bar chart for stats
class SimpleBarChart extends StatelessWidget {
  final List<ChartBar> bars;
  final double maxValue;
  final double barHeight;

  const SimpleBarChart({
    super.key,
    required this.bars,
    required this.maxValue,
    this.barHeight = 140,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: barHeight + 30,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.map((bar) {
          final heightFactor = maxValue > 0 ? bar.value / maxValue : 0.0;

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${bar.value.round()}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: barHeight * heightFactor,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [bar.color, bar.color.withValues(alpha: 0.6)],
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  bar.label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ChartBar {
  final String label;
  final double value;
  final Color color;

  const ChartBar({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Edit profile button
class EditProfileButton extends StatelessWidget {
  final VoidCallback? onTap;

  const EditProfileButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined, size: 16, color: AppColors.textPrimary),
            SizedBox(width: 6),
            Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Follow/Following button
class FollowButton extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback? onTap;

  const FollowButton({
    super.key,
    this.isFollowing = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isFollowing ? AppColors.surface : AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFollowing ? AppColors.divider : AppColors.primary,
          ),
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isFollowing ? AppColors.textPrimary : Colors.white,
          ),
        ),
      ),
    );
  }
}
