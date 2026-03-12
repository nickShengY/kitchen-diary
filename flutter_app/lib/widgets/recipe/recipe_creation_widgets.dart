import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// Recipe template selector
class RecipeTemplateSelector extends StatelessWidget {
  final List<RecipeTemplate> templates;
  final String? selectedId;
  final Function(String templateId)? onSelect;

  const RecipeTemplateSelector({
    super.key,
    required this.templates,
    this.selectedId,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        final isSelected = template.id == selectedId;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onSelect?.call(template.id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(template.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text(
                  template.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  template.description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: index * 50))
            .fadeIn()
            .scale(begin: const Offset(0.95, 0.95));
      },
    );
  }
}

class RecipeTemplate {
  final String id;
  final String name;
  final String emoji;
  final String description;

  const RecipeTemplate({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
  });
}

/// Recipe creation step indicator
class RecipeCreationProgress extends StatelessWidget {
  final List<CreationStep> steps;
  final int currentStep;

  const RecipeCreationProgress({
    super.key,
    required this.steps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isCompleted = index < currentStep;
          final isCurrent = index == currentStep;
          final isLast = index == steps.length - 1;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.primary
                              : (isCurrent
                                  ? AppColors.primary.withValues(alpha: 0.2)
                                  : AppColors.surface),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCompleted || isCurrent
                                ? AppColors.primary
                                : AppColors.divider,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isCurrent
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: isCurrent
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 20),
                      color: isCompleted ? AppColors.primary : AppColors.divider,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class CreationStep {
  final String id;
  final String name;
  final bool required;

  const CreationStep({
    required this.id,
    required this.name,
    this.required = false,
  });
}

/// AI assist button
class AIAssistButton extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isLoading;
  final VoidCallback? onTap;

  const AIAssistButton({
    super.key,
    required this.label,
    required this.emoji,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF667EEA).withValues(alpha: 0.1),
              const Color(0xFF764BA2).withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF667EEA).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              )
            else
              Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isLoading ? AppColors.textSecondary : const Color(0xFF667EEA),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ingredient input with autocomplete
class IngredientInput extends StatefulWidget {
  final Function(Ingredient)? onAdd;
  final List<String> suggestions;

  const IngredientInput({
    super.key,
    this.onAdd,
    this.suggestions = const [],
  });

  @override
  State<IngredientInput> createState() => _IngredientInputState();
}

class _IngredientInputState extends State<IngredientInput> {
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _nameController = TextEditingController();

  void _handleAdd() {
    if (_nameController.text.isNotEmpty) {
      widget.onAdd?.call(Ingredient(
        name: _nameController.text,
        quantity: _quantityController.text.isNotEmpty
            ? _quantityController.text
            : null,
        unit: _unitController.text.isNotEmpty ? _unitController.text : null,
      ));
      _quantityController.clear();
      _unitController.clear();
      _nameController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 60,
                child: TextField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    hintText: 'Qty',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    hintText: 'Unit',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Ingredient name',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onSubmitted: (_) => _handleAdd(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _handleAdd,
                icon: const Icon(Icons.add_circle, color: AppColors.primary),
              ),
            ],
          ),
          if (widget.suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.suggestions.take(6).map((sug) {
                return GestureDetector(
                  onTap: () => _nameController.text = sug,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text(
                      sug,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class Ingredient {
  final String name;
  final String? quantity;
  final String? unit;

  const Ingredient({
    required this.name,
    this.quantity,
    this.unit,
  });
}

/// Draggable ingredient list item
class DraggableIngredientItem extends StatelessWidget {
  final Ingredient ingredient;
  final int index;
  final VoidCallback? onRemove;
  final VoidCallback? onEdit;

  const DraggableIngredientItem({
    super.key,
    required this.ingredient,
    required this.index,
    this.onRemove,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_handle, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              ingredient.quantity != null
                  ? '${ingredient.quantity} ${ingredient.unit ?? ''}'.trim()
                  : '-',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ingredient.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// Step input
class StepInput extends StatelessWidget {
  final int stepNumber;
  final TextEditingController controller;
  final VoidCallback? onRemove;
  final VoidCallback? onAddTimer;

  const StepInput({
    super.key,
    required this.stepNumber,
    required this.controller,
    this.onRemove,
    this.onAddTimer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$stepNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Step $stepNumber',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.timer_outlined, size: 20, color: AppColors.textSecondary),
                onPressed: onAddTimer,
                tooltip: 'Add timer',
              ),
              if (stepNumber > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  onPressed: onRemove,
                  tooltip: 'Remove step',
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Describe what to do in this step...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draft indicator
class DraftIndicator extends StatelessWidget {
  final DateTime lastSaved;
  final bool isSaving;

  const DraftIndicator({
    super.key,
    required this.lastSaved,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSaving ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSaving ? Icons.sync : Icons.check_circle,
            size: 14,
            color: isSaving ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 4),
          Text(
            isSaving ? 'Saving...' : 'Saved',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSaving ? Colors.orange : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

