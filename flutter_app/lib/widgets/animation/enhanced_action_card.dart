import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// Enhanced action card with visual cues, difficulty indicators,
/// and haptic feedback patterns for the animation composer.
class EnhancedActionCard extends StatefulWidget {
  final String actionId;
  final String label;
  final String icon;
  final String verb;
  final int difficulty;
  final int estimatedSeconds;
  final String colorAccent;
  final List<String> visualCues;
  final bool isSelected;
  final bool isCompatible;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const EnhancedActionCard({
    super.key,
    required this.actionId,
    required this.label,
    required this.icon,
    required this.verb,
    this.difficulty = 1,
    this.estimatedSeconds = 30,
    this.colorAccent = '#FF6B6B',
    this.visualCues = const [],
    this.isSelected = false,
    this.isCompatible = true,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<EnhancedActionCard> createState() => _EnhancedActionCardState();
}

class _EnhancedActionCardState extends State<EnhancedActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  Color get _accentColor {
    try {
      final hex = widget.colorAccent.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  void _handleTap() {
    if (!widget.isCompatible) {
      HapticFeedback.heavyImpact();
      return;
    }
    
    // Trigger haptic based on action type
    _triggerHaptic();
    widget.onTap?.call();
  }

  void _triggerHaptic() {
    switch (widget.difficulty) {
      case 1:
        HapticFeedback.lightImpact();
        break;
      case 2:
        HapticFeedback.mediumImpact();
        break;
      case 3:
        HapticFeedback.heavyImpact();
        break;
      default:
        HapticFeedback.selectionClick();
    }
  }

  String _formatTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m';
    return '${seconds ~/ 3600}h';
  }

  @override
  Widget build(BuildContext context) {
    final opacity = widget.isCompatible ? 1.0 : 0.4;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: GestureDetector(
        onTap: _handleTap,
        onLongPress: widget.onLongPress,
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            final scale = 1.0 + (_hoverController.value * 0.02);
            
            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? _accentColor.withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.isSelected
                          ? _accentColor.withValues(alpha: 0.5)
                          : _isHovered
                              ? _accentColor.withValues(alpha: 0.3)
                              : AppColors.divider,
                      width: widget.isSelected ? 2 : 1,
                    ),
                    boxShadow: widget.isSelected || _isHovered
                        ? [
                            BoxShadow(
                              color: _accentColor.withValues(alpha: 0.15),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header row
                      Row(
                        children: [
                          // Icon container with accent color
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                widget.icon,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Title and verb
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.label,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: widget.isSelected
                                        ? _accentColor
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.verb.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    color: AppColors.textSecondary
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Difficulty indicator
                          _DifficultyBadge(
                            difficulty: widget.difficulty,
                            color: _accentColor,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Info row
                      Row(
                        children: [
                          // Time estimate
                          _InfoChip(
                            icon: Icons.timer_outlined,
                            label: _formatTime(widget.estimatedSeconds),
                            color: _accentColor,
                          ),
                          const SizedBox(width: 8),
                          
                          // Visual cue count
                          if (widget.visualCues.isNotEmpty)
                            _InfoChip(
                              icon: Icons.auto_awesome_outlined,
                              label: '${widget.visualCues.length} effects',
                              color: _accentColor,
                            ),
                          
                          const Spacer(),
                          
                          // Selected indicator
                          if (widget.isSelected)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _accentColor,
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
                      
                      // Visual cues preview (on hover or selected)
                      if ((_isHovered || widget.isSelected) &&
                          widget.visualCues.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: widget.visualCues
                              .take(4)
                              .map((cue) => _VisualCueTag(
                                    label: cue,
                                    color: _accentColor,
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ).animate(target: widget.isSelected ? 1 : 0).shimmer(
          duration: 1500.ms,
          color: _accentColor.withValues(alpha: 0.1),
        );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final int difficulty;
  final Color color;

  const _DifficultyBadge({required this.difficulty, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isActive = index < difficulty;
        return Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? color : color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualCueTag extends StatelessWidget {
  final String label;
  final Color color;

  const _VisualCueTag({required this.label, required this.color});

  String _formatCue(String cue) {
    return cue.replaceAll('-', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        _formatCue(label),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

/// A beautiful drag handle for reorderable lists
class AnimationStepDragHandle extends StatelessWidget {
  final bool isDragging;

  const AnimationStepDragHandle({super.key, this.isDragging = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 44,
      decoration: BoxDecoration(
        color: isDragging
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _DragLine(isDragging: isDragging),
          const SizedBox(height: 3),
          _DragLine(isDragging: isDragging),
          const SizedBox(height: 3),
          _DragLine(isDragging: isDragging),
        ],
      ),
    );
  }
}

class _DragLine extends StatelessWidget {
  final bool isDragging;

  const _DragLine({required this.isDragging});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 2,
      decoration: BoxDecoration(
        color: isDragging
            ? AppColors.primary
            : AppColors.textSecondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

/// Animated connector between timeline steps
class TimelineConnector extends StatelessWidget {
  final bool isActive;
  final bool isAnimating;
  final Color? color;

  const TimelineConnector({
    super.key,
    this.isActive = false,
    this.isAnimating = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final lineColor = color ?? (isActive ? AppColors.primary : AppColors.divider);

    return SizedBox(
      width: 40,
      height: 2,
      child: Stack(
        children: [
          // Background line
          Container(
            width: double.infinity,
            height: 2,
            color: lineColor.withValues(alpha: isActive ? 1.0 : 0.3),
          ),
          
          // Animated pulse if animating
          if (isAnimating)
            Positioned.fill(
              child: _AnimatedPulse(color: lineColor),
            ),
        ],
      ),
    );
  }
}

class _AnimatedPulse extends StatefulWidget {
  final Color color;

  const _AnimatedPulse({required this.color});

  @override
  State<_AnimatedPulse> createState() => _AnimatedPulseState();
}

class _AnimatedPulseState extends State<_AnimatedPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _PulsePainter(
            progress: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _PulsePainter extends CustomPainter {
  final double progress;
  final Color color;

  _PulsePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 1 - progress)
      ..style = PaintingStyle.fill;

    final x = progress * size.width;
    canvas.drawCircle(Offset(x, size.height / 2), 4 * (1 - progress), paint);
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Floating action button for animation preview
class AnimationPreviewFAB extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback? onPressed;

  const AnimationPreviewFAB({
    super.key,
    this.isPlaying = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onPressed?.call();
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.8),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            key: ValueKey(isPlaying),
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    ).animate(target: isPlaying ? 1 : 0).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.1, 1.1),
          curve: Curves.easeOutBack,
          duration: 200.ms,
        );
  }
}

