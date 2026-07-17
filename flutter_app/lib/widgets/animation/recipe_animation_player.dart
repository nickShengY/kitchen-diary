import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_theme.dart';
import '../../models/animation_model.dart';

/// A beautiful, interactive recipe animation player that shows
/// cooking steps with ingredient transformations and particle effects.
class RecipeAnimationPlayer extends StatefulWidget {
  final RecipeAnimation animation;
  final bool autoPlay;
  final VoidCallback? onComplete;
  final Function(int)? onStepChange;

  const RecipeAnimationPlayer({
    super.key,
    required this.animation,
    this.autoPlay = false,
    this.onComplete,
    this.onStepChange,
  });

  @override
  State<RecipeAnimationPlayer> createState() => _RecipeAnimationPlayerState();
}

class _RecipeAnimationPlayerState extends State<RecipeAnimationPlayer>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _pulseController;

  late RecipeAnimation _currentAnimation;
  Timer? _autoPlayTimer;
  bool _isPlaying = false;
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentAnimation = widget.animation;

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    if (widget.autoPlay) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _mainController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    setState(() => _isPlaying = true);
    _scheduleNextStep();
  }

  void _scheduleNextStep() {
    final currentStep = _currentAnimation.steps.isNotEmpty &&
            _currentStepIndex < _currentAnimation.steps.length
        ? _currentAnimation.steps[_currentStepIndex]
        : null;

    final duration = currentStep?.duration ?? const Duration(seconds: 2);

    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer(duration, () {
      if (_isPlaying && mounted) {
        _nextStep();
      }
    });
  }

  void _togglePlayPause() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _scheduleNextStep();
      } else {
        _autoPlayTimer?.cancel();
      }
    });
  }

  void _nextStep() {
    if (_currentStepIndex < _currentAnimation.steps.length - 1) {
      HapticFeedback.lightImpact();
      _mainController.forward(from: 0);
      setState(() {
        _currentStepIndex++;
      });
      widget.onStepChange?.call(_currentStepIndex);
      if (_isPlaying) {
        _scheduleNextStep();
      }
    } else {
      setState(() {
        _isPlaying = false;
      });
      widget.onComplete?.call();
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      HapticFeedback.lightImpact();
      _mainController.forward(from: 0);
      setState(() {
        _currentStepIndex--;
      });
      widget.onStepChange?.call(_currentStepIndex);
    }
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _currentStepIndex = 0;
      _isPlaying = false;
    });
    _autoPlayTimer?.cancel();
    widget.onStepChange?.call(0);
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _currentAnimation.steps.isNotEmpty &&
            _currentStepIndex < _currentAnimation.steps.length
        ? _currentAnimation.steps[_currentStepIndex]
        : null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.background,
            AppColors.surface,
            AppColors.background.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),

          // Main animation stage
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background particles
                _buildParticleBackground(),

                // Main content
                if (currentStep != null)
                  _buildStepContent(currentStep)
                else
                  _buildEmptyState(),

                // Floating particles overlay
                _buildFloatingParticles(),
              ],
            ),
          ),

          // Timeline
          _buildTimeline(),

          // Controls
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Recipe icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child:
                const Icon(Iconsax.video_play, color: Colors.white, size: 24),
          )
              .animate(controller: _pulseController)
              .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05)),

          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentAnimation.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Step ${_currentStepIndex + 1} of ${_currentAnimation.steps.length}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // Duration badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.timer_1,
                    size: 14, color: AppColors.secondary),
                const SizedBox(width: 6),
                Text(
                  _formatDuration(_currentAnimation.totalDuration),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticleBackground() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticleBackgroundPainter(
            progress: _particleController.value,
            color: AppColors.primary.withValues(alpha: 0.05),
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildStepContent(AnimationStep step) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = math.max(0.0, constraints.maxHeight - 48);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Action icon with animation
                  _buildActionIcon(step),

                  const SizedBox(height: 32),

                  // Transformation visualization
                  _buildTransformationVisual(step),

                  const SizedBox(height: 24),

                  // Action description
                  _buildActionDescription(step),
                ],
              ),
            ),
          ),
        );
      },
    )
        .animate(key: ValueKey(_currentStepIndex))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildActionIcon(AnimationStep step) {
    final actionEmoji = _getActionEmoji(step.actionId);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
        ),

        // Main icon container
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              actionEmoji,
              style: const TextStyle(fontSize: 48),
            ),
          ),
        )
            .animate(
              onPlay: (controller) => controller.repeat(reverse: true),
            )
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.08, 1.08),
              duration: 1200.ms,
              curve: Curves.easeInOutSine,
            ),

        // Rotating ring
        AnimatedBuilder(
          animation: _particleController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _particleController.value * 2 * math.pi,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTransformationVisual(AnimationStep step) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // From state
        _buildStateChip(step.fromState, isFrom: true),

        // Arrow animation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(3, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  Iconsax.arrow_right_3,
                  size: 16,
                  color:
                      AppColors.primary.withValues(alpha: 0.5 + (index * 0.2)),
                ),
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(),
                  )
                  .slideX(
                    begin: -0.3,
                    end: 0.3,
                    duration: 800.ms,
                    delay: Duration(milliseconds: index * 150),
                    curve: Curves.easeInOut,
                  )
                  .fadeIn();
            }),
          ),
        ),

        // To state
        _buildStateChip(step.toState, isFrom: false),
      ],
    );
  }

  Widget _buildStateChip(String state, {required bool isFrom}) {
    final color = isFrom ? AppColors.textSecondary : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _capitalizeFirst(state),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    )
        .animate(
          key: ValueKey('${state}_$isFrom'),
        )
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.elasticOut,
        );
  }

  Widget _buildActionDescription(AnimationStep step) {
    final ingredients = step.allIngredientNames.join(', ');

    return Column(
      children: [
        Text(
          _getActionName(step.actionId),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (ingredients.isNotEmpty)
          Text(
            'Ingredients: ${_capitalizeFirst(ingredients)}',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        if (step.toolId != null) ...[
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              const Icon(Iconsax.cpu, size: 14, color: AppColors.secondary),
              Text(
                'Using: ${_getToolName(step.toolId!)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFloatingParticles() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          return CustomPaint(
            painter: _FloatingParticlesPainter(
              progress: _particleController.value,
              isPlaying: _isPlaying,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Iconsax.video_slash,
            size: 36,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'No animation steps',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(
          _currentAnimation.steps.length,
          (index) => Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _currentStepIndex = index);
                widget.onStepChange?.call(index);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Progress indicator
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: index <= _currentStepIndex
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Step dot
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: index == _currentStepIndex ? 12 : 8,
                      height: index == _currentStepIndex ? 12 : 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index <= _currentStepIndex
                            ? AppColors.primary
                            : AppColors.divider,
                        boxShadow: index == _currentStepIndex
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Reset button
          _buildControlButton(
            icon: Iconsax.refresh,
            onTap: _reset,
            size: 44,
          ),

          const SizedBox(width: 16),

          // Previous button
          _buildControlButton(
            icon: Iconsax.previous,
            onTap: _currentStepIndex > 0 ? _previousStep : null,
            size: 48,
          ),

          const SizedBox(width: 16),

          // Play/Pause button
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                _isPlaying ? Iconsax.pause : Iconsax.play,
                color: Colors.white,
                size: 28,
              ),
            ).animate(target: _isPlaying ? 1 : 0).scale(
                begin: const Offset(1, 1), end: const Offset(0.95, 0.95)),
          ),

          const SizedBox(width: 16),

          // Next button
          _buildControlButton(
            icon: Iconsax.next,
            onTap: _currentStepIndex < _currentAnimation.steps.length - 1
                ? _nextStep
                : null,
            size: 48,
          ),

          const SizedBox(width: 16),

          // Fullscreen button
          _buildControlButton(
            icon: Iconsax.maximize_3,
            onTap: () {
              // TODO: Fullscreen mode
            },
            size: 44,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    VoidCallback? onTap,
    required double size,
  }) {
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isEnabled
              ? AppColors.surface
              : AppColors.divider.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isEnabled
              ? AppColors.textPrimary
              : AppColors.textSecondary.withValues(alpha: 0.5),
          size: size * 0.45,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return '0s';
    if (duration.inMilliseconds < 1000) {
      final seconds = duration.inMilliseconds / 1000;
      return '${seconds.toStringAsFixed(1)}s';
    }
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _getActionEmoji(String? actionId) {
    const actionEmojis = {
      'chop': '🔪',
      'dice': '🎲',
      'slice': '🍰',
      'mince': '🧄',
      'peel': '🍌',
      'grate': '🧀',
      'mix': '🥣',
      'whisk': '🥄',
      'marinate': '🫙',
      'fry': '🍳',
      'sear': '🔥',
      'saute': '🍳',
      'boil': '♨️',
      'simmer': '🍲',
      'steam': '💨',
      'bake': '🧁',
      'roast': '🍗',
      'grill': '🍖',
      'blend': '🥤',
      'stirfry': '🥡',
      'plate': '🥗',
      'garnish': '🌿',
      'drizzle': '🫒',
      'sprinkle': '✨',
    };
    return actionEmojis[actionId] ?? '👨‍🍳';
  }

  String _getActionName(String? actionId) {
    const actionNames = {
      'chop': 'Chop',
      'dice': 'Dice',
      'slice': 'Slice',
      'mince': 'Mince',
      'peel': 'Peel',
      'grate': 'Grate',
      'mix': 'Mix',
      'whisk': 'Whisk',
      'marinate': 'Marinate',
      'fry': 'Stir Fry',
      'sear': 'Sear',
      'saute': 'Saut茅',
      'boil': 'Boil',
      'simmer': 'Simmer',
      'steam': 'Steam',
      'bake': 'Bake',
      'roast': 'Roast',
      'grill': 'Grill',
      'blend': 'Blend',
      'stirfry': 'Wok Fry',
      'plate': 'Plate',
      'garnish': 'Garnish',
      'drizzle': 'Drizzle',
      'sprinkle': 'Sprinkle',
    };
    return actionNames[actionId] ?? 'Cook';
  }

  String _getToolName(String toolId) {
    const toolNames = {
      'knife': 'Chef Knife',
      'bowl': 'Mixing Bowl',
      'peeler': 'Peeler',
      'grater': 'Grater',
      'cutting_board': 'Cutting Board',
      'pan': 'Frying Pan',
      'pot': 'Stock Pot',
      'wok': 'Wok',
      'grill': 'Grill',
      'oven': 'Oven',
      'blender': 'Blender',
      'microwave': 'Microwave',
      'airfryer': 'Air Fryer',
    };
    return toolNames[toolId] ?? toolId;
  }
}

/// Custom painter for background particles
class _ParticleBackgroundPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ParticleBackgroundPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final random = math.Random(42);

    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final y = (baseY + progress * 50) % size.height;
      final radius = 2 + random.nextDouble() * 4;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Custom painter for floating particles
class _FloatingParticlesPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;

  _FloatingParticlesPainter({required this.progress, required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    if (!isPlaying) return;

    final random = math.Random(123);

    for (int i = 0; i < 15; i++) {
      final startX = random.nextDouble() * size.width;
      final offsetProgress = (progress + i * 0.1) % 1.0;

      final x = startX + math.sin(offsetProgress * math.pi * 4) * 20;
      final y = size.height - (offsetProgress * size.height * 1.2);

      if (y > 0 && y < size.height) {
        final opacity = (1 - offsetProgress) * 0.5;
        final paint = Paint()
          ..color = Colors.white.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;

        final radius = 2 + random.nextDouble() * 3;
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying;
  }
}
