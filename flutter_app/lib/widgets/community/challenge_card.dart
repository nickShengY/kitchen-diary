import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

/// Cooking challenge card
class ChallengeCard extends StatelessWidget {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final int participantCount;
  final int submissionCount;
  final String? imageUrl;
  final List<String> prizes;
  final bool isJoined;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;

  const ChallengeCard({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.type,
    required this.startDate,
    required this.endDate,
    this.participantCount = 0,
    this.submissionCount = 0,
    this.imageUrl,
    this.prizes = const [],
    this.isJoined = false,
    this.isActive = true,
    this.onTap,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = endDate.difference(DateTime.now()).inDays;
    final progress = _calculateProgress();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getChallengeColor(type),
              _getChallengeColor(type).withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _getChallengeColor(type).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              top: -20,
              child: Text(
                emoji,
                style: TextStyle(
                  fontSize: 120,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getTypeEmoji(type),
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getTypeLabel(type),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            daysLeft > 0
                                ? '$daysLeft days left'
                                : 'Ends today!',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _getChallengeColor(type),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Row(
                    children: [
                      Text(
                        emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 16),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stats and action
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.people_outline,
                        value: _formatCount(participantCount),
                        label: 'joined',
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        icon: Icons.restaurant_menu,
                        value: _formatCount(submissionCount),
                        label: 'entries',
                      ),
                      const Spacer(),
                      if (isActive)
                        ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            onJoin?.call();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _getChallengeColor(type),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            isJoined ? 'View' : 'Join',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Prizes
                  if (prizes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            '🏆',
                            style: TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Prizes: ${prizes.join(', ')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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

  double _calculateProgress() {
    final total = endDate.difference(startDate).inDays;
    final elapsed = DateTime.now().difference(startDate).inDays;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  Color _getChallengeColor(String type) {
    switch (type) {
      case 'weekly':
        return const Color(0xFF3B82F6);
      case 'flash':
        return const Color(0xFFEF4444);
      case 'monthly':
        return const Color(0xFF8B5CF6);
      case 'seasonal':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getTypeEmoji(String type) {
    switch (type) {
      case 'weekly':
        return '🥇';
      case 'flash':
        return '⚡';
      case 'monthly':
        return '🗓️';
      case 'seasonal':
        return '🍂';
      default:
        return '🏆';
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'weekly':
        return 'WEEKLY';
      case 'flash':
        return 'FLASH';
      case 'monthly':
        return 'MONTHLY';
      case 'seasonal':
        return 'SEASONAL';
      default:
        return 'CHALLENGE';
    }
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.8)),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Compact challenge card for horizontal lists
class CompactChallengeCard extends StatelessWidget {
  final String title;
  final String emoji;
  final String type;
  final int daysLeft;
  final VoidCallback? onTap;

  const CompactChallengeCard({
    super.key,
    required this.title,
    required this.emoji,
    required this.type,
    required this.daysLeft,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getChallengeColor(type),
              _getChallengeColor(type).withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              daysLeft > 0 ? '$daysLeft days left' : 'Ends today!',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getChallengeColor(String type) {
    switch (type) {
      case 'weekly':
        return const Color(0xFF3B82F6);
      case 'flash':
        return const Color(0xFFEF4444);
      case 'monthly':
        return const Color(0xFF8B5CF6);
      case 'seasonal':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

/// Leaderboard entry widget
class LeaderboardEntry extends StatelessWidget {
  final int rank;
  final String userName;
  final String? userAvatar;
  final String? userEmoji;
  final int score;
  final String metric;
  final bool isCurrentUser;
  final VoidCallback? onTap;

  const LeaderboardEntry({
    super.key,
    required this.rank,
    required this.userName,
    this.userAvatar,
    this.userEmoji,
    required this.score,
    this.metric = 'votes',
    this.isCurrentUser = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentUser
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 32,
              child: Text(
                _getRankDisplay(rank),
                style: TextStyle(
                  fontSize: rank <= 3 ? 20 : 16,
                  fontWeight: FontWeight.w700,
                  color: _getRankColor(rank),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                image: userAvatar != null
                    ? DecorationImage(
                        image: NetworkImage(userAvatar!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: userAvatar == null
                  ? Center(
                      child: Text(
                        userEmoji ?? '👨‍🍳',
                        style: const TextStyle(fontSize: 20),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Name
            Expanded(
              child: Text(
                userName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w500,
                  color:
                      isCurrentUser ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),

            // Score
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isCurrentUser
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  metric,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRankDisplay(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.textSecondary;
    }
  }
}
