import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// Mood-based recipe suggestion selector
class MoodSelector extends StatelessWidget {
  final List<MoodOption> moods;
  final String? selectedMoodId;
  final Function(String moodId)? onMoodSelected;

  const MoodSelector({
    super.key,
    required this.moods,
    this.selectedMoodId,
    this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "What's your mood today?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: moods.length,
            itemBuilder: (context, index) {
              final mood = moods[index];
              final isSelected = mood.id == selectedMoodId;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _MoodCard(
                  mood: mood,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onMoodSelected?.call(mood.id);
                  },
                ),
              )
                  .animate(delay: Duration(milliseconds: index * 50))
                  .fadeIn()
                  .slideX(begin: 0.2, end: 0);
            },
          ),
        ),
      ],
    );
  }
}

class _MoodCard extends StatelessWidget {
  final MoodOption mood;
  final bool isSelected;
  final VoidCallback? onTap;

  const _MoodCard({
    required this.mood,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 90,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [mood.color, mood.color.withValues(alpha: 0.7)],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? mood.color : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: mood.color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              mood.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              mood.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class MoodOption {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final List<String> tags;

  const MoodOption({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    this.tags = const [],
  });
}

/// Ingredient-based recipe finder
class IngredientFinder extends StatefulWidget {
  final List<String> selectedIngredients;
  final List<String> suggestions;
  final Function(List<String>)? onIngredientsChanged;
  final VoidCallback? onSearch;

  const IngredientFinder({
    super.key,
    this.selectedIngredients = const [],
    this.suggestions = const [],
    this.onIngredientsChanged,
    this.onSearch,
  });

  @override
  State<IngredientFinder> createState() => _IngredientFinderState();
}

class _IngredientFinderState extends State<IngredientFinder> {
  final _controller = TextEditingController();
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedIngredients);
  }

  void _addIngredient(String ingredient) {
    if (!_selected.contains(ingredient)) {
      setState(() {
        _selected.add(ingredient);
      });
      widget.onIngredientsChanged?.call(_selected);
      HapticFeedback.lightImpact();
    }
    _controller.clear();
  }

  void _removeIngredient(String ingredient) {
    setState(() {
      _selected.remove(ingredient);
    });
    widget.onIngredientsChanged?.call(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🥚', style: TextStyle(fontSize: 24)),
              SizedBox(width: 10),
              Text(
                'What do you have?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Input
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Add an ingredient...',
              prefixIcon: const Icon(Icons.add),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) _addIngredient(value);
            },
          ),

          // Selected ingredients
          if (_selected.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selected.map((ing) {
                return Chip(
                  label: Text(ing),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeIngredient(ing),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                );
              }).toList(),
            ),
          ],

          // Suggestions
          if (widget.suggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Quick add:',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.suggestions
                  .where((s) => !_selected.contains(s))
                  .take(8)
                  .map((sug) {
                return GestureDetector(
                  onTap: () => _addIngredient(sug),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 14),
                        const SizedBox(width: 4),
                        Text(sug, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Search button
          if (_selected.isNotEmpty) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onSearch,
                icon: const Icon(Icons.search),
                label: Text(
                    'Find ${_selected.length == 1 ? 'Recipe' : 'Recipes'}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Similar recipe card
class SimilarRecipeCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final double similarity;
  final String matchReason;
  final VoidCallback? onTap;

  const SimilarRecipeCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.similarity,
    required this.matchReason,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.2,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surface,
                        child: const Center(
                            child: Text('🥗', style: TextStyle(fontSize: 32))),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(similarity * 100).round()}% match',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    matchReason,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

/// AI recommendation card
class AIRecommendationCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String reason;
  final String emoji;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const AIRecommendationCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.reason,
    required this.emoji,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Recommended for you',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (onDismiss != null)
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 18, color: AppColors.textSecondary),
                      onPressed: onDismiss,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.surface,
                          child: Center(
                              child: Text(emoji,
                                  style: const TextStyle(fontSize: 28))),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                reason,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Arrow
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textSecondary,
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

/// Quick filter chips
class QuickFilters extends StatelessWidget {
  final List<QuickFilter> filters;
  final Set<String> selectedIds;
  final Function(String filterId)? onToggle;

  const QuickFilters({
    super.key,
    required this.filters,
    this.selectedIds = const {},
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedIds.contains(filter.id);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onToggle?.call(filter.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? filter.color : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? filter.color : AppColors.divider,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: filter.color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(filter.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      filter.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class QuickFilter {
  final String id;
  final String label;
  final String emoji;
  final Color color;

  const QuickFilter({
    required this.id,
    required this.label,
    required this.emoji,
    required this.color,
  });
}
