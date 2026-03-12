import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// Onboarding page with illustration
class OnboardingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imagePath;
  final String? emoji;
  final Widget? customContent;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.subtitle,
    this.imagePath,
    this.emoji,
    this.customContent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image or emoji
          if (imagePath != null)
            Image.asset(
              imagePath!,
              height: 250,
              fit: BoxFit.contain,
            ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8))
          else if (emoji != null)
            Text(
              emoji!,
              style: const TextStyle(fontSize: 100),
            )
                .animate()
                .fadeIn()
                .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),

          const SizedBox(height: 48),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

          // Custom content
          if (customContent != null) ...[
            const SizedBox(height: 32),
            customContent!.animate().fadeIn(delay: 400.ms),
          ],
        ],
      ),
    );
  }
}

/// Onboarding page indicator
class OnboardingIndicator extends StatelessWidget {
  final int totalPages;
  final int currentPage;

  const OnboardingIndicator({
    super.key,
    required this.totalPages,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final isActive = index == currentPage;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.divider,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// Skill level selector
class SkillLevelSelector extends StatelessWidget {
  final String? selectedLevel;
  final Function(String level)? onSelect;

  const SkillLevelSelector({
    super.key,
    this.selectedLevel,
    this.onSelect,
  });

  static const levels = [
    {
      'id': 'beginner',
      'label': 'Beginner',
      'emoji': '🌱',
      'description': 'Just starting out'
    },
    {
      'id': 'intermediate',
      'label': 'Home Cook',
      'emoji': '🏠',
      'description': 'Comfortable in the kitchen'
    },
    {
      'id': 'advanced',
      'label': 'Advanced',
      'emoji': '👨‍🍳',
      'description': 'Love trying new techniques'
    },
    {
      'id': 'expert',
      'label': 'Expert',
      'emoji': '⭐',
      'description': 'Professional level skills'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: levels.map((level) {
        final isSelected = level['id'] == selectedLevel;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onSelect?.call(level['id'] as String);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  level['emoji'] as String,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level['label'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        level['description'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle,
                      color: AppColors.primary, size: 24),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Cuisine preference selector
class CuisinePreferenceSelector extends StatelessWidget {
  final Set<String> selected;
  final Function(Set<String>)? onChanged;

  const CuisinePreferenceSelector({
    super.key,
    this.selected = const {},
    this.onChanged,
  });

  static const cuisines = [
    {'id': 'italian', 'name': 'Italian', 'emoji': '🍝'},
    {'id': 'asian', 'name': 'Asian', 'emoji': '🍜'},
    {'id': 'mexican', 'name': 'Mexican', 'emoji': '🌮'},
    {'id': 'american', 'name': 'American', 'emoji': '🍔'},
    {'id': 'indian', 'name': 'Indian', 'emoji': '🍛'},
    {'id': 'mediterranean', 'name': 'Mediterranean', 'emoji': '🥗'},
    {'id': 'healthy', 'name': 'Healthy', 'emoji': '🥗'},
    {'id': 'desserts', 'name': 'Desserts', 'emoji': '🍰'},
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: cuisines.map((cuisine) {
        final isSelected = selected.contains(cuisine['id']);

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            final newSet = Set<String>.from(selected);
            if (isSelected) {
              newSet.remove(cuisine['id']);
            } else {
              newSet.add(cuisine['id'] as String);
            }
            onChanged?.call(newSet);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cuisine['emoji'] as String,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  cuisine['name'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Dietary restrictions selector
class DietaryRestrictionsSelector extends StatelessWidget {
  final Set<String> selected;
  final Function(Set<String>)? onChanged;

  const DietaryRestrictionsSelector({
    super.key,
    this.selected = const {},
    this.onChanged,
  });

  static const restrictions = [
    {'id': 'vegetarian', 'name': 'Vegetarian', 'emoji': '🥬'},
    {'id': 'vegan', 'name': 'Vegan', 'emoji': '🌱'},
    {'id': 'gluten_free', 'name': 'Gluten-Free', 'emoji': '🌾'},
    {'id': 'dairy_free', 'name': 'Dairy-Free', 'emoji': '🥛'},
    {'id': 'nut_free', 'name': 'Nut-Free', 'emoji': '🥜'},
    {'id': 'keto', 'name': 'Keto', 'emoji': '🥑'},
    {'id': 'halal', 'name': 'Halal', 'emoji': '☕'},
    {'id': 'kosher', 'name': 'Kosher', 'emoji': '✨'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: restrictions.map((restriction) {
        final isSelected = selected.contains(restriction['id']);

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            final newSet = Set<String>.from(selected);
            if (isSelected) {
              newSet.remove(restriction['id']);
            } else {
              newSet.add(restriction['id'] as String);
            }
            onChanged?.call(newSet);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider,
              ),
            ),
            child: Row(
              children: [
                Text(
                  restriction['emoji'] as String,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    restriction['name'] as String,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                Checkbox(
                  value: isSelected,
                  onChanged: (_) {
                    final newSet = Set<String>.from(selected);
                    if (isSelected) {
                      newSet.remove(restriction['id']);
                    } else {
                      newSet.add(restriction['id'] as String);
                    }
                    onChanged?.call(newSet);
                  },
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Goal selector for onboarding
class GoalSelector extends StatelessWidget {
  final Set<String> selected;
  final Function(Set<String>)? onChanged;

  const GoalSelector({
    super.key,
    this.selected = const {},
    this.onChanged,
  });

  static const goals = [
    {'id': 'cook_more', 'name': 'Cook more at home', 'emoji': '🏠'},
    {'id': 'try_new', 'name': 'Try new recipes', 'emoji': '🌟'},
    {'id': 'eat_healthy', 'name': 'Eat healthier', 'emoji': '🥗'},
    {'id': 'save_money', 'name': 'Save money', 'emoji': '💵'},
    {'id': 'meal_prep', 'name': 'Master meal prep', 'emoji': '📦'},
    {'id': 'baking', 'name': 'Learn baking', 'emoji': '🍰'},
    {'id': 'share', 'name': 'Share my recipes', 'emoji': '📲'},
    {'id': 'family', 'name': 'Cook for family', 'emoji': '👨‍👩‍👧‍👦'},
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: goals.map((goal) {
        final isSelected = selected.contains(goal['id']);

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            final newSet = Set<String>.from(selected);
            if (isSelected) {
              newSet.remove(goal['id']);
            } else {
              newSet.add(goal['id'] as String);
            }
            onChanged?.call(newSet);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(goal['emoji'] as String,
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  goal['name'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Onboarding complete card
class OnboardingCompleteCard extends StatelessWidget {
  final String userName;
  final VoidCallback? onStart;

  const OnboardingCompleteCard({
    super.key,
    required this.userName,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '🎉',
          style: TextStyle(fontSize: 80),
        )
            .animate()
            .fadeIn()
            .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),
        const SizedBox(height: 32),
        Text(
          "You're all set, $userName!",
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 16),
        const Text(
          "Let's start cooking amazing meals together",
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Start Cooking! 🍳',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }
}
