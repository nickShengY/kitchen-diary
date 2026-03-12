import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// AI-powered suggestion chip for next cooking steps
class AISuggestionChip extends StatelessWidget {
  final String actionId;
  final String actionName;
  final String emoji;
  final double confidence;
  final VoidCallback? onTap;
  final bool isHighlighted;

  const AISuggestionChip({
    super.key,
    required this.actionId,
    required this.actionName,
    required this.emoji,
    this.confidence = 0.8,
    this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isHighlighted
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                )
              : null,
          color: isHighlighted ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHighlighted
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.divider,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI indicator
            Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 10,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),

            // Emoji
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),

            // Action name
            Text(
              actionName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isHighlighted ? AppColors.primary : AppColors.textPrimary,
              ),
            ),

            // Confidence indicator
            if (confidence >= 0.9) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.trending_up,
                size: 14,
                color: Colors.green.shade400,
              ),
            ],
          ],
        ),
      ),
    ).animate(target: isHighlighted ? 1 : 0).shimmer(
          duration: 2000.ms,
          color: AppColors.primary.withValues(alpha: 0.1),
        );
  }
}

/// AI suggestion panel showing next step predictions
class AISuggestionPanel extends StatelessWidget {
  final String currentStep;
  final List<SuggestedAction> suggestions;
  final Function(String actionId)? onSuggestionTap;

  const AISuggestionPanel({
    super.key,
    required this.currentStep,
    required this.suggestions,
    this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Suggested Next Steps',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Suggestions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.asMap().entries.map((entry) {
              final index = entry.key;
              final suggestion = entry.value;
              return AISuggestionChip(
                actionId: suggestion.actionId,
                actionName: suggestion.actionName,
                emoji: suggestion.emoji,
                confidence: suggestion.confidence,
                isHighlighted: index == 0,
                onTap: () => onSuggestionTap?.call(suggestion.actionId),
              )
                  .animate(delay: Duration(milliseconds: index * 100))
                  .fadeIn()
                  .slideX(begin: 0.1, end: 0);
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

/// Data class for suggested actions
class SuggestedAction {
  final String actionId;
  final String actionName;
  final String emoji;
  final double confidence;
  final String? reason;

  const SuggestedAction({
    required this.actionId,
    required this.actionName,
    required this.emoji,
    this.confidence = 0.8,
    this.reason,
  });
}

/// Ingredient pairing suggestion widget
class IngredientPairingSuggestion extends StatelessWidget {
  final String baseIngredient;
  final List<PairingIngredient> pairings;
  final String? reason;
  final Function(String ingredientId)? onPairingTap;

  const IngredientPairingSuggestion({
    super.key,
    required this.baseIngredient,
    required this.pairings,
    this.reason,
    this.onPairingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.05),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Text('🤝', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Pairs well with $baseIngredient',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          if (reason != null) ...[
            const SizedBox(height: 4),
            Text(
              reason!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Pairings
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pairings.map((pairing) {
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onPairingTap?.call(pairing.ingredientId);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(pairing.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        pairing.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Data class for pairing ingredients
class PairingIngredient {
  final String ingredientId;
  final String name;
  final String emoji;

  const PairingIngredient({
    required this.ingredientId,
    required this.name,
    required this.emoji,
  });
}

/// Smart timing suggestion widget
class SmartTimingSuggestion extends StatelessWidget {
  final String message;
  final TimingSuggestionType type;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionLabel;

  const SmartTimingSuggestion({
    super.key,
    required this.message,
    required this.type,
    this.onDismiss,
    this.onAction,
    this.actionLabel,
  });

  IconData get _icon {
    switch (type) {
      case TimingSuggestionType.parallel:
        return Icons.call_split;
      case TimingSuggestionType.rest:
        return Icons.hourglass_bottom;
      case TimingSuggestionType.prepAhead:
        return Icons.schedule;
    }
  }

  Color get _color {
    switch (type) {
      case TimingSuggestionType.parallel:
        return Colors.blue;
      case TimingSuggestionType.rest:
        return Colors.orange;
      case TimingSuggestionType.prepAhead:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(_icon, size: 20, color: _color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: _color,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(actionLabel!),
            ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }
}

enum TimingSuggestionType {
  parallel,
  rest,
  prepAhead,
}
