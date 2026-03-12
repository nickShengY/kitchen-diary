import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:confetti/confetti.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/recipe_provider.dart';
import '../../models/recipe_model.dart';

class CookingModeScreen extends StatefulWidget {
  final String recipeId;

  const CookingModeScreen({super.key, required this.recipeId});

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen> {
  late PageController _pageController;
  late ConfettiController _confettiController;

  int _currentStep = 0;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    Future.microtask(() {
      if (!mounted) return;
      context.read<RecipeProvider>().getRecipe(widget.recipeId);
    });

    // Keep screen on during cooking
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _nextStep(int totalSteps) {
    HapticFeedback.mediumImpact();

    if (_currentStep < totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      setState(() => _isCompleted = true);
      _confettiController.play();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      HapticFeedback.selectionClick();
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final backgroundColor = theme.brightness == Brightness.dark
        ? scheme.surface
        : scheme.inverseSurface;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Consumer<RecipeProvider>(
        builder: (context, provider, _) {
          final recipe = provider.currentRecipe;

          if (recipe == null) {
            return Center(
              child: CircularProgressIndicator(color: scheme.primary),
            );
          }

          final steps = recipe.displaySteps;

          if (_isCompleted) {
            return _buildCompletionScreen(recipe);
          }

          return Stack(
            children: [
              // Steps
              PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  return _buildStepPage(steps[index], index, steps.length);
                },
              ),

              // Top bar
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCloseButton(),
                      _buildProgressIndicator(steps.length),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),

              // Confetti
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  particleDrag: 0.05,
                  emissionFrequency: 0.05,
                  numberOfParticles: 30,
                  gravity: 0.1,
                  colors: [
                    scheme.primary,
                    scheme.secondary,
                    scheme.tertiary,
                    scheme.error,
                    Colors.pink,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCloseButton() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foregroundColor = theme.brightness == Brightness.dark
        ? scheme.onSurface
        : scheme.onInverseSurface;

    return Semantics(
      button: true,
      label: 'Exit cooking mode',
      child: Material(
        color: foregroundColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _showExitDialog(),
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(Iconsax.close_circle, color: foregroundColor),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int total) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foregroundColor = theme.brightness == Brightness.dark
        ? scheme.onSurface
        : scheme.onInverseSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: foregroundColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${_currentStep + 1} / $total',
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildStepPage(CookingStep step, int index, int total) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foregroundColor = theme.brightness == Brightness.dark
        ? scheme.onSurface
        : scheme.onInverseSurface;
    final overlayColor = foregroundColor.withValues(alpha: 0.10);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: overlayColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  step.actionEmoji,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

            const SizedBox(height: 32),

            // Action title
            Text(
              step.actionName,
              style: theme.textTheme.displaySmall?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w800,
              ),
            ).animate().fadeIn().slideX(begin: 0.1, end: 0),

            const SizedBox(height: 8),

            Text(
              'with ${step.toolName}',
              style: TextStyle(
                color: foregroundColor.withValues(alpha: 0.75),
                fontSize: 18,
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 32),

            // Ingredients
            if (step.ingredients.isNotEmpty) ...[
              Text(
                'INGREDIENTS',
                style: TextStyle(
                  color: foregroundColor.withValues(alpha: 0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: step.ingredients.map((ing) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: overlayColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(ing.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          '${ing.amount} ${ing.unit} ${ing.name}',
                          style: TextStyle(
                            color: foregroundColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ).animate().fadeIn(delay: 200.ms),
            ],

            const Spacer(),

            // Settings row
            if (step.duration != null || step.temperature != null)
              Row(
                children: [
                  if (step.temperature != null)
                    _buildSettingCard(
                      icon: Iconsax.flash_1,
                      label: 'Heat',
                      value: step.temperature!,
                      color: scheme.error,
                    ),
                  if (step.duration != null)
                    _buildSettingCard(
                      icon: Iconsax.timer_1,
                      label: 'Time',
                      value: step.duration!,
                      color: scheme.tertiary,
                    ),
                ],
              ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 32),

            // Navigation buttons
            Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: Material(
                      color: overlayColor,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: _previousStep,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          margin: const EdgeInsets.only(right: 12),
                          child: Center(
                            child: Text(
                              'Previous',
                              style: TextStyle(
                                color: foregroundColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  flex: _currentStep > 0 ? 2 : 1,
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => _nextStep(total),
                      borderRadius: BorderRadius.circular(16),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            index == total - 1
                                ? 'Finish! 🎉'
                                : 'Done, Next Step',
                            style: TextStyle(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foregroundColor = theme.brightness == Brightness.dark
        ? scheme.onSurface
        : scheme.onInverseSurface;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: foregroundColor.withValues(alpha: 0.65),
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionScreen(RecipeModel recipe) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foregroundColor = theme.brightness == Brightness.dark
        ? scheme.onSurface
        : scheme.onInverseSurface;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Text(
              '🎉',
              style: TextStyle(fontSize: 100),
            )
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .then()
                .shake(hz: 2),
            const SizedBox(height: 32),
            Text(
              'Congratulations!',
              style: theme.textTheme.displaySmall?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w800,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 8),
            Text(
              'You finished making\n${recipe.title}',
              style: TextStyle(
                color: foregroundColor.withValues(alpha: 0.8),
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/explore'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: const Text('Back to Explore'),
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // TODO: Share completion
              },
              child: Text(
                'Share your creation',
                style: TextStyle(
                  color: foregroundColor.withValues(alpha: 0.75),
                ),
              ),
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }

  void _showExitDialog() {
    final scheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Exit Cooking Mode?'),
        content: const Text('Your progress will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Cooking'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
