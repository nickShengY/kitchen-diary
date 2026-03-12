import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

/// Shopping list item model
class ShoppingItem {
  final String id;
  final String name;
  final String? quantity;
  final String? unit;
  final String aisle;
  final bool isChecked;
  final String? note;
  final String? recipeSource;

  const ShoppingItem({
    required this.id,
    required this.name,
    this.quantity,
    this.unit,
    required this.aisle,
    this.isChecked = false,
    this.note,
    this.recipeSource,
  });

  ShoppingItem copyWith({bool? isChecked}) {
    return ShoppingItem(
      id: id,
      name: name,
      quantity: quantity,
      unit: unit,
      aisle: aisle,
      isChecked: isChecked ?? this.isChecked,
      note: note,
      recipeSource: recipeSource,
    );
  }
}

/// Aisle model
class Aisle {
  final String id;
  final String name;
  final String emoji;
  final int order;

  const Aisle({
    required this.id,
    required this.name,
    required this.emoji,
    required this.order,
  });
}

/// Shopping list header with progress
class ShoppingListHeader extends StatelessWidget {
  final String title;
  final int totalItems;
  final int checkedItems;
  final VoidCallback? onShare;
  final VoidCallback? onClear;

  const ShoppingListHeader({
    super.key,
    required this.title,
    required this.totalItems,
    required this.checkedItems,
    this.onShare,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalItems > 0 ? checkedItems / totalItems : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: onShare,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: onClear,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$checkedItems/$totalItems',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          if (checkedItems == totalItems && totalItems > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🎉', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 6),
                  Text(
                    'All done!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Aisle section with collapsible items
class AisleSection extends StatelessWidget {
  final Aisle aisle;
  final List<ShoppingItem> items;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final Function(String itemId)? onItemToggle;
  final Function(String itemId)? onItemDelete;

  const AisleSection({
    super.key,
    required this.aisle,
    required this.items,
    this.isExpanded = true,
    this.onToggle,
    this.onItemToggle,
    this.onItemDelete,
  });

  @override
  Widget build(BuildContext context) {
    final checkedCount = items.where((i) => i.isChecked).length;
    final isAllChecked = checkedCount == items.length && items.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isAllChecked ? Colors.green.withValues(alpha: 0.05) : null,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(16),
                  bottom: Radius.circular(isExpanded ? 0 : 16),
                ),
              ),
              child: Row(
                children: [
                  Text(aisle.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aisle.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isAllChecked
                                ? Colors.green
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$checkedCount/${items.length} items',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Items
          if (isExpanded)
            ...items.asMap().entries.map((entry) {
              final item = entry.value;
              return Dismissible(
                key: Key(item.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => onItemDelete?.call(item.id),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: ShoppingListItem(
                  item: item,
                  onToggle: () => onItemToggle?.call(item.id),
                  showDivider: entry.key < items.length - 1,
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// Individual shopping list item
class ShoppingListItem extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback? onToggle;
  final bool showDivider;

  const ShoppingListItem({
    super.key,
    required this.item,
    this.onToggle,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onToggle?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: AppColors.divider))
              : null,
        ),
        child: Row(
          children: [
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: item.isChecked ? Colors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: item.isChecked ? Colors.green : AppColors.divider,
                  width: 2,
                ),
              ),
              child: item.isChecked
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),

            const SizedBox(width: 12),

            // Quantity
            if (item.quantity != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${item.quantity}${item.unit != null ? ' ${item.unit}' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: item.isChecked
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              ),

            const SizedBox(width: 12),

            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: item.isChecked
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      decoration:
                          item.isChecked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (item.recipeSource != null)
                    Text(
                      'From: ${item.recipeSource}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
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

/// Add item input
class AddItemInput extends StatefulWidget {
  final Function(String name, String? quantity)? onAdd;

  const AddItemInput({
    super.key,
    this.onAdd,
  });

  @override
  State<AddItemInput> createState() => _AddItemInputState();
}

class _AddItemInputState extends State<AddItemInput> {
  final _controller = TextEditingController();
  bool _isFocused = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_controller.text.isNotEmpty) {
      widget.onAdd?.call(_controller.text, null);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused ? AppColors.primary : AppColors.divider,
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: _isFocused
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
        children: [
          const Icon(Icons.add, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Focus(
              onFocusChange: (focused) => setState(() => _isFocused = focused),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Add item...',
                  border: InputBorder.none,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleSubmit(),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.send, color: AppColors.primary),
              onPressed: _handleSubmit,
            ),
        ],
      ),
    );
  }
}

/// Quick add suggestions
class QuickAddSuggestions extends StatelessWidget {
  final List<String> suggestions;
  final Function(String)? onSelect;

  const QuickAddSuggestions({
    super.key,
    required this.suggestions,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline,
                  size: 16, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Text(
                'Frequently bought',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: suggestions.map((item) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onSelect?.call(item);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          item,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
