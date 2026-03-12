import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/pantry_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../models/recipe_model.dart';

class WhatCanICookScreen extends StatefulWidget {
  const WhatCanICookScreen({super.key});

  @override
  State<WhatCanICookScreen> createState() => _WhatCanICookScreenState();
}

class _WhatCanICookScreenState extends State<WhatCanICookScreen> {
  final _ingredientController = TextEditingController();
  final List<String> _selectedIngredients = [];
  List<RecipeModel> _matchedRecipes = [];
  bool _isSearching = false;
  int _maxTime = 0; // 0 = no limit
  RecipeDifficulty? _maxDifficulty;

  @override
  void initState() {
    super.initState();
    // Pre-populate from pantry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pantry = context.read<PantryProvider>();
      final pantryNames = pantry.allItems.map((i) => i.name).toList();
      if (pantryNames.isNotEmpty) {
        setState(() => _selectedIngredients.addAll(pantryNames.take(5)));
        _search();
      }
    });
  }

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }

  void _addIngredient(String ingredient) {
    final trimmed = ingredient.trim();
    if (trimmed.isEmpty || _selectedIngredients.contains(trimmed)) return;
    setState(() {
      _selectedIngredients.add(trimmed);
    });
    _ingredientController.clear();
    _search();
  }

  void _removeIngredient(String ingredient) {
    setState(() {
      _selectedIngredients.remove(ingredient);
    });
    _search();
  }

  void _search() {
    if (_selectedIngredients.isEmpty) {
      setState(() => _matchedRecipes = []);
      return;
    }

    setState(() => _isSearching = true);

    // Simulate matching against available recipes
    final recipeProvider = context.read<RecipeProvider>();
    final allRecipes = recipeProvider.recipes;
    final lowerIngredients =
        _selectedIngredients.map((i) => i.toLowerCase()).toSet();

    final matched = allRecipes.where((recipe) {
      // Check ingredient match
      final recipeIngredients = recipe.steps
          .expand((s) => s.ingredients)
          .map((i) => i.name.toLowerCase())
          .toSet();

      final matchCount =
          recipeIngredients.intersection(lowerIngredients).length;
      if (matchCount == 0) return false;

      // Filter by time
      if (_maxTime > 0 &&
          recipe.prepTimeMinutes + recipe.cookTimeMinutes > _maxTime) {
        return false;
      }

      // Filter by difficulty
      if (_maxDifficulty != null &&
          recipe.difficulty.index > _maxDifficulty!.index) {
        return false;
      }

      return true;
    }).toList();

    // Sort by match percentage
    matched.sort((a, b) {
      final aIngredients = a.steps
          .expand((s) => s.ingredients)
          .map((i) => i.name.toLowerCase())
          .toSet();
      final bIngredients = b.steps
          .expand((s) => s.ingredients)
          .map((i) => i.name.toLowerCase())
          .toSet();
      final aMatch = aIngredients.intersection(lowerIngredients).length /
          aIngredients.length;
      final bMatch = bIngredients.intersection(lowerIngredients).length /
          bIngredients.length;
      return bMatch.compareTo(aMatch);
    });

    setState(() {
      _matchedRecipes = matched;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('What Can I Cook?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: scheme.surface,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(scheme)),
          SliverToBoxAdapter(child: _buildIngredientInput(scheme)),
          SliverToBoxAdapter(child: _buildSelectedChips(scheme)),
          SliverToBoxAdapter(child: _buildFilters(scheme)),
          if (_isSearching)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_selectedIngredients.isNotEmpty && _matchedRecipes.isEmpty)
            SliverToBoxAdapter(child: _buildNoResults(scheme))
          else
            _buildResults(scheme),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Text('🧑‍🍳', style: TextStyle(fontSize: 48)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smart Recipe Matcher',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tell me what ingredients you have, and I\'ll find recipes you can make!',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildIngredientInput(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ingredientController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Add ingredient (e.g., chicken, rice...)',
                prefixIcon: const Icon(Iconsax.search_normal),
                filled: true,
                fillColor:
                    scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _addIngredient,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: () => _addIngredient(_ingredientController.text),
            icon: const Icon(Iconsax.add),
            style: IconButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedChips(ColorScheme scheme) {
    if (_selectedIngredients.isEmpty) return const SizedBox(height: 8);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your ingredients (${_selectedIngredients.length})',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: scheme.onSurface),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _selectedIngredients.clear());
                  _search();
                },
                child: const Text('Clear all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedIngredients.map((ingredient) {
              return Chip(
                label: Text(ingredient),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeIngredient(ingredient),
                backgroundColor: scheme.primary.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                    color: scheme.primary, fontWeight: FontWeight.w500),
                deleteIconColor: scheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _maxTime,
              decoration: InputDecoration(
                labelText: 'Max time',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Any')),
                DropdownMenuItem(value: 15, child: Text('15 min')),
                DropdownMenuItem(value: 30, child: Text('30 min')),
                DropdownMenuItem(value: 60, child: Text('1 hour')),
              ],
              onChanged: (v) {
                setState(() => _maxTime = v ?? 0);
                _search();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<RecipeDifficulty?>(
              value: _maxDifficulty,
              decoration: InputDecoration(
                labelText: 'Difficulty',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Any')),
                DropdownMenuItem(
                    value: RecipeDifficulty.easy, child: Text('Easy')),
                DropdownMenuItem(
                    value: RecipeDifficulty.medium, child: Text('Medium')),
                DropdownMenuItem(
                    value: RecipeDifficulty.hard, child: Text('Hard')),
              ],
              onChanged: (v) {
                setState(() => _maxDifficulty = v);
                _search();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const Text('🤷', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'No recipes found',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adding more ingredients or\nadjust your filters',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildResults(ColorScheme scheme) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${_matchedRecipes.length} recipes found',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: scheme.onSurface),
                ),
              );
            }
            final recipe = _matchedRecipes[index - 1];
            return _buildRecipeMatchCard(scheme, recipe, index - 1);
          },
          childCount: _matchedRecipes.length + 1,
        ),
      ),
    );
  }

  Widget _buildRecipeMatchCard(
      ColorScheme scheme, RecipeModel recipe, int index) {
    final recipeIngredients = recipe.steps
        .expand((s) => s.ingredients)
        .map((i) => i.name.toLowerCase())
        .toSet();
    final lowerSelected =
        _selectedIngredients.map((i) => i.toLowerCase()).toSet();
    final matched = recipeIngredients.intersection(lowerSelected);
    final matchPct = recipeIngredients.isNotEmpty
        ? (matched.length / recipeIngredients.length * 100).round()
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/recipe/${recipe.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recipe.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: matchPct > 70
                          ? AppColors.success.withValues(alpha: 0.15)
                          : matchPct > 40
                              ? AppColors.warning.withValues(alpha: 0.15)
                              : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$matchPct% match',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: matchPct > 70
                            ? AppColors.success
                            : matchPct > 40
                                ? AppColors.warning
                                : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Iconsax.clock, size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${recipe.prepTimeMinutes + recipe.cookTimeMinutes} min',
                      style: TextStyle(
                          fontSize: 13, color: scheme.onSurfaceVariant)),
                  const SizedBox(width: 16),
                  Icon(Iconsax.chart, size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(recipe.difficulty.name,
                      style: TextStyle(
                          fontSize: 13, color: scheme.onSurfaceVariant)),
                  const SizedBox(width: 16),
                  Icon(Iconsax.people,
                      size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${recipe.servings} servings',
                      style: TextStyle(
                          fontSize: 13, color: scheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: recipeIngredients.map((ing) {
                  final isMatched = lowerSelected.contains(ing);
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isMatched
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ing,
                      style: TextStyle(
                        fontSize: 11,
                        color: isMatched ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 60).ms).fadeIn().slideY(begin: 0.1);
  }
}
