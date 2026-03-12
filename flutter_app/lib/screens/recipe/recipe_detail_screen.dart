import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/recipe_provider.dart';
import '../../models/recipe_model.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _isLiked = false;
  bool _isSaved = false;
  int _servings = 2;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  void _loadRecipe() {
    context.read<RecipeProvider>().getRecipe(widget.recipeId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: Consumer<RecipeProvider>(
        builder: (context, provider, _) {
          final recipe = provider.currentRecipe;

          if (recipe == null) {
            return Center(
              child: CircularProgressIndicator(color: scheme.primary),
            );
          }

          return CustomScrollView(
            slivers: [
              // App bar with image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                stretch: true,
                leading: _buildBackButton(),
                actions: [
                  _buildActionButton(
                    icon: _isSaved ? Iconsax.bookmark5 : Iconsax.bookmark,
                    onTap: () => setState(() => _isSaved = !_isSaved),
                  ),
                  _buildActionButton(
                    icon: Iconsax.share,
                    onTap: () =>
                        Share.share('Check out this recipe: ${recipe.title}'),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildHeroImage(recipe),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              scheme.scrim.withValues(alpha: 0.35),
                              Colors.transparent,
                              scheme.scrim.withValues(alpha: 0.55),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  transform: Matrix4.translationValues(0, -32, 0),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and author
                        _buildHeader(recipe),

                        const SizedBox(height: 24),

                        // Stats
                        _buildStats(recipe),

                        const SizedBox(height: 24),

                        // Description
                        if (recipe.description != null) ...[
                          Text(
                            recipe.description!,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.6,
                                    ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Tags
                        if (recipe.tags.isNotEmpty) ...[
                          _buildTags(recipe),
                          const SizedBox(height: 24),
                        ],

                        // Servings adjuster
                        _buildServingsAdjuster(recipe),

                        const SizedBox(height: 24),

                        // Ingredients
                        _buildIngredientsSection(recipe),

                        const SizedBox(height: 32),

                        // Steps
                        _buildStepsSection(recipe),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<RecipeProvider>(
        builder: (context, provider, _) {
          final recipe = provider.currentRecipe;
          if (recipe == null) return const SizedBox.shrink();

          return _buildBottomBar(recipe);
        },
      ),
    );
  }

  Widget _buildHeroImage(RecipeModel recipe) {
    final imageUrl = recipe.imageUrl ??
        (recipe.imageUrls.isNotEmpty ? recipe.imageUrls.first : null);

    if (imageUrl == null) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const Text('🍽️', style: TextStyle(fontSize: 56)),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      errorWidget: (context, url, error) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const Text('🍽️', style: TextStyle(fontSize: 56)),
      ),
    );
  }

  Widget _buildBackButton() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: scheme.inverseSurface.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.pop(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(Iconsax.arrow_left, color: scheme.onInverseSurface),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: scheme.inverseSurface.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: scheme.onInverseSurface),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(RecipeModel recipe) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recipe.title,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ).animate().fadeIn().slideY(begin: 0.2, end: 0),
        const SizedBox(height: 12),
        Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/user/${recipe.authorId}'),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            scheme.primaryContainer.withValues(alpha: 0.7),
                        child: Text(recipe.authorAvatar,
                            style: const TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe.authorName,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            '${recipe.likes} likes',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Like button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _isLiked = !_isLiked),
                borderRadius: BorderRadius.circular(20),
                child: Ink(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isLiked
                        ? scheme.errorContainer
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: scheme.outline.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isLiked ? Iconsax.heart5 : Iconsax.heart,
                        color:
                            _isLiked ? scheme.error : scheme.onSurfaceVariant,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isLiked ? 'Liked' : 'Like',
                        style: TextStyle(
                          color:
                              _isLiked ? scheme.error : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildStats(RecipeModel recipe) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shadowColor = theme.shadowColor.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.35 : 0.10,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Iconsax.timer_1, '${recipe.totalTimeMinutes}', 'mins'),
          _buildStatDivider(),
          _buildStatItem(
              Iconsax.profile_2user, '${recipe.servings}', 'servings'),
          _buildStatDivider(),
          _buildStatItem(
            Iconsax.chart,
            recipe.difficulty.name.toUpperCase(),
            'difficulty',
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: scheme.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 1,
      height: 50,
      color: scheme.outline.withValues(alpha: 0.22),
    );
  }

  Widget _buildTags(RecipeModel recipe) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: recipe.tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            tag,
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildServingsAdjuster(RecipeModel recipe) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Servings',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Row(
            children: [
              _buildServingButton(
                icon: Icons.remove,
                onTap: () {
                  if (_servings > 1) setState(() => _servings--);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '$_servings',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              _buildServingButton(
                icon: Icons.add,
                onTap: () => setState(() => _servings++),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServingButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: scheme.primary, size: 20),
        ),
      ),
    );
  }

  Widget _buildIngredientsSection(RecipeModel recipe) {
    final scheme = Theme.of(context).colorScheme;
    final ingredients = recipe.allIngredients;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingredients',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          '${ingredients.length} items',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        ...ingredients.asMap().entries.map((entry) {
          final ing = entry.value;
          final multiplier = _servings / recipe.servings;
          final amount = double.tryParse(ing.amount) ?? 1;
          final adjustedAmount = (amount * multiplier).toStringAsFixed(
            amount * multiplier % 1 == 0 ? 0 : 1,
          );

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outline.withValues(alpha: 0.10),
              ),
            ),
            child: Row(
              children: [
                Text(ing.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    ing.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '$adjustedAmount ${ing.unit}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: (entry.key * 50).ms)
              .slideX(begin: 0.1, end: 0);
        }),
      ],
    );
  }

  Widget _buildStepsSection(RecipeModel recipe) {
    final scheme = Theme.of(context).colorScheme;
    final steps = recipe.displaySteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instructions',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          '${steps.length} steps',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map((entry) {
          final step = entry.value;
          final index = entry.key;

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step number
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Step content
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: scheme.outline.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(step.actionEmoji,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              '${step.actionName} with ${step.toolName}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        if (step.ingredients.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: step.ingredients.map((ing) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${ing.emoji} ${ing.name}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        if (step.duration != null ||
                            step.temperature != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (step.duration != null)
                                _buildStepTag(Iconsax.timer_1, step.duration!,
                                    scheme.tertiary),
                              if (step.temperature != null)
                                _buildStepTag(Iconsax.flash_1,
                                    step.temperature!, scheme.error),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: (index * 100).ms)
              .slideX(begin: 0.1, end: 0);
        }),
      ],
    );
  }

  Widget _buildStepTag(IconData icon, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(RecipeModel recipe) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shadowColor = theme.shadowColor.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.35 : 0.12,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.outline.withValues(alpha: 0.12)),
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/recipe/${recipe.id}/cook'),
                  icon: const Icon(Iconsax.play),
                  label: const Text('Start Cooking'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
