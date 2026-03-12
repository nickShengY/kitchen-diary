import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// Swipeable recipe card (Tinder-style)
class SwipeableRecipeCard extends StatefulWidget {
  final String title;
  final String imageUrl;
  final String chef;
  final int cookTime;
  final String difficulty;
  final Function(String action)? onSwipe;

  const SwipeableRecipeCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.chef,
    required this.cookTime,
    required this.difficulty,
    this.onSwipe,
  });

  @override
  State<SwipeableRecipeCard> createState() => _SwipeableRecipeCardState();
}

class _SwipeableRecipeCardState extends State<SwipeableRecipeCard> {
  double _dragX = 0;
  double _dragY = 0;
  String? _actionHint;

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragX += details.delta.dx;
      _dragY += details.delta.dy;

      if (_dragX > 50) {
        _actionHint = 'save';
      } else if (_dragX < -50) {
        _actionHint = 'skip';
      } else if (_dragY < -50) {
        _actionHint = 'cook_now';
      } else {
        _actionHint = null;
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragX.abs() > 100 || _dragY.abs() > 100) {
      HapticFeedback.mediumImpact();
      widget.onSwipe?.call(_actionHint ?? 'skip');
    }
    setState(() {
      _dragX = 0;
      _dragY = 0;
      _actionHint = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rotation = _dragX / 1000;

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onDoubleTap: () {
        HapticFeedback.heavyImpact();
        widget.onSwipe?.call('super_like');
      },
      child: Transform(
        transform: Matrix4.identity()
          ..translate(_dragX, _dragY)
          ..rotateZ(rotation),
        alignment: Alignment.center,
        child: Stack(
          children: [
            // Card
            Container(
              width: 320,
              height: 450,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image
                    Image.network(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surface,
                        child: const Center(
                          child: Text('🥗', style: TextStyle(fontSize: 64)),
                        ),
                      ),
                    ),

                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),

                    // Content
                    Positioned(
                      bottom: 24,
                      left: 24,
                      right: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'by ${widget.chef}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _InfoChip(
                                  icon: Icons.timer,
                                  label: '${widget.cookTime} min'),
                              const SizedBox(width: 8),
                              _InfoChip(
                                  icon: Icons.restaurant,
                                  label: widget.difficulty),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action stamps
            if (_actionHint == 'save')
              const Positioned(
                top: 40,
                left: 20,
                child: _ActionStamp(
                  text: 'SAVE',
                  color: Colors.green,
                  rotation: -0.3,
                ),
              ),
            if (_actionHint == 'skip')
              const Positioned(
                top: 40,
                right: 20,
                child: _ActionStamp(
                  text: 'NOPE',
                  color: Colors.red,
                  rotation: 0.3,
                ),
              ),
            if (_actionHint == 'cook_now')
              const Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: _ActionStamp(
                    text: 'COOK NOW!',
                    color: Colors.blue,
                    rotation: 0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionStamp extends StatelessWidget {
  final String text;
  final Color color;
  final double rotation;

  const _ActionStamp({
    required this.text,
    required this.color,
    required this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ),
    ).animate().scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut);
  }
}

/// Cooking horoscope card
class CookingHoroscopeCard extends StatelessWidget {
  final String sign;
  final String emoji;
  final String element;
  final String todaysFlavor;
  final String luckyIngredient;
  final String cookingMood;
  final String recommendation;
  final VoidCallback? onTapRecipe;

  const CookingHoroscopeCard({
    super.key,
    required this.sign,
    required this.emoji,
    required this.element,
    required this.todaysFlavor,
    required this.luckyIngredient,
    required this.cookingMood,
    required this.recommendation,
    this.onTapRecipe,
  });

  Color get _elementColor {
    switch (element) {
      case 'fire':
        return const Color(0xFFFF6B6B);
      case 'earth':
        return const Color(0xFF2ECC71);
      case 'air':
        return const Color(0xFF3498DB);
      case 'water':
        return const Color(0xFF9B59B6);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _elementColor,
            _elementColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _elementColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sign,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${element.toUpperCase()} SIGN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Text('🔮', style: TextStyle(fontSize: 24)),
            ],
          ),

          const SizedBox(height: 20),

          // Stats
          Row(
            children: [
              _HoroscopeStat(
                  label: "Today's Flavor", value: todaysFlavor, emoji: '🌿'),
              _HoroscopeStat(
                  label: 'Lucky Ingredient',
                  value: luckyIngredient,
                  emoji: '🍎'),
            ],
          ),

          const SizedBox(height: 16),

          // Mood
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🔮', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      'Cooking Mood: $cookingMood',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  recommendation,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // CTA
          if (onTapRecipe != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTapRecipe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _elementColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'See Your Recipe 🥗',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HoroscopeStat extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;

  const _HoroscopeStat({
    required this.label,
    required this.value,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fortune cookie widget
class FortuneCookieWidget extends StatefulWidget {
  final VoidCallback? onOpen;

  const FortuneCookieWidget({
    super.key,
    this.onOpen,
  });

  @override
  State<FortuneCookieWidget> createState() => _FortuneCookieWidgetState();
}

class _FortuneCookieWidgetState extends State<FortuneCookieWidget>
    with SingleTickerProviderStateMixin {
  bool _isOpened = false;
  late AnimationController _shakeController;
  String? _fortune;

  final _fortunes = [
    'A pinch of patience makes the perfect dish 🍴',
    'Your next meal will bring unexpected joy 🌟',
    'Trust your taste buds, they know the way 👍',
    'The secret ingredient is always love ❤️',
    'A new cuisine awaits your discovery 🌍',
    'Leftovers today, gourmet tomorrow 🍴',
  ];

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _openCookie() {
    if (_isOpened) return;

    HapticFeedback.heavyImpact();
    setState(() {
      _isOpened = true;
      _fortune = _fortunes[math.Random().nextInt(_fortunes.length)];
    });
    widget.onOpen?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openCookie,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _isOpened ? _buildOpenedCookie() : _buildClosedCookie(),
      ),
    );
  }

  Widget _buildClosedCookie() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '🥠',
          style: TextStyle(fontSize: 100),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .rotate(begin: -0.05, end: 0.05, duration: 1000.ms)
            .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Tap to reveal your fortune!',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.brown,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOpenedCookie() {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🥠', style: TextStyle(fontSize: 48))
              .animate()
              .scale(begin: const Offset(0, 0), curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(
            _fortune ?? '',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.brown.shade800,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Share Fortune'),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    ).animate().scale(begin: const Offset(0.8, 0.8));
  }
}

/// Virtual food tour progress card
class FoodTourCard extends StatelessWidget {
  final String tourName;
  final String country;
  final String emoji;
  final int currentStop;
  final int totalStops;
  final int recipesCompleted;
  final int totalRecipes;
  final VoidCallback? onContinue;

  const FoodTourCard({
    super.key,
    required this.tourName,
    required this.country,
    required this.emoji,
    required this.currentStop,
    required this.totalStops,
    required this.recipesCompleted,
    required this.totalRecipes,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final progress = recipesCompleted / totalRecipes;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with flag
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tourName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        country,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Stop $currentStop/$totalStops',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Progress
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tour Progress',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$recipesCompleted/$totalRecipes recipes',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onContinue,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Continue Journey'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Weekly recap story card
class WeeklyRecapCard extends StatelessWidget {
  final int recipesCooked;
  final int newRecipes;
  final String favoriteRecipe;
  final String topCuisine;
  final int minutesCooking;
  final int xpEarned;
  final int currentStreak;
  final VoidCallback? onShare;

  const WeeklyRecapCard({
    super.key,
    required this.recipesCooked,
    required this.newRecipes,
    required this.favoriteRecipe,
    required this.topCuisine,
    required this.minutesCooking,
    required this.xpEarned,
    required this.currentStreak,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Text('📊', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          const Text(
            'Your Week in Review',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Stats grid
          Row(
            children: [
              _RecapStat(
                  value: '$recipesCooked', label: 'Recipes', emoji: '🥗'),
              _RecapStat(value: '$newRecipes', label: 'New', emoji: '✨'),
              _RecapStat(value: '$currentStreak', label: 'Streak', emoji: '🔥'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _RecapStat(
                  value: '${minutesCooking}m', label: 'Cooking', emoji: '🍳'),
              _RecapStat(value: '+$xpEarned', label: 'XP', emoji: '⭐'),
              _RecapStat(value: topCuisine, label: 'Top', emoji: '🌍'),
            ],
          ),

          const SizedBox(height: 24),

          // Favorite
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('❤️', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Week's Favorite",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        favoriteRecipe,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Share button
          if (onShare != null)
            OutlinedButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share, size: 18),
              label: const Text('Share Recap'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecapStat extends StatelessWidget {
  final String value;
  final String label;
  final String emoji;

  const _RecapStat({
    required this.value,
    required this.label,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Glassmorphism container
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsets padding;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.blur = 20,
    this.opacity = 0.2,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
