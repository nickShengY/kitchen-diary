import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';

/// Onboarding overlay for the Animation Composer feature.
/// Shows a guided tour of the main features on first use.
class AnimationOnboarding extends StatefulWidget {
  final VoidCallback onComplete;
  final List<OnboardingStep> steps;

  const AnimationOnboarding({
    super.key,
    required this.onComplete,
    required this.steps,
  });

  /// Check if onboarding has been completed
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('animation_onboarding_complete') ?? false;
  }

  /// Mark onboarding as completed
  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('animation_onboarding_complete', true);
  }

  /// Reset onboarding (for testing)
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('animation_onboarding_complete');
  }

  @override
  State<AnimationOnboarding> createState() => _AnimationOnboardingState();
}

class _AnimationOnboardingState extends State<AnimationOnboarding> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    HapticFeedback.lightImpact();
    if (_currentStep < widget.steps.length - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _complete();
    }
  }

  void _previousStep() {
    HapticFeedback.lightImpact();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _complete() {
    HapticFeedback.mediumImpact();
    AnimationOnboarding.markComplete();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _complete,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentStep = index),
                itemCount: widget.steps.length,
                itemBuilder: (context, index) {
                  final step = widget.steps[index];
                  return _OnboardingStepView(
                    step: step,
                    isActive: index == _currentStep,
                  );
                },
              ),
            ),

            // Progress indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.steps.length, (index) {
                  final isActive = index == _currentStep;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentStep == widget.steps.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingStepView extends StatelessWidget {
  final OnboardingStep step;
  final bool isActive;

  const _OnboardingStepView({
    required this.step,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step.emoji,
                style: const TextStyle(fontSize: 56),
              ),
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                curve: Curves.elasticOut,
                duration: 600.ms,
              )
              .fadeIn(duration: 300.ms),

          const SizedBox(height: 40),

          // Title
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(delay: 100.ms, duration: 300.ms)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          // Description
          Text(
            step.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(delay: 200.ms, duration: 300.ms)
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}

/// Data class for onboarding steps
class OnboardingStep {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final String? illustration;
  final String? highlightElement;

  const OnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    this.illustration,
    this.highlightElement,
  });

  factory OnboardingStep.fromJson(Map<String, dynamic> json) {
    return OnboardingStep(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      emoji: json['emoji'] as String,
      illustration: json['illustration'] as String?,
      highlightElement: json['highlightElement'] as String?,
    );
  }
}

/// Empty state widget for various animation scenarios
class AnimationEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String emoji;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AnimationEmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.emoji,
    this.actionLabel,
    this.onAction,
  });

  factory AnimationEmptyState.fromJson(
    Map<String, dynamic> json, {
    VoidCallback? onAction,
  }) {
    return AnimationEmptyState(
      title: json['title'] as String,
      message: json['message'] as String,
      emoji: json['emoji'] as String,
      actionLabel: json['actionLabel'] as String?,
      onAction: onAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated emoji
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: 1500.ms,
                  curve: Curves.easeInOut,
                ),

            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Message
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          curve: Curves.easeOut,
        );
  }
}

/// Loading state widget with animated messages
class AnimationLoadingState extends StatefulWidget {
  final List<String> messages;
  final Duration messageInterval;

  const AnimationLoadingState({
    super.key,
    required this.messages,
    this.messageInterval = const Duration(seconds: 2),
  });

  @override
  State<AnimationLoadingState> createState() => _AnimationLoadingStateState();
}

class _AnimationLoadingStateState extends State<AnimationLoadingState> {
  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    _cycleMessages();
  }

  void _cycleMessages() async {
    while (mounted && _currentMessageIndex < widget.messages.length - 1) {
      await Future.delayed(widget.messageInterval);
      if (mounted) {
        setState(() => _currentMessageIndex++);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated cooking emoji
          _AnimatedCookingLoader(),

          const SizedBox(height: 24),

          // Animated message
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              widget.messages[_currentMessageIndex],
              key: ValueKey(_currentMessageIndex),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedCookingLoader extends StatefulWidget {
  @override
  State<_AnimatedCookingLoader> createState() => _AnimatedCookingLoaderState();
}

class _AnimatedCookingLoaderState extends State<_AnimatedCookingLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<String> _cookingEmojis = ['🍳', '🔪', '🍲', '✨'];
  int _currentEmoji = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _currentEmoji = (_currentEmoji + 1) % _cookingEmojis.length;
          });
          _controller.forward(from: 0);
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_controller.value * 0.1),
          child: Opacity(
            opacity: 0.5 + (_controller.value * 0.5),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _cookingEmojis[_currentEmoji],
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Feedback toast for animation actions
class AnimationFeedbackToast extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Color? color;

  const AnimationFeedbackToast({
    super.key,
    required this.message,
    this.icon,
    this.color,
  });

  static void show(
    BuildContext context,
    String message, {
    IconData? icon,
    Color? color,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: 24,
        right: 24,
        child: AnimationFeedbackToast(
          message: message,
          icon: icon,
          color: color,
        ),
      ),
    );

    overlay.insert(entry);
    HapticFeedback.lightImpact();

    Future.delayed(const Duration(seconds: 2), () {
      entry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: color ?? AppColors.textPrimary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.5, end: 0, curve: Curves.easeOutCubic)
        .then(delay: 1500.ms)
        .fadeOut(duration: 200.ms)
        .slideY(begin: 0, end: 0.5);
  }
}
