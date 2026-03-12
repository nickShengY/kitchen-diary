import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_theme.dart';

class _Challenge {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final String difficulty;
  final int participants;
  final int daysLeft;
  final String prize;
  final List<_LeaderboardEntry> leaderboard;
  final bool isJoined;

  const _Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.difficulty,
    required this.participants,
    required this.daysLeft,
    required this.prize,
    this.leaderboard = const [],
    this.isJoined = false,
  });
}

class _LeaderboardEntry {
  final String name;
  final String avatar;
  final int score;
  final int rank;

  const _LeaderboardEntry({
    required this.name,
    required this.avatar,
    required this.score,
    required this.rank,
  });
}

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<_Challenge> _challenges = [
    _Challenge(
      id: '1',
      title: 'One-Pot Wonder Week',
      description: 'Create the most delicious one-pot meal! Share your recipe and get community votes.',
      emoji: '🍲',
      difficulty: 'Beginner',
      participants: 342,
      daysLeft: 5,
      prize: '🏆 Featured Chef Badge + 500 XP',
      leaderboard: [
        _LeaderboardEntry(name: 'Chef Maria', avatar: '👩‍🍳', score: 156, rank: 1),
        _LeaderboardEntry(name: 'CookMaster', avatar: '👨‍🍳', score: 142, rank: 2),
        _LeaderboardEntry(name: 'FoodieKing', avatar: '🧑‍🍳', score: 128, rank: 3),
        _LeaderboardEntry(name: 'SpiceQueen', avatar: '👩‍🍳', score: 115, rank: 4),
        _LeaderboardEntry(name: 'PastaLover', avatar: '👨‍🍳', score: 98, rank: 5),
      ],
    ),
    _Challenge(
      id: '2',
      title: '5-Ingredient Challenge',
      description: 'Make an amazing dish using only 5 ingredients. Creativity is key!',
      emoji: '✋',
      difficulty: 'Intermediate',
      participants: 218,
      daysLeft: 3,
      prize: '🥇 Gold Innovator Badge + 300 XP',
      leaderboard: [
        _LeaderboardEntry(name: 'MinimalistChef', avatar: '🧑‍🍳', score: 189, rank: 1),
        _LeaderboardEntry(name: 'SimpleEats', avatar: '👩‍🍳', score: 167, rank: 2),
        _LeaderboardEntry(name: 'QuickCook', avatar: '👨‍🍳', score: 145, rank: 3),
      ],
    ),
    _Challenge(
      id: '3',
      title: 'World Cuisine Tour',
      description: 'Cook a dish from a different country each day this week. Document your journey!',
      emoji: '🌍',
      difficulty: 'Advanced',
      participants: 156,
      daysLeft: 7,
      prize: '🌟 World Explorer Badge + 1000 XP',
      leaderboard: [
        _LeaderboardEntry(name: 'GlobalFoodie', avatar: '👩‍🍳', score: 234, rank: 1),
        _LeaderboardEntry(name: 'TravelChef', avatar: '🧑‍🍳', score: 198, rank: 2),
      ],
    ),
    _Challenge(
      id: '4',
      title: 'Healthy Meal Prep Master',
      description: 'Prep a week of healthy meals under 500 calories each. Share your meal prep photos!',
      emoji: '🥗',
      difficulty: 'Beginner',
      participants: 489,
      daysLeft: 6,
      prize: '💪 Health Hero Badge + 400 XP',
      isJoined: true,
      leaderboard: [
        _LeaderboardEntry(name: 'FitFoodie', avatar: '👩‍🍳', score: 267, rank: 1),
        _LeaderboardEntry(name: 'NutriChef', avatar: '👨‍🍳', score: 231, rank: 2),
        _LeaderboardEntry(name: 'CleanEats', avatar: '🧑‍🍳', score: 198, rank: 3),
        _LeaderboardEntry(name: 'You', avatar: '👨‍🍳', score: 45, rank: 12),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Cooking Challenges', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: scheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'My Challenges'),
            Tab(text: 'Past Winners'),
          ],
          labelColor: scheme.primary,
          unselectedLabelColor: scheme.onSurfaceVariant,
          indicatorColor: scheme.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveChallenges(scheme),
          _buildMyChallenges(scheme),
          _buildPastWinners(scheme),
        ],
      ),
    );
  }

  Widget _buildActiveChallenges(ColorScheme scheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _challenges.length,
      itemBuilder: (context, index) {
        final challenge = _challenges[index];
        return _buildChallengeCard(scheme, challenge, index);
      },
    );
  }

  Widget _buildMyChallenges(ColorScheme scheme) {
    final joined = _challenges.where((c) => c.isJoined).toList();
    if (joined.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏅', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('No challenges joined yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: scheme.onSurface)),
            const SizedBox(height: 8),
            Text('Join a challenge to compete!', style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ).animate().fadeIn(),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: joined.length,
      itemBuilder: (context, index) => _buildChallengeCard(scheme, joined[index], index),
    );
  }

  Widget _buildPastWinners(ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('Coming Soon', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: scheme.onSurface)),
          const SizedBox(height: 8),
          Text('Past challenge winners will be displayed here', style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildChallengeCard(ColorScheme scheme, _Challenge challenge, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: scheme.shadow.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: challenge.isJoined ? AppColors.accentGradient : AppColors.primaryGradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(challenge.emoji, style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(challenge.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(height: 2),
                            Text(challenge.difficulty, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${challenge.daysLeft}d left',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(challenge.description, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.4)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Iconsax.people, size: 16, color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(width: 6),
                    Text('${challenge.participants} participants', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                    const Spacer(),
                    Text(challenge.prize, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          // Leaderboard preview
          if (challenge.leaderboard.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Leaderboard', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: scheme.onSurface)),
                  Text('Top ${challenge.leaderboard.length}', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            ...challenge.leaderboard.take(3).map((entry) {
              final medals = ['🥇', '🥈', '🥉'];
              return ListTile(
                dense: true,
                leading: Text(
                  entry.rank <= 3 ? medals[entry.rank - 1] : '#${entry.rank}',
                  style: const TextStyle(fontSize: 18),
                ),
                title: Text(entry.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                trailing: Text(
                  '${entry.score} pts',
                  style: TextStyle(fontWeight: FontWeight.w600, color: scheme.primary),
                ),
              );
            }),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: challenge.isJoined
                  ? OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Iconsax.tick_circle),
                      label: const Text('Joined - Submit Entry'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Joined ${challenge.title}! 🎉'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      icon: const Icon(Iconsax.flash_1),
                      label: const Text('Join Challenge'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
            ),
          ),
        ],
      ),
    ).animate(delay: (index * 100).ms).fadeIn().slideY(begin: 0.1);
  }
}
