import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Nutrition data model
class NutritionInfo {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;
  final int servings;

  const NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
    this.servings = 1,
  });
}

/// Compact nutrition badge row
class NutritionBadges extends StatelessWidget {
  final NutritionInfo nutrition;

  const NutritionBadges({
    super.key,
    required this.nutrition,
  });

  @override
  Widget build(BuildContext context) {
    final badges = _getBadges();
    if (badges.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: badges
          .map((badge) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badge.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(badge.emoji, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      badge.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badge.color,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  List<_Badge> _getBadges() {
    final badges = <_Badge>[];

    if (nutrition.calories < 300) {
      badges.add(const _Badge('🔥', 'Low Cal', Colors.orange));
    }
    if (nutrition.protein > 20) {
      badges.add(const _Badge('💪', 'High Protein', Colors.blue));
    }
    if (nutrition.carbs < 20) {
      badges.add(const _Badge('🥗', 'Low Carb', Colors.green));
    }
    if (nutrition.fat < 10) {
      badges.add(const _Badge('💚', 'Low Fat', Colors.teal));
    }
    if (nutrition.fiber > 10) {
      badges.add(const _Badge('🌿', 'High Fiber', Colors.brown));
    }

    return badges;
  }
}

class _Badge {
  final String emoji;
  final String label;
  final Color color;

  const _Badge(this.emoji, this.label, this.color);
}

/// Nutrition facts card
class NutritionFactsCard extends StatelessWidget {
  final NutritionInfo nutrition;
  final bool expanded;
  final VoidCallback? onToggle;

  const NutritionFactsCard({
    super.key,
    required this.nutrition,
    this.expanded = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🥗', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                const Text(
                  'Nutrition Facts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Per serving',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textSecondary,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Calories highlight
            Row(
              children: [
                _CalorieCircle(calories: nutrition.calories),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _MacroBar(
                        label: 'Protein',
                        value: nutrition.protein,
                        max: 50,
                        color: Colors.blue,
                        unit: 'g',
                      ),
                      const SizedBox(height: 8),
                      _MacroBar(
                        label: 'Carbs',
                        value: nutrition.carbs,
                        max: 300,
                        color: Colors.orange,
                        unit: 'g',
                      ),
                      const SizedBox(height: 8),
                      _MacroBar(
                        label: 'Fat',
                        value: nutrition.fat,
                        max: 65,
                        color: Colors.purple,
                        unit: 'g',
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Expanded details
            if (expanded) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              _NutrientRow(
                  'Fiber', '${nutrition.fiber.toStringAsFixed(1)}g', 25),
              _NutrientRow(
                  'Sugar', '${nutrition.sugar.toStringAsFixed(1)}g', 50),
              _NutrientRow(
                  'Sodium', '${nutrition.sodium.toStringAsFixed(0)}mg', 2300),
            ],
          ],
        ),
      ),
    );
  }
}

class _CalorieCircle extends StatelessWidget {
  final int calories;

  const _CalorieCircle({required this.calories});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$calories',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const Text(
            'kcal',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;
  final String unit;

  const _MacroBar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (value / max).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percent,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '${value.toStringAsFixed(1)}$unit',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _NutrientRow extends StatelessWidget {
  final String name;
  final String value;
  final double dailyValue;

  const _NutrientRow(this.name, this.value, this.dailyValue);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ingredient scaling widget
class IngredientScaler extends StatelessWidget {
  final int currentServings;
  final int originalServings;
  final List<double> quickScale;
  final ValueChanged<int>? onServingsChanged;

  const IngredientScaler({
    super.key,
    required this.currentServings,
    required this.originalServings,
    this.quickScale = const [0.5, 1, 1.5, 2, 3, 4],
    this.onServingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🥗', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              const Text(
                'Servings',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _ServingCounter(
                value: currentServings,
                onChanged: onServingsChanged,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Quick scale buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: quickScale.map((scale) {
                final servings = (originalServings * scale).round();
                final isSelected = servings == currentServings;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onServingsChanged?.call(servings),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        scale == 1 ? 'Original' : '${scale}x',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServingCounter extends StatelessWidget {
  final int value;
  final ValueChanged<int>? onChanged;

  const _ServingCounter({
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CounterButton(
          icon: Icons.remove,
          onTap: value > 1 ? () => onChanged?.call(value - 1) : null,
        ),
        Container(
          width: 48,
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _CounterButton(
          icon: Icons.add,
          onTap: value < 24 ? () => onChanged?.call(value + 1) : null,
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CounterButton({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.primary : AppColors.divider,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Scaled ingredient display
class ScaledIngredient extends StatelessWidget {
  final String name;
  final String originalAmount;
  final String scaledAmount;
  final bool isScaled;
  final bool isChecked;
  final VoidCallback? onToggle;

  const ScaledIngredient({
    super.key,
    required this.name,
    required this.originalAmount,
    required this.scaledAmount,
    this.isScaled = false,
    this.isChecked = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              isChecked ? Colors.green.withValues(alpha: 0.05) : Colors.white,
          border: const Border(
            bottom: BorderSide(color: AppColors.divider),
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isChecked ? Colors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isChecked ? Colors.green : AppColors.divider,
                  width: 2,
                ),
              ),
              child: isChecked
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),

            const SizedBox(width: 12),

            // Amount
            SizedBox(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scaledAmount,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isChecked ? Colors.green : AppColors.textPrimary,
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (isScaled)
                    Text(
                      '(was $originalAmount)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Name
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 15,
                  color: isChecked
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  decoration: isChecked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
