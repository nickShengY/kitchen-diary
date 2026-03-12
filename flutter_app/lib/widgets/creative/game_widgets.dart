import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// Mini game: Speed Chop
class SpeedChopGame extends StatefulWidget {
  final int targetCount;
  final Duration duration;
  final Function(int score)? onComplete;

  const SpeedChopGame({
    super.key,
    this.targetCount = 20,
    this.duration = const Duration(seconds: 10),
    this.onComplete,
  });

  @override
  State<SpeedChopGame> createState() => _SpeedChopGameState();
}

class _SpeedChopGameState extends State<SpeedChopGame> {
  int _count = 0;
  bool _isPlaying = false;
  bool _isComplete = false;
  int _timeLeft = 10;
  Timer? _timer;

  final _ingredients = ['🥕', '🧅', '🧄', '🍎', '🥬', '🧁', '🍅'];
  String _currentIngredient = '🥕';

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _count = 0;
      _timeLeft = widget.duration.inSeconds;
      _currentIngredient =
          _ingredients[math.Random().nextInt(_ingredients.length)];
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          _endGame();
        }
      });
    });
  }

  void _chop() {
    if (!_isPlaying) return;

    HapticFeedback.lightImpact();
    setState(() {
      _count++;
      _currentIngredient =
          _ingredients[math.Random().nextInt(_ingredients.length)];
    });
  }

  void _endGame() {
    _timer?.cancel();
    setState(() {
      _isPlaying = false;
      _isComplete = true;
    });
    widget.onComplete?.call(_count);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPlaying && !_isComplete) {
      return _buildStartScreen();
    }

    if (_isComplete) {
      return _buildResultScreen();
    }

    return _buildGameScreen();
  }

  Widget _buildStartScreen() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🔪', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        const Text(
          'Speed Chop!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tap as fast as you can to chop ingredients!',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _startGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: const Text(
            'START!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _buildGameScreen() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Timer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer,
              color: _timeLeft <= 3 ? Colors.red : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              '$_timeLeft',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: _timeLeft <= 3 ? Colors.red : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Chops: $_count',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 24),

        // Chop button
        GestureDetector(
          onTap: _chop,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _currentIngredient,
                style: const TextStyle(fontSize: 64),
              ).animate(onPlay: (c) => c.forward(from: 0)).scale(
                  begin: const Offset(1.2, 1.2),
                  end: const Offset(1, 1),
                  duration: 100.ms),
            ),
          ),
        ),

        const SizedBox(height: 16),
        const Text(
          'TAP TAP TAP!',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildResultScreen() {
    final rating = _count >= 30 ? '🏆' : (_count >= 20 ? '⭐' : '👍');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(rating, style: const TextStyle(fontSize: 64))
            .animate()
            .scale(begin: const Offset(0, 0), curve: Curves.elasticOut),
        const SizedBox(height: 16),
        Text(
          '$_count chops!',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _count >= 30
              ? 'Chef Level: Master! 🔥'
              : (_count >= 20 ? 'Nice chopping!' : 'Keep practicing!'),
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _isComplete = false;
                  _count = 0;
                });
              },
              child: const Text('Play Again'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Mystery Box Challenge
class MysteryBoxChallenge extends StatefulWidget {
  final Function(List<String> ingredients)? onStart;

  const MysteryBoxChallenge({
    super.key,
    this.onStart,
  });

  @override
  State<MysteryBoxChallenge> createState() => _MysteryBoxChallengeState();
}

class _MysteryBoxChallengeState extends State<MysteryBoxChallenge> {
  bool _revealed = false;
  List<String> _ingredients = [];

  final _allIngredients = [
    {'emoji': '🍗', 'name': 'Chicken'},
    {'emoji': '🥩', 'name': 'Beef'},
    {'emoji': '🐟', 'name': 'Fish'},
    {'emoji': '🥕', 'name': 'Carrot'},
    {'emoji': '🧅', 'name': 'Onion'},
    {'emoji': '🧄', 'name': 'Garlic'},
    {'emoji': '🍅', 'name': 'Tomato'},
    {'emoji': '🥬', 'name': 'Lettuce'},
    {'emoji': '🧁', 'name': 'Pepper'},
    {'emoji': '🍋', 'name': 'Lemon'},
    {'emoji': '🧀', 'name': 'Cheese'},
    {'emoji': '🥚', 'name': 'Eggs'},
    {'emoji': '🍝', 'name': 'Pasta'},
    {'emoji': '🍚', 'name': 'Rice'},
    {'emoji': '🥔', 'name': 'Potato'},
  ];

  void _reveal() {
    HapticFeedback.heavyImpact();
    final random = math.Random();
    final shuffled = List.from(_allIngredients)..shuffle(random);

    setState(() {
      _revealed = true;
      _ingredients = shuffled.take(3).map((i) => i['emoji'] as String).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.purple.shade400, Colors.purple.shade700],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🎁 Mystery Box Challenge',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a dish with these 3 random ingredients!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (!_revealed) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MysteryIngredient(),
                const SizedBox(width: 16),
                _MysteryIngredient(),
                const SizedBox(width: 16),
                _MysteryIngredient(),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _reveal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.purple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'REVEAL! 🎉',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _ingredients.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  )
                      .animate(delay: Duration(milliseconds: entry.key * 200))
                      .scale(
                          begin: const Offset(0, 0), curve: Curves.elasticOut),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => widget.onStart?.call(_ingredients),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.purple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Accept Challenge! 🍳',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MysteryIngredient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
      ),
      child: const Center(
        child: Text('❓', style: TextStyle(fontSize: 40)),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
        begin: const Offset(1, 1),
        end: const Offset(1.05, 1.05),
        duration: 800.ms);
  }
}

/// Extended reactions bar
class ExtendedReactionsBar extends StatelessWidget {
  final List<ReactionType> reactions;
  final Map<String, int> counts;
  final String? selectedReaction;
  final Function(String reactionId)? onReact;

  const ExtendedReactionsBar({
    super.key,
    required this.reactions,
    this.counts = const {},
    this.selectedReaction,
    this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactions.asMap().entries.map((entry) {
          final reaction = entry.value;
          final isSelected = reaction.id == selectedReaction;
          final count = counts[reaction.id] ?? 0;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onReact?.call(reaction.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 12 : 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected ? reaction.color.withValues(alpha: 0.2) : null,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      reaction.emoji,
                      style: TextStyle(fontSize: isSelected ? 24 : 20),
                    ),
                    if (count > 0 || isSelected) ...[
                      const SizedBox(width: 4),
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? reaction.color
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
                .animate(delay: Duration(milliseconds: entry.key * 50))
                .fadeIn()
                .scale(begin: const Offset(0.8, 0.8)),
          );
        }).toList(),
      ),
    );
  }
}

class ReactionType {
  final String id;
  final String emoji;
  final String label;
  final Color color;

  const ReactionType({
    required this.id,
    required this.emoji,
    required this.label,
    required this.color,
  });
}

/// Daily cooking prompt
class DailyPromptCard extends StatelessWidget {
  final String promptType;
  final String prompt;
  final String emoji;
  final Color color;
  final VoidCallback? onAccept;
  final VoidCallback? onSkip;

  const DailyPromptCard({
    super.key,
    required this.promptType,
    required this.prompt,
    required this.emoji,
    required this.color,
    this.onAccept,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Text('📅', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 6),
                    Text(
                      "Today's Prompt",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                promptType.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            prompt,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSkip,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Let's Cook! 🍳",
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ingredient story card
class IngredientStoryCard extends StatelessWidget {
  final String ingredient;
  final String title;
  final String emoji;
  final String origin;
  final VoidCallback? onTap;

  const IngredientStoryCard({
    super.key,
    required this.ingredient,
    required this.title,
    required this.emoji,
    required this.origin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '📍 $origin',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
