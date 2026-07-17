import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// A beautiful widget that visualizes ingredient state transformations
/// with smooth animations and particle effects.
class IngredientTransformationWidget extends StatefulWidget {
  final String ingredientName;
  final String emoji;
  final String fromState;
  final String toState;
  final Duration duration;
  final VoidCallback? onComplete;
  final bool autoPlay;

  const IngredientTransformationWidget({
    super.key,
    required this.ingredientName,
    required this.emoji,
    required this.fromState,
    required this.toState,
    this.duration = const Duration(milliseconds: 1500),
    this.onComplete,
    this.autoPlay = true,
  });

  @override
  State<IngredientTransformationWidget> createState() =>
      _IngredientTransformationWidgetState();
}

class _IngredientTransformationWidgetState
    extends State<IngredientTransformationWidget>
    with TickerProviderStateMixin {
  late AnimationController _transformController;
  late AnimationController _particleController;
  late AnimationController _glowController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _transformController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 0.8)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_transformController);

    _rotateAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 0.1)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.1, end: -0.1)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.1, end: 0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
    ]).animate(_transformController);

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _transformController,
        curve: const Interval(0.4, 0.6, curve: Curves.easeInOut),
      ),
    );

    _transformController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    if (widget.autoPlay) {
      _transformController.forward();
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void play() {
    _transformController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Particle background
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: _TransformationParticlesPainter(
                  progress: _particleController.value,
                  transformProgress: _transformController.value,
                  color: AppColors.primary,
                ),
                size: const Size(200, 200),
              );
            },
          ),

          // Glow effect
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                width: 120 + (_glowController.value * 20),
                height: 120 + (_glowController.value * 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: 0.2 + (_glowController.value * 0.1),
                      ),
                      blurRadius: 30 + (_glowController.value * 10),
                      spreadRadius: 5,
                    ),
                  ],
                ),
              );
            },
          ),

          // Main transformation content
          AnimatedBuilder(
            animation: _transformController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotateAnimation.value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // From state (fading out)
                      Opacity(
                        opacity: _fadeAnimation.value,
                        child: _buildStateVisual(
                          widget.emoji,
                          widget.fromState,
                          isFrom: true,
                        ),
                      ),

                      // To state (fading in)
                      Opacity(
                        opacity: 1 - _fadeAnimation.value,
                        child: _buildStateVisual(
                          _getTransformedEmoji(),
                          widget.toState,
                          isFrom: false,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // State labels
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _transformController,
              builder: (context, child) {
                final showToState = _transformController.value > 0.5;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey(showToState),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: showToState
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.textSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      showToState
                          ? _capitalizeFirst(widget.toState)
                          : _capitalizeFirst(widget.fromState),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: showToState
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateVisual(String emoji, String state, {required bool isFrom}) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isFrom ? AppColors.textSecondary : AppColors.primary)
                .withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 48),
        ),
      ),
    );
  }

  String _getTransformedEmoji() {
    // Could add logic to show different emoji based on transformation
    // For now, return the same emoji with a visual effect applied via animation
    return widget.emoji;
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

/// Particle painter for transformation effects
class _TransformationParticlesPainter extends CustomPainter {
  final double progress;
  final double transformProgress;
  final Color color;

  _TransformationParticlesPainter({
    required this.progress,
    required this.transformProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final random = math.Random(42);

    // Draw particles in a spiral pattern
    for (int i = 0; i < 20; i++) {
      final baseAngle = (i / 20) * math.pi * 2;
      final spiralOffset = progress * math.pi * 2;
      final angle = baseAngle + spiralOffset;

      final radiusBase = 60 + (random.nextDouble() * 30);
      final radiusPulse = math.sin(progress * math.pi * 2 + i) * 10;
      final radius = radiusBase + radiusPulse;

      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;

      final particleSize = 2 + random.nextDouble() * 3;
      final opacity = 0.3 + (math.sin(progress * math.pi * 4 + i) * 0.3);

      final paint = Paint()
        ..color =
            color.withValues(alpha: opacity * (1 - transformProgress * 0.5))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }

    // Draw burst particles during transformation peak
    if (transformProgress > 0.3 && transformProgress < 0.7) {
      final burstIntensity = 1 - ((transformProgress - 0.5).abs() * 5);

      for (int i = 0; i < 12; i++) {
        final angle = (i / 12) * math.pi * 2;
        final distance = 50 + (burstIntensity * 30);

        final x = center.dx + math.cos(angle) * distance;
        final y = center.dy + math.sin(angle) * distance;

        final paint = Paint()
          ..color = color.withValues(alpha: burstIntensity * 0.6)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(x, y), 4 * burstIntensity, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TransformationParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.transformProgress != transformProgress;
  }
}

/// A compact state badge widget
class StateBadge extends StatelessWidget {
  final String state;
  final bool isActive;
  final VoidCallback? onTap;

  const StateBadge({
    super.key,
    required this.state,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.divider.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _capitalizeFirst(state),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ).animate(target: isActive ? 1 : 0).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 200.ms,
        );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

/// A flow visualization showing state progression
class StateFlowVisualization extends StatelessWidget {
  final List<String> states;
  final int currentIndex;
  final Function(int)? onStateTap;

  const StateFlowVisualization({
    super.key,
    required this.states,
    this.currentIndex = 0,
    this.onStateTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(states.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Arrow connector
            final stateIndex = index ~/ 2;
            final isPast = stateIndex < currentIndex;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: isPast
                    ? AppColors.primary
                    : AppColors.textSecondary.withValues(alpha: 0.3),
              ),
            ).animate(delay: Duration(milliseconds: index * 50)).fadeIn();
          } else {
            // State badge
            final stateIndex = index ~/ 2;
            final isActive = stateIndex == currentIndex;
            final isPast = stateIndex < currentIndex;

            return StateBadge(
              state: states[stateIndex],
              isActive: isActive || isPast,
              onTap: onStateTap != null ? () => onStateTap!(stateIndex) : null,
            )
                .animate(delay: Duration(milliseconds: index * 50))
                .fadeIn()
                .slideX(
                  begin: 0.2,
                  end: 0,
                );
          }
        }),
      ),
    );
  }
}
