import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// Search bar with filter chips for the animation composer
class AnimationSearchBar extends StatefulWidget {
  final String placeholder;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final Duration debounce;
  final bool autofocus;

  const AnimationSearchBar({
    super.key,
    this.placeholder = 'Search...',
    this.onChanged,
    this.onClear,
    this.debounce = const Duration(milliseconds: 300),
    this.autofocus = false,
  });

  @override
  State<AnimationSearchBar> createState() => _AnimationSearchBarState();
}

class _AnimationSearchBarState extends State<AnimationSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounce, () {
      widget.onChanged?.call(value);
    });
  }

  void _onClear() {
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _isFocused ? Colors.white : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.divider,
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        onChanged: _onChanged,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: widget.placeholder,
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: _isFocused ? AppColors.primary : AppColors.textSecondary,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: _onClear,
                  color: AppColors.textSecondary,
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

/// Filter chip row for categories
class FilterChipRow extends StatelessWidget {
  final List<FilterOption> options;
  final String? selectedId;
  final ValueChanged<String>? onSelected;
  final bool scrollable;

  const FilterChipRow({
    super.key,
    required this.options,
    this.selectedId,
    this.onSelected,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final chips = options.asMap().entries.map((entry) {
      final option = entry.value;
      final isSelected = option.id == selectedId;

      return _FilterChip(
        option: option,
        isSelected: isSelected,
        onTap: () {
          HapticFeedback.selectionClick();
          onSelected?.call(option.id);
        },
      )
          .animate(delay: Duration(milliseconds: entry.key * 30))
          .fadeIn(duration: 200.ms)
          .slideX(begin: 0.1, end: 0);
    }).toList();

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
            children: chips
                .map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: c,
                    ))
                .toList()),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }
}

class _FilterChip extends StatelessWidget {
  final FilterOption option;
  final bool isSelected;
  final VoidCallback? onTap;

  const _FilterChip({
    required this.option,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(option.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              option.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (option.count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.divider,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${option.count}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Filter option data class
class FilterOption {
  final String id;
  final String label;
  final String emoji;
  final int? count;
  final List<String>? actions;

  const FilterOption({
    required this.id,
    required this.label,
    required this.emoji,
    this.count,
    this.actions,
  });

  factory FilterOption.fromJson(Map<String, dynamic> json) {
    return FilterOption(
      id: json['id'] as String,
      label: json['label'] as String,
      emoji: json['emoji'] as String,
      actions: (json['actions'] as List<dynamic>?)?.cast<String>(),
    );
  }
}

/// Sort dropdown
class SortDropdown extends StatelessWidget {
  final List<SortOption> options;
  final String? selectedId;
  final ValueChanged<String>? onChanged;

  const SortDropdown({
    super.key,
    required this.options,
    this.selectedId,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = options.firstWhere(
      (o) => o.id == selectedId,
      orElse: () => options.first,
    );

    return PopupMenuButton<String>(
      onSelected: (value) {
        HapticFeedback.selectionClick();
        onChanged?.call(value);
      },
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              selected.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
      itemBuilder: (context) => options.map((option) {
        final isSelected = option.id == selectedId;
        return PopupMenuItem<String>(
          value: option.id,
          child: Row(
            children: [
              if (isSelected)
                const Icon(Icons.check, size: 18, color: AppColors.primary)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text(
                option.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Sort option data class
class SortOption {
  final String id;
  final String label;

  const SortOption({
    required this.id,
    required this.label,
  });

  factory SortOption.fromJson(Map<String, dynamic> json) {
    return SortOption(
      id: json['id'] as String,
      label: json['label'] as String,
    );
  }
}

/// Recent items section
class RecentItemsSection<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final Widget Function(T item) itemBuilder;
  final VoidCallback? onClearAll;

  const RecentItemsSection({
    super.key,
    required this.title,
    required this.items,
    required this.itemBuilder,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.history,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (onClearAll != null)
              TextButton(
                onPressed: onClearAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items
                .map((item) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: itemBuilder(item),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

/// No results found widget
class NoSearchResults extends StatelessWidget {
  final String query;
  final VoidCallback? onClear;

  const NoSearchResults({
    super.key,
    required this.query,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'No results for "$query"',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try a different search term or browse categories',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onClear != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onClear,
                child: const Text('Clear search'),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
