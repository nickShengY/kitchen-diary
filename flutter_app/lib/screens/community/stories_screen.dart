import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_theme.dart';

class _Story {
  final String id;
  final String authorName;
  final String authorAvatar;
  final String caption;
  final String recipe;
  final int likes;
  final int comments;
  final String timeAgo;
  final bool isLiked;
  final List<String> tags;

  const _Story({
    required this.id,
    required this.authorName,
    required this.authorAvatar,
    required this.caption,
    required this.recipe,
    this.likes = 0,
    this.comments = 0,
    required this.timeAgo,
    this.isLiked = false,
    this.tags = const [],
  });
}

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<_Story> _stories = [
    _Story(
      id: '1',
      authorName: 'Chef Maria',
      authorAvatar: '👩‍🍳',
      caption:
          'Just made the most incredible pasta carbonara! The secret is using pecorino romano and fresh eggs from the market 🍝✨',
      recipe: 'Classic Carbonara',
      likes: 234,
      comments: 18,
      timeAgo: '2h ago',
      tags: ['Italian', 'Pasta', 'Quick'],
    ),
    _Story(
      id: '2',
      authorName: 'BakeKing',
      authorAvatar: '👨‍🍳',
      caption:
          'Sourdough day 7 - look at that crumb! 😍🍞 Starting to get consistent results with my new starter',
      recipe: 'Artisan Sourdough',
      likes: 456,
      comments: 42,
      timeAgo: '4h ago',
      isLiked: true,
      tags: ['Baking', 'Bread', 'Sourdough'],
    ),
    _Story(
      id: '3',
      authorName: 'HealthyBites',
      authorAvatar: '🧑‍🍳',
      caption:
          'Meal prep Sunday done right! 5 lunches ready for the week 💪🥗 All under 500 cal',
      recipe: 'Mediterranean Bowl',
      likes: 189,
      comments: 24,
      timeAgo: '6h ago',
      tags: ['MealPrep', 'Healthy', 'Budget'],
    ),
    _Story(
      id: '4',
      authorName: 'SpiceWorld',
      authorAvatar: '👩‍🍳',
      caption:
          'Homemade ramen from scratch! 12 hours of broth simmering was SO worth it 🍜🔥',
      recipe: 'Tonkotsu Ramen',
      likes: 567,
      comments: 56,
      timeAgo: '8h ago',
      tags: ['Japanese', 'Ramen', 'FromScratch'],
    ),
    _Story(
      id: '5',
      authorName: 'DessertQueen',
      authorAvatar: '👩‍🍳',
      caption:
          'Mirror glaze cake for my sister\'s birthday! First time doing galaxy theme 🌌🎂',
      recipe: 'Galaxy Mirror Cake',
      likes: 892,
      comments: 78,
      timeAgo: '12h ago',
      isLiked: true,
      tags: ['Baking', 'Cake', 'Birthday'],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kitchen Stories',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.camera, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Share your cooking story! 📸'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            tooltip: 'Create story',
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemCount: _stories.length,
        itemBuilder: (context, index) {
          final story = _stories[index];
          return _buildStoryPage(context, scheme, story, index);
        },
      ),
    );
  }

  Widget _buildStoryPage(
      BuildContext context, ColorScheme scheme, _Story story, int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryDark.withValues(alpha: 0.9),
                AppColors.backgroundDark,
                Colors.black,
              ],
            ),
          ),
        ),

        // Food emoji as large background
        Positioned(
          top: MediaQuery.of(context).size.height * 0.15,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              _getFoodEmoji(story.tags),
              style: const TextStyle(fontSize: 180),
            ).animate().scale(
                begin: const Offset(0.8, 0.8),
                duration: 600.ms,
                curve: Curves.elasticOut),
          ),
        ),

        // Content overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black.withValues(alpha: 0.95),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Author info
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                          child: Text(story.authorAvatar,
                              style: const TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(story.authorName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                        Text(story.timeAgo,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12)),
                      ],
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                      ),
                      child:
                          const Text('Follow', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Caption
                Text(
                  story.caption,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16, height: 1.5),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 12),

                // Recipe tag
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.note_2, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(story.recipe,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Tags
                Wrap(
                  spacing: 8,
                  children: story.tags
                      .map((t) => Text(
                            '#$t',
                            style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ))
                      .toList(),
                ),

                const SizedBox(height: 20),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _storyAction(
                      icon: story.isLiked ? Iconsax.heart5 : Iconsax.heart,
                      label: '${story.likes}',
                      color: story.isLiked ? Colors.redAccent : Colors.white,
                      onTap: () => HapticFeedback.lightImpact(),
                    ),
                    _storyAction(
                      icon: Iconsax.message,
                      label: '${story.comments}',
                      color: Colors.white,
                      onTap: () {},
                    ),
                    _storyAction(
                      icon: Iconsax.share,
                      label: 'Share',
                      color: Colors.white,
                      onTap: () {},
                    ),
                    _storyAction(
                      icon: Iconsax.save_2,
                      label: 'Save',
                      color: Colors.white,
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Progress dots
        Positioned(
          right: 12,
          top: MediaQuery.of(context).padding.top + 60,
          child: Column(
            children: List.generate(_stories.length, (i) {
              return Container(
                width: 4,
                height: i == _currentIndex ? 24 : 8,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: i == _currentIndex ? Colors.white : Colors.white38,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  String _getFoodEmoji(List<String> tags) {
    if (tags.contains('Pasta') || tags.contains('Italian')) return '🍝';
    if (tags.contains('Bread') ||
        tags.contains('Baking') ||
        tags.contains('Sourdough')) return '🍞';
    if (tags.contains('Healthy') || tags.contains('MealPrep')) return '🥗';
    if (tags.contains('Japanese') || tags.contains('Ramen')) return '🍜';
    if (tags.contains('Cake') || tags.contains('Birthday')) return '🎂';
    return '🍽️';
  }

  Widget _storyAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
