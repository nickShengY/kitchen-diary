import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// A beautiful circular cooking progress indicator that shows
/// the state transformation journey with visual feedback.
class CookingProgressIndicator extends StatefulWidget {
  final double progress;
  final String currentState;
  final String? nextState;
  final String emoji;
  final Color? primaryColor;
  final double size;
  final bool showLabels;
  final bool animate;

  const CookingProgressIndicator({
    super.key,
    required this.progress,
    required this.currentState,
    this.nextState,
    required this.emoji,
    this.primaryColor,
    this.size = 120,
    this.showLabels = true,
    this.animate = true,
  });

  @override
  State<CookingProgressIndicator> createState() =>
      _CookingProgressIndicatorState();
}

class _CookingProgressIndicatorState extends State<CookingProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.primaryColor ?? AppColors.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size + (widget.showLabels ? 40 : 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background ring
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _ProgressRingPainter(
                    progress: 1.0,
                    color: color.withValues(alpha: 0.1),
                    strokeWidth: 8,
                  ),
                ),

                // Progress ring with animation
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final pulseScale = widget.animate
                        ? 1.0 + (_pulseController.value * 0.02)
                        : 1.0;

                    return Transform.scale(
                      scale: pulseScale,
                      child: CustomPaint(
                        size: Size(widget.size, widget.size),
                        painter: _ProgressRingPainter(
                          progress: widget.progress,
                          color: color,
                          strokeWidth: 8,
                          hasGlow: widget.animate,
                        ),
                      ),
                    );
                  },
                ),

                // Particle effects at progress point
                if (widget.animate)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size(widget.size, widget.size),
                        painter: _ProgressParticlesPainter(
                          progress: widget.progress,
                          animationValue: _pulseController.value,
                          color: color,
                          radius: widget.size / 2 - 4,
                        ),
                      );
                    },
                  ),

                // Center content
                Container(
                  width: widget.size * 0.65,
                  height: widget.size * 0.65,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.emoji,
                        style: TextStyle(fontSize: widget.size * 0.25),
                      ),
                      if (widget.showLabels) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${(widget.progress * 100).round()}%',
                          style: TextStyle(
                            fontSize: widget.size * 0.12,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Progress notches
                ...List.generate(12, (index) {
                  final angle = (index / 12) * 2 * math.pi - math.pi / 2;
                  final isActive = index / 12 <= widget.progress;
                  final notchRadius = widget.size / 2 - 20;

                  return Positioned(
                    left: widget.size / 2 + math.cos(angle) * notchRadius - 3,
                    top: widget.size / 2 + math.sin(angle) * notchRadius - 3,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive ? color : color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // State labels
          if (widget.showLabels) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _capitalizeFirst(widget.currentState),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                if (widget.nextState != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    _capitalizeFirst(widget.nextState!),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final bool hasGlow;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    this.hasGlow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (hasGlow) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = strokeWidth + 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        glowPaint,
      );
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _ProgressParticlesPainter extends CustomPainter {
  final double progress;
  final double animationValue;
  final Color color;
  final double radius;

  _ProgressParticlesPainter({
    required this.progress,
    required this.animationValue,
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final progressAngle = 2 * math.pi * progress - math.pi / 2;

    // Draw particles at progress point
    final progressPoint = Offset(
      center.dx + math.cos(progressAngle) * radius,
      center.dy + math.sin(progressAngle) * radius,
    );

    final random = math.Random(42);
    for (int i = 0; i < 5; i++) {
      final offset = (animationValue + i * 0.2) % 1.0;
      final particleOffset = Offset(
        (random.nextDouble() - 0.5) * 20 * offset,
        (random.nextDouble() - 0.5) * 20 * offset - offset * 10,
      );

      final paint = Paint()
        ..color = color.withValues(alpha: (1 - offset) * 0.6)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        progressPoint + particleOffset,
        3 * (1 - offset),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressParticlesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.progress != progress;
  }
}

/// A horizontal timeline showing cooking steps progress
class CookingTimeline extends StatelessWidget {
  final List<CookingTimelineStep> steps;
  final int currentIndex;
  final Function(int)? onStepTap;
  final double height;

  const CookingTimeline({
    super.key,
    required this.steps,
    this.currentIndex = 0,
    this.onStepTap,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: steps.length,
        itemBuilder: (context, index) {
          final step = steps[index];
          final isActive = index == currentIndex;
          final isPast = index < currentIndex;
          final isLast = index == steps.length - 1;

          return Row(
            children: [
              GestureDetector(
                onTap: onStepTap != null ? () => onStepTap!(index) : null,
                child: _TimelineStepWidget(
                  step: step,
                  isActive: isActive,
                  isPast: isPast,
                  index: index,
                ),
              ),
              if (!isLast)
                _TimelineConnector(
                  isActive: isPast,
                ),
            ],
          )
              .animate(delay: Duration(milliseconds: index * 50))
              .fadeIn()
              .slideX(begin: 0.1, end: 0);
        },
      ),
    );
  }
}

class _TimelineStepWidget extends StatelessWidget {
  final CookingTimelineStep step;
  final bool isActive;
  final bool isPast;
  final int index;

  const _TimelineStepWidget({
    required this.step,
    required this.isActive,
    required this.isPast,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isActive || isPast ? AppColors.primary : AppColors.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isActive ? 56 : 48,
          height: isActive ? 56 : 48,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : isPast
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.divider.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  isActive || isPast ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              step.emoji,
              style: TextStyle(
                fontSize: isActive ? 24 : 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          step.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  final bool isActive;

  const _TimelineConnector({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.divider,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

/// Data class for timeline steps
class CookingTimelineStep {
  final String id;
  final String label;
  final String emoji;
  final String? state;

  const CookingTimelineStep({
    required this.id,
    required this.label,
    required this.emoji,
    this.state,
  });
}

/// A glassmorphic card for cooking actions
class CookingActionCard extends StatelessWidget {
  final String title;
  final String emoji;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback? onTap;

  const CookingActionCard({
    super.key,
    required this.title,
    required this.emoji,
    this.subtitle,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    ).animate(target: isSelected ? 1 : 0).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.02, 1.02),
          duration: 150.ms,
        );
  }
}
