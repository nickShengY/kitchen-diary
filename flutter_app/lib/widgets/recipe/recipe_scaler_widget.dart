import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_theme.dart';
import '../../models/recipe_model.dart';

class RecipeScalerWidget extends StatefulWidget {
  final int originalServings;
  final List<RecipeIngredient> ingredients;
  final ValueChanged<int> onServingsChanged;

  const RecipeScalerWidget({
    super.key,
    required this.originalServings,
    required this.ingredients,
    required this.onServingsChanged,
  });

  @override
  State<RecipeScalerWidget> createState() => _RecipeScalerWidgetState();
}

class _RecipeScalerWidgetState extends State<RecipeScalerWidget> {
  late int _currentServings;
  late double _scaleFactor;

  @override
  void initState() {
    super.initState();
    _currentServings = widget.originalServings;
    _scaleFactor = 1.0;
  }

  void _updateServings(int newServings) {
    if (newServings < 1 || newServings > 50) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentServings = newServings;
      _scaleFactor = newServings / widget.originalServings;
    });
    widget.onServingsChanged(newServings);
  }

  String _scaleAmount(String originalAmount) {
    final parsed = double.tryParse(originalAmount);
    if (parsed == null) return originalAmount;
    final scaled = parsed * _scaleFactor;
    if (scaled == scaled.roundToDouble()) return scaled.round().toString();
    return scaled.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Servings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              if (_scaleFactor != 1.0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_scaleFactor.toStringAsFixed(1)}x',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Serving selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildServeButton(
                icon: Iconsax.minus,
                onTap: () => _updateServings(_currentServings - 1),
                enabled: _currentServings > 1,
                scheme: scheme,
              ),
              const SizedBox(width: 24),
              Column(
                children: [
                  Text(
                    '$_currentServings',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                  Text(
                    'servings',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              _buildServeButton(
                icon: Iconsax.add,
                onTap: () => _updateServings(_currentServings + 1),
                enabled: _currentServings < 50,
                scheme: scheme,
              ),
            ],
          ),

          // Quick select chips
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [1, 2, 4, 6, 8, 12].map((n) {
              final isSelected = _currentServings == n;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => _updateServings(n),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? scheme.primary
                          : scheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$n',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          if (_scaleFactor != 1.0) ...[
            const SizedBox(height: 20),
            Divider(color: scheme.outline.withValues(alpha: 0.1)),
            const SizedBox(height: 12),
            Text(
              'Scaled Ingredients',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.ingredients.asMap().entries.map((entry) {
              final idx = entry.key;
              final ing = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(ing.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      '${_scaleAmount(ing.amount)} ${ing.unit}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ing.name,
                        style: TextStyle(color: scheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ).animate(delay: (idx * 30).ms).fadeIn().slideX(begin: 0.1);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildServeButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
    required ColorScheme scheme,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled
              ? scheme.primary.withValues(alpha: 0.1)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: enabled
              ? scheme.primary
              : scheme.onSurfaceVariant.withValues(alpha: 0.3),
          size: 20,
        ),
      ),
    );
  }
}
