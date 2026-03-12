import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// Achievement data model
class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int xpReward;
  final String? unlocks;
  final bool isUnlocked;
  final double progress;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.xpReward,
    this.unlocks,
    this.isUnlocked = false,
    this.progress = 0.0,
    this.unlockedAt,
  });

  factory Achievement.fromJson(
    Map<String, dynamic> json, {
    bool isUnlocked = false,
    double progress = 0.0,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      emoji: json['emoji'] as String,
      xpReward: json['xpReward'] as int,
      unlocks: json['unlocks'] as String?,
      isUnlocked: isUnlocked,
      progress: progress,
      unlockedAt: unlockedAt,
    );
  }
}

/// Achievement badge widget
class AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final double size;
  final VoidCallback? onTap;

  const AchievementBadge({
    super.key,
    required this.achievement,
    this.size = 64,
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
          alignment: Alignment.center,
          children: [
            // Background circle
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: achievement.isUnlocked
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.accent,
                          AppColors.primary,
                        ],
                      )
                    : null,
                color: achievement.isUnlocked ? null : AppColors.divider,
                shape: BoxShape.circle,
                boxShadow: achievement.isUnlocked
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
            ),

            // Progress ring (if not unlocked)
            if (!achievement.isUnlocked && achievement.progress > 0)
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: achievement.progress,
                  strokeWidth: 3,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(
                    AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
              ),

            // Emoji
            Text(
              achievement.emoji,
              style: TextStyle(
                fontSize: size * 0.45,
                color: achievement.isUnlocked ? null : Colors.grey,
              ),
            ),

            // Lock overlay
            if (!achievement.isUnlocked)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: size * 0.35,
                  height: size * 0.35,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    Icons.lock,
                    size: size * 0.18,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Achievement unlock popup
class AchievementUnlockPopup extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback? onDismiss;

  const AchievementUnlockPopup({
    super.key,
    required this.achievement,
    this.onDismiss,
  });

  static void show(BuildContext context, Achievement achievement) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => AchievementUnlockPopup(
        achievement: achievement,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
    HapticFeedback.heavyImpact();

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) entry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber.shade700,
                    Colors.orange.shade800,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'ACHIEVEMENT UNLOCKED!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Badge
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        achievement.emoji,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ).animate().scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        duration: 500.ms,
                        curve: Curves.elasticOut,
                      ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    achievement.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Description
                  Text(
                    achievement.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // XP reward
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          '+${achievement.xpReward} XP',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Unlocks info
                  if (achievement.unlocks != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Unlocked: ${_formatUnlock(achievement.unlocks!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: -0.3, end: 0, curve: Curves.easeOutBack)
        .then(delay: 3000.ms)
        .fadeOut(duration: 300.ms)
        .slideY(begin: 0, end: -0.3);
  }

  String _formatUnlock(String unlock) {
    return unlock.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}

/// Achievement list card
class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback? onTap;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: achievement.isUnlocked
              ? AppColors.accent.withValues(alpha: 0.05)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: achievement.isUnlocked
                ? AppColors.accent.withValues(alpha: 0.3)
                : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            // Badge
            AchievementBadge(
              achievement: achievement,
              size: 56,
            ),

            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          achievement.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: achievement.isUnlocked
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+${achievement.xpReward} XP',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  // Progress bar (if not unlocked)
                  if (!achievement.isUnlocked && achievement.progress > 0) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: achievement.progress,
                        minHeight: 6,
                        backgroundColor: AppColors.divider,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(achievement.progress * 100).toInt()}% complete',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],

                  // Unlocked date
                  if (achievement.isUnlocked &&
                      achievement.unlockedAt != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Unlocked ${_formatDate(achievement.unlockedAt!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}

/// XP progress bar
class XPProgressBar extends StatelessWidget {
  final int currentXP;
  final int levelXP;
  final int level;

  const XPProgressBar({
    super.key,
    required this.currentXP,
    required this.levelXP,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentXP / levelXP;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$level',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Level $level',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                '$currentXP / $levelXP XP',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
