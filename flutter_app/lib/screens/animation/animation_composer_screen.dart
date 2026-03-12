import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/kitchen_image_paths.dart';
import '../../core/theme/app_theme.dart';
import '../../models/animation_model.dart';
import '../../widgets/animation/recipe_animation_player.dart';

/// A beautiful drag-and-drop interface for composing recipe animations
/// from modular cooking blocks.
class AnimationComposerScreen extends StatefulWidget {
  const AnimationComposerScreen({super.key});

  @override
  State<AnimationComposerScreen> createState() =>
      _AnimationComposerScreenState();
}

class _AnimationComposerScreenState extends State<AnimationComposerScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _titleController;

  Map<String, dynamic> _kitchenData = {};
  List<ComposableBlock> _availableBlocks = [];
  List<Map<String, dynamic>> _ingredients = [];
  List<Map<String, dynamic>> _actions = [];
  List<Map<String, dynamic>> _tools = [];

  // Composer state
  final List<_ComposerStep> _composedSteps = [];
  String? _selectedIngredientId;
  bool _isPreviewMode = false;
  RecipeAnimation? _previewAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _titleController = TextEditingController(text: 'My Recipe Animation');
    _loadKitchenData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadKitchenData() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/kitchen_data.json',
      );
      final data = json.decode(jsonString) as Map<String, dynamic>;

      setState(() {
        _kitchenData = data;
        _ingredients =
            List<Map<String, dynamic>>.from(data['ingredients'] ?? []);
        _actions = List<Map<String, dynamic>>.from(data['actions'] ?? []);
        _tools = List<Map<String, dynamic>>.from(data['tools'] ?? []);

        final blocksData =
            data['composableBlocks'] as Map<String, dynamic>? ?? {};
        _availableBlocks = blocksData.entries.map((e) {
          final blockJson = e.value as Map<String, dynamic>;
          blockJson['id'] = e.key;
          return ComposableBlock.fromJson(blockJson);
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading kitchen data: $e');
    }
  }

  Widget _assetThumb(
    String assetPath, {
    required Widget fallback,
    double size = 40,
    double borderRadius = 10,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return SizedBox(
            width: size,
            height: size,
            child: Center(child: fallback),
          );
        },
      ),
    );
  }

  void _addBlock(ComposableBlock block) {
    if (_selectedIngredientId == null) {
      _showSelectIngredientDialog();
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _composedSteps.add(_ComposerStep(
        id: 'step_${DateTime.now().millisecondsSinceEpoch}',
        type: _StepType.block,
        blockId: block.id,
        blockName: block.name,
        ingredientIds: [_selectedIngredientId!],
        emoji: _getBlockEmoji(block.id),
      ));
    });
  }

  void _addAction(Map<String, dynamic> action) {
    if (_selectedIngredientId == null) {
      _showSelectIngredientDialog();
      return;
    }

    HapticFeedback.mediumImpact();
    final toolId = action['requiresToolId'] as String?;

    setState(() {
      _composedSteps.add(_ComposerStep(
        id: 'step_${DateTime.now().millisecondsSinceEpoch}',
        type: _StepType.action,
        actionId: action['id'] as String,
        actionName: action['name'] as String,
        toolId: toolId,
        ingredientIds: [_selectedIngredientId!],
        emoji: action['icon'] as String? ?? '👨‍🍳',
      ));
    });
  }

  void _removeStep(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _composedSteps.removeAt(index);
    });
  }

  void _reorderSteps(int oldIndex, int newIndex) {
    HapticFeedback.selectionClick();
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _composedSteps.removeAt(oldIndex);
      _composedSteps.insert(newIndex, item);
    });
  }

  void _showSelectIngredientDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _IngredientSelectorSheet(
        ingredients: _ingredients,
        onSelect: (ingredientId) {
          setState(() => _selectedIngredientId = ingredientId);
          Navigator.pop(context);
        },
      ),
    );
  }

  RecipeAnimation _buildAnimation() {
    final builder = RecipeAnimationBuilder(
      id: 'composed_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text,
      description: 'A custom recipe animation',
    );

    // Add selected ingredient
    if (_selectedIngredientId != null) {
      final ing = _ingredients.firstWhere(
        (i) => i['id'] == _selectedIngredientId,
        orElse: () => {},
      );
      if (ing.isNotEmpty) {
        builder.addIngredient(
          ing['id'] as String,
          ing['name'] as String,
          ing['emoji'] as String,
        );
      }
    }

    // Add steps
    for (final step in _composedSteps) {
      if (step.type == _StepType.action && step.actionId != null) {
        final actionTransform = _getTransformation(step.actionId!);
        builder.addStep(
          actionId: step.actionId,
          ingredientIds: step.ingredientIds,
          toolId: step.toolId,
          fromState: actionTransform?['inputStates']?.first ?? 'raw',
          toState: actionTransform?['outputState'] ?? 'cooked',
          duration: const Duration(milliseconds: 1500),
        );
      } else if (step.type == _StepType.block && step.blockId != null) {
        final block = _availableBlocks.firstWhere(
          (b) => b.id == step.blockId,
          orElse: () => _availableBlocks.first,
        );
        for (final actionId in block.sequence) {
          final actionTransform = _getTransformation(actionId);
          builder.addStep(
            blockId: step.blockId,
            actionId: actionId,
            ingredientIds: step.ingredientIds,
            fromState: actionTransform?['inputStates']?.first ?? 'raw',
            toState: actionTransform?['outputState'] ?? 'cooked',
            duration: const Duration(milliseconds: 1200),
          );
        }
      }
    }

    return builder.build();
  }

  Map<String, dynamic>? _getTransformation(String actionId) {
    final transforms =
        _kitchenData['actionTransformations'] as Map<String, dynamic>?;
    return transforms?[actionId] as Map<String, dynamic>?;
  }

  void _togglePreview() {
    HapticFeedback.mediumImpact();
    if (_composedSteps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Add some steps first!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _isPreviewMode = !_isPreviewMode;
      if (_isPreviewMode) {
        _previewAnimation = _buildAnimation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Main content
            Expanded(
              child:
                  _isPreviewMode ? _buildPreviewMode() : _buildComposerMode(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.divider.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.arrow_left, size: 20),
                ),
              ),

              const SizedBox(width: 16),

              // Title input
              Expanded(
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Recipe Animation Title',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),

              // Preview toggle
              GestureDetector(
                onTap: _togglePreview,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: _isPreviewMode ? AppColors.primaryGradient : null,
                    color: _isPreviewMode
                        ? null
                        : AppColors.divider.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPreviewMode ? Iconsax.edit : Iconsax.play,
                        size: 18,
                        color: _isPreviewMode
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isPreviewMode ? 'Edit' : 'Preview',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _isPreviewMode
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Selected ingredient chip
          if (_selectedIngredientId != null)
            _buildSelectedIngredientChip()
          else
            _buildSelectIngredientButton(),
        ],
      ),
    );
  }

  Widget _buildSelectedIngredientChip() {
    final ing = _ingredients.firstWhere(
      (i) => i['id'] == _selectedIngredientId,
      orElse: () => {},
    );

    return GestureDetector(
      onTap: _showSelectIngredientDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _assetThumb(
              KitchenImagePaths.ingredient(ing['id'] as String? ?? ''),
              fallback: Text(
                ing['emoji'] as String? ?? '🥗',
                style: const TextStyle(fontSize: 18),
              ),
              size: 26,
              borderRadius: 8,
            ),
            const SizedBox(width: 8),
            Text(
              ing['name'] as String? ?? 'Ingredient',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Iconsax.edit_2, size: 14, color: AppColors.primary),
          ],
        ),
      ).animate().scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1, 1),
            duration: 300.ms,
            curve: Curves.elasticOut,
          ),
    );
  }

  Widget _buildSelectIngredientButton() {
    return GestureDetector(
      onTap: _showSelectIngredientDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.add_circle, size: 18, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Select Ingredient to Animate',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.02, 1.02),
          duration: 1.seconds),
    );
  }

  Widget _buildComposerMode() {
    return Row(
      children: [
        // Left panel - Available blocks and actions
        Expanded(
          flex: 2,
          child: _buildBlocksPanel(),
        ),

        // Right panel - Composed timeline
        Expanded(
          flex: 3,
          child: _buildTimelinePanel(),
        ),
      ],
    );
  }

  Widget _buildBlocksPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tabs
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.divider.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              tabs: const [
                Tab(text: 'Blocks'),
                Tab(text: 'Actions'),
                Tab(text: 'Tools'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBlocksGrid(),
                _buildActionsGrid(),
                _buildToolsGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlocksGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _availableBlocks.length,
      itemBuilder: (context, index) {
        final block = _availableBlocks[index];
        return _buildBlockCard(block, index);
      },
    );
  }

  Widget _buildBlockCard(ComposableBlock block, int index) {
    return GestureDetector(
      onTap: () => _addBlock(block),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _assetThumb(
              KitchenImagePaths.block(block.id),
              fallback: Text(
                _getBlockEmoji(block.id),
                style: const TextStyle(fontSize: 32),
              ),
              size: 54,
              borderRadius: 14,
            ),
            const SizedBox(height: 8),
            Text(
              block.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              block.estimatedTime,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: index * 50))
          .fadeIn()
          .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
    );
  }

  Widget _buildActionsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _actions.length,
      itemBuilder: (context, index) {
        final action = _actions[index];
        return _buildActionCard(action, index);
      },
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action, int index) {
    final animationKey = action['animationKey'] as String?;
    final fallback = Text(
      action['icon'] as String? ?? '👨‍🍳',
      style: const TextStyle(fontSize: 24),
    );

    return GestureDetector(
      onTap: () => _addAction(action),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (animationKey != null)
              _assetThumb(
                KitchenImagePaths.action(animationKey),
                fallback: fallback,
                size: 44,
                borderRadius: 12,
              )
            else
              fallback,
            const SizedBox(height: 4),
            Text(
              action['name'] as String? ?? '',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: index * 30))
          .fadeIn()
          .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
    );
  }

  Widget _buildToolsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _tools.length,
      itemBuilder: (context, index) {
        final tool = _tools[index];
        final animationKey = tool['animationKey'] as String?;
        final fallback = Text(
          tool['icon'] as String? ?? '🔧',
          style: const TextStyle(fontSize: 24),
        );
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (animationKey != null)
                _assetThumb(
                  KitchenImagePaths.tool(animationKey),
                  fallback: fallback,
                  size: 44,
                  borderRadius: 12,
                )
              else
                fallback,
              const SizedBox(height: 4),
              Text(
                tool['name'] as String? ?? '',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        )
            .animate(delay: Duration(milliseconds: index * 30))
            .fadeIn()
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
      },
    );
  }

  Widget _buildTimelinePanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Iconsax.timer_1, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Animation Timeline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_composedSteps.length} steps',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Timeline
          Expanded(
            child: _composedSteps.isEmpty
                ? _buildEmptyTimeline()
                : _buildStepsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTimeline() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.divider.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.video_add,
              size: 36,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Start adding steps!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap on blocks or actions to add them\nto your animation timeline',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fadeIn().scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1, 1),
          ),
    );
  }

  Widget _buildStepsList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      onReorder: _reorderSteps,
      itemCount: _composedSteps.length,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Material(
              elevation: 4,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              child: child,
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final step = _composedSteps[index];
        return _buildStepCard(step, index);
      },
    );
  }

  Widget _buildStepCard(_ComposerStep step, int index) {
    return Container(
      key: ValueKey(step.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey('dismiss_${step.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _removeStep(index),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Iconsax.trash, color: AppColors.error),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              // Drag handle
              Icon(
                Iconsax.menu,
                size: 20,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),

              const SizedBox(width: 12),

              // Step number
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Icon
              Text(step.emoji, style: const TextStyle(fontSize: 28)),

              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.type == _StepType.block
                          ? step.blockName ?? 'Block'
                          : step.actionName ?? 'Action',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.type == _StepType.block
                          ? 'Cooking Block'
                          : 'Single Action',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Delete button
              GestureDetector(
                onTap: () => _removeStep(index),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.close_circle,
                    size: 16,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        )
            .animate(delay: Duration(milliseconds: index * 50))
            .fadeIn()
            .slideX(begin: 0.1, end: 0),
      ),
    );
  }

  Widget _buildPreviewMode() {
    if (_previewAnimation == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: RecipeAnimationPlayer(
        animation: _previewAnimation!,
        autoPlay: false,
        onComplete: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Animation complete! 🎉'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }

  String _getBlockEmoji(String blockId) {
    const blockEmojis = {
      'prep_vegetable': '🥬',
      'quick_dice': '🔪',
      'asian_stir_fry': '🥡',
      'pan_sear': '🍳',
      'slow_simmer': '🍲',
      'finish_plate': '🥗',
      'marinate_grill': '🔥',
      'blend_smooth': '🥤',
    };
    return blockEmojis[blockId] ?? '📦';
  }
}

/// Internal step type
enum _StepType { block, action }

/// Internal composer step model
class _ComposerStep {
  final String id;
  final _StepType type;
  final String? blockId;
  final String? blockName;
  final String? actionId;
  final String? actionName;
  final String? toolId;
  final List<String> ingredientIds;
  final String emoji;

  const _ComposerStep({
    required this.id,
    required this.type,
    this.blockId,
    this.blockName,
    this.actionId,
    this.actionName,
    this.toolId,
    required this.ingredientIds,
    required this.emoji,
  });
}

/// Ingredient selector bottom sheet
class _IngredientSelectorSheet extends StatefulWidget {
  final List<Map<String, dynamic>> ingredients;
  final Function(String) onSelect;

  const _IngredientSelectorSheet({
    required this.ingredients,
    required this.onSelect,
  });

  @override
  State<_IngredientSelectorSheet> createState() =>
      _IngredientSelectorSheetState();
}

class _IngredientSelectorSheetState extends State<_IngredientSelectorSheet> {
  String _searchQuery = '';
  String _selectedCategory = 'all';

  List<Map<String, dynamic>> get _filteredIngredients {
    return widget.ingredients.where((ing) {
      final matchesSearch = _searchQuery.isEmpty ||
          (ing['name'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'all' || ing['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Ingredient',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),

                // Search
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Search ingredients...',
                      border: InputBorder.none,
                      icon: Icon(Iconsax.search_normal,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Category filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'all',
                      'vegetable',
                      'meat',
                      'seafood',
                      'dairy',
                      'grain',
                      'fruit'
                    ]
                        .map((cat) => GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedCategory = cat),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _selectedCategory == cat
                                      ? AppColors.primary
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  cat == 'all'
                                      ? 'All'
                                      : cat[0].toUpperCase() + cat.substring(1),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedCategory == cat
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          // Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.9,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _filteredIngredients.length,
              itemBuilder: (context, index) {
                final ing = _filteredIngredients[index];
                final ingId = ing['id'] as String? ?? '';
                final fallback = Text(
                  ing['emoji'] as String? ?? '🥗',
                  style: const TextStyle(fontSize: 32),
                );
                return GestureDetector(
                  onTap: () => widget.onSelect(ing['id'] as String),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            KitchenImagePaths.ingredient(ingId),
                            width: 54,
                            height: 54,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return SizedBox(
                                width: 54,
                                height: 54,
                                child: Center(child: fallback),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ing['name'] as String? ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )
                      .animate(delay: Duration(milliseconds: index * 20))
                      .fadeIn()
                      .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1, 1)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
