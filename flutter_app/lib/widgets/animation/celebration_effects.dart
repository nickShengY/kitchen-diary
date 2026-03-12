import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';
import '../../services/haptic_service.dart';

/// A confetti celebration overlay for recipe completion.
class ConfettiCelebration extends StatefulWidget {
  final VoidCallback? onComplete;
  final Duration duration;
  final int particleCount;
  final List<String> emojis;
  final List<Color> colors;

  const ConfettiCelebration({
    super.key,
    this.onComplete,
    this.duration = const Duration(seconds: 3),
    this.particleCount = 50,
    this.emojis = const ['🎉', '✨', '🌟', '🎈', '⭐'],
    this.colors = const [
      Color(0xFFFF6B6B),
      Color(0xFF4ECDC4),
      Color(0xFFFFE66D),
      Color(0xFFFF9F43),
      Color(0xFFA55EEA),
    ],
  });

  /// Show confetti celebration as an overlay
  static void show(
    BuildContext context, {
    VoidCallback? onComplete,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => ConfettiCelebration(
        duration: duration,
        onComplete: () {
          entry.remove();
          onComplete?.call();
        },
      ),
    );

    overlay.insert(entry);
    HapticFeedback.heavyImpact();
  }

  @override
  State<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends State<ConfettiCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ConfettiParticle> _particles;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _particles = List.generate(widget.particleCount, (index) {
      return _ConfettiParticle(
        emoji: widget.emojis[_random.nextInt(widget.emojis.length)],
        color: widget.colors[_random.nextInt(widget.colors.length)],
        startX: _random.nextDouble(),
        startY: -0.1 - (_random.nextDouble() * 0.3),
        velocityX: (_random.nextDouble() - 0.5) * 0.3,
        velocityY: 0.3 + _random.nextDouble() * 0.4,
        rotation: _random.nextDouble() * 360,
        rotationSpeed: (_random.nextDouble() - 0.5) * 720,
        size: 16 + _random.nextDouble() * 16,
        delay: _random.nextDouble() * 0.3,
      );
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _controller.value,
            ),
            size: MediaQuery.of(context).size,
          );
        },
      ),
    );
  }
}

class _ConfettiParticle {
  final String emoji;
  final Color color;
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final double rotation;
  final double rotationSpeed;
  final double size;
  final double delay;

  _ConfettiParticle({
    required this.emoji,
    required this.color,
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.delay,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final adjustedProgress =
          ((progress - particle.delay) / (1 - particle.delay)).clamp(0.0, 1.0);

      if (adjustedProgress <= 0) continue;

      final x = (particle.startX + particle.velocityX * adjustedProgress) *
          size.width;
      final y = (particle.startY +
              particle.velocityY * adjustedProgress +
              0.5 * adjustedProgress * adjustedProgress) *
          size.height;
      final opacity = (1 - adjustedProgress).clamp(0.0, 1.0);
      final rotation =
          particle.rotation + particle.rotationSpeed * adjustedProgress;

      if (y > size.height || opacity <= 0) continue;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation * math.pi / 180);

      final textPainter = TextPainter(
        text: TextSpan(
          text: particle.emoji,
          style: TextStyle(
            fontSize: particle.size,
            color: Colors.white.withValues(alpha: opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Sparkle effect for step completion
class SparkleEffect extends StatefulWidget {
  final Offset center;
  final VoidCallback? onComplete;
  final int particleCount;
  final Duration duration;

  const SparkleEffect({
    super.key,
    required this.center,
    this.onComplete,
    this.particleCount = 8,
    this.duration = const Duration(milliseconds: 800),
  });

  static void showAt(
    BuildContext context,
    Offset position, {
    VoidCallback? onComplete,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        left: 0,
        top: 0,
        child: SparkleEffect(
          center: position,
          onComplete: () {
            entry.remove();
            onComplete?.call();
          },
        ),
      ),
    );

    overlay.insert(entry);
    HapticFeedback.lightImpact();
  }

  @override
  State<SparkleEffect> createState() => _SparkleEffectState();
}

class _SparkleEffectState extends State<SparkleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _SparklePainter(
              center: widget.center,
              progress: _controller.value,
              particleCount: widget.particleCount,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Offset center;
  final double progress;
  final int particleCount;

  _SparklePainter({
    required this.center,
    required this.progress,
    required this.particleCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi;
      final distance = 20 + progress * 40;
      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final particleSize = 4 * (1 - progress * 0.5);

      paint.color = Color.lerp(
        const Color(0xFFFFD700),
        const Color(0xFFFFA500),
        i / particleCount,
      )!
          .withValues(alpha: opacity);

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Success checkmark animation
class SuccessCheckmark extends StatelessWidget {
  final double size;
  final Color color;
  final Duration duration;

  const SuccessCheckmark({
    super.key,
    this.size = 80,
    this.color = const Color(0xFF4ECDC4),
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circle background
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
          ).animate().scale(
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
                duration: duration * 0.5,
                curve: Curves.easeOutBack,
              ),

          // Circle border
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
            ),
          ).animate().scale(
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
                duration: duration * 0.5,
                curve: Curves.easeOutBack,
              ),

          // Checkmark
          Icon(
            Icons.check_rounded,
            size: size * 0.5,
            color: color,
          ).animate(delay: duration * 0.3).scale(
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
                duration: duration * 0.4,
                curve: Curves.elasticOut,
              ),
        ],
      ),
    );
  }
}

/// Animated star rating for recipe completion
class AnimatedStarRating extends StatelessWidget {
  final int starCount;
  final int filledStars;
  final double size;
  final Duration staggerDuration;

  const AnimatedStarRating({
    super.key,
    this.starCount = 5,
    required this.filledStars,
    this.size = 32,
    this.staggerDuration = const Duration(milliseconds: 150),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) {
        final isFilled = index < filledStars;
        return Icon(
          isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: isFilled ? const Color(0xFFFFD700) : Colors.grey.shade300,
        )
            .animate(delay: staggerDuration * index)
            .scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              duration: 400.ms,
              curve: Curves.elasticOut,
            )
            .then()
            .shimmer(
              duration: 1000.ms,
              color: isFilled
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.transparent,
            );
      }),
    );
  }
}

/// Ingredient suggestion chip with pairing info
class IngredientPairingChip extends StatelessWidget {
  final String ingredientName;
  final String emoji;
  final bool isPaired;
  final VoidCallback? onTap;

  const IngredientPairingChip({
    super.key,
    required this.ingredientName,
    required this.emoji,
    this.isPaired = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService().trigger('selection');
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isPaired
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPaired
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              ingredientName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isPaired ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            if (isPaired) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.favorite,
                size: 12,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    ).animate(target: isPaired ? 1 : 0).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 200.ms,
        );
  }
}

/// Cooking tip tooltip
class CookingTipBubble extends StatelessWidget {
  final String tip;
  final String actionEmoji;

  const CookingTipBubble({
    super.key,
    required this.tip,
    required this.actionEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(actionEmoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 14,
                      color: AppColors.accent,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Pro Tip',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }
}
