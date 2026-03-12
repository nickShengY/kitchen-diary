import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';
// import '../../providers/subscription_provider.dart'; // Reserved for VIP features
import '../../models/recipe_model.dart';
import '../../data/kitchen_data_repository.dart';
import '../../widgets/common/custom_button.dart';
// subscription_service import removed - using provider instead

class RecipeBuilderScreen extends StatefulWidget {
  final String? recipeId;

  const RecipeBuilderScreen({super.key, this.recipeId});

  @override
  State<RecipeBuilderScreen> createState() => _RecipeBuilderScreenState();
}

class _RecipeBuilderScreenState extends State<RecipeBuilderScreen> {
  final _nameController = TextEditingController(text: 'My Delicious Recipe');
  final _descController = TextEditingController();
  final List<CookingStep> _steps = [];

  // Editor state
  bool _isEditing = false;
  int _currentStage =
      0; // 0: station, 1: tool, 2: ingredients, 3: action, 4: details
  Map<String, dynamic> _currentStep = {};
  List<Map<String, dynamic>> _selectedIngredients = [];
  KitchenDataRepository? _kitchenData;

  final _stages = ['Station', 'Tool', 'Ingredients', 'Action', 'Details'];

  @override
  void initState() {
    super.initState();
    _loadKitchenData();
    if (widget.recipeId != null) {
      _loadRecipe();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipe() async {
    final recipe =
        await context.read<RecipeProvider>().getRecipe(widget.recipeId!);
    if (recipe != null) {
      setState(() {
        _nameController.text = recipe.title;
        _descController.text = recipe.description ?? '';
        _steps.addAll(recipe.steps);
      });
    }
  }

  void _startNewStep() {
    setState(() {
      _isEditing = true;
      _currentStage = 0;
      _currentStep = {'id': const Uuid().v4()};
      _selectedIngredients = [];
    });
  }

  Future<void> _loadKitchenData() async {
    final data = await KitchenDataRepository.load();
    if (!mounted) return;
    setState(() {
      _kitchenData = data;
    });
  }

  List<Map<String, dynamic>> get _ingredients =>
      _kitchenData?.ingredients ?? const [];

  List<Map<String, dynamic>> get _tools =>
      _kitchenData?.tools ?? const [];

  List<Map<String, dynamic>> get _actions =>
      _kitchenData?.actions ?? const [];

  List<String> get _temperatures =>
      _kitchenData?.temperatures ?? const ['Low', 'Medium', 'High'];

  List<String> get _times => _kitchenData?.times ?? const ['1 min', '5 mins', '10 mins'];

  void _finishStep() {
    if (_currentStep['actionId'] != null) {
      final step = CookingStep(
        id: _currentStep['id'],
        stepNumber: _steps.length + 1,
        station: StationCategory.values.firstWhere(
          (s) => s.name == _currentStep['station'],
          orElse: () => StationCategory.prep,
        ),
        ingredients: _selectedIngredients
            .map((i) => RecipeIngredient(
                  ingredientId: i['id'],
                  name: i['name'],
                  emoji: i['emoji'],
                  amount: i['amount'] ?? '1',
                  unit: i['unit'] ?? 'pcs',
                ))
            .toList(),
        toolId: _currentStep['toolId'] ?? '',
        toolName: _currentStep['toolName'] ?? '',
        toolIcon: _currentStep['toolIcon'] ?? '',
        actionId: _currentStep['actionId'] ?? '',
        actionName: _currentStep['actionName'] ?? '',
        actionEmoji: _currentStep['actionEmoji'] ?? '',
        temperature: _currentStep['temperature'],
        duration: _currentStep['duration'],
        waterLevel: _currentStep['waterLevel'],
      );

      setState(() {
        _steps.add(step);
        _isEditing = false;
      });

      HapticFeedback.mediumImpact();
    }
  }

  void _deleteStep(String stepId) {
    setState(() {
      _steps.removeWhere((s) => s.id == stepId);
    });
  }

  Future<void> _saveRecipe() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please name your recipe')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final user = auth.user;

    if (user == null) return;

    final recipe = RecipeModel(
      id: widget.recipeId ?? const Uuid().v4(),
      title: _nameController.text,
      description:
          _descController.text.isNotEmpty ? _descController.text : null,
      authorId: user.id,
      authorName: user.displayName,
      authorAvatar: user.avatarEmoji,
      authorPhotoUrl: user.photoUrl,
      steps: _steps,
      tags: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final provider = context.read<RecipeProvider>();

    if (widget.recipeId != null) {
      await provider.updateRecipe(recipe);
    } else {
      await provider.createRecipe(recipe);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe saved! 🎉')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // VIP status available via context.watch<SubscriptionProvider>().isVip

    return Scaffold(
      body: _isEditing ? _buildEditor() : _buildTimeline(),
    );
  }

  Widget _buildTimeline() {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        style: Theme.of(context).textTheme.headlineMedium,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Name your recipe...',
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _saveRecipe,
                      icon: const Icon(Iconsax.tick_circle),
                      color: AppColors.primary,
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Iconsax.timer_1,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${_steps.length} steps • ${_steps.length * 5} mins est.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Steps Timeline
          Expanded(
            child: _steps.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _steps.length,
                    itemBuilder: (context, index) {
                      return _buildStepCard(_steps[index], index);
                    },
                  ),
          ),

          // Add Step Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: CustomButton(
              text: 'Add Step',
              icon: Iconsax.add,
              onPressed: _startNewStep,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👩‍🍳', style: TextStyle(fontSize: 80))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 1500.ms),
          const SizedBox(height: 20),
          Text(
            'Your kitchen is empty!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to start cooking.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildStepCard(CookingStep step, int index) {
    // VIP status available via context.watch<SubscriptionProvider>().isVip

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: step.station == StationCategory.cook
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: step.station == StationCategory.cook
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    step.actionEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              if (index < _steps.length - 1)
                Container(
                  width: 3,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.secondary,
                        AppColors.primary.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Step content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
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
                      Expanded(
                        child: Text(
                          '${step.actionName} using ${step.toolName}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _deleteStep(step.id),
                        icon: const Icon(Iconsax.trash, size: 18),
                        color: AppColors.textLight,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Ingredients
                  if (step.ingredients.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: step.ingredients.map((ing) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.shade100),
                          ),
                          child: Text(
                            '${ing.emoji} ${ing.amount} ${ing.unit} ${ing.name}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 12),

                  // Settings
                  Row(
                    children: [
                      if (step.temperature != null)
                        _buildSettingChip(
                          icon: Iconsax.flash_1,
                          label: step.temperature!,
                          color: Colors.red,
                        ),
                      if (step.duration != null)
                        _buildSettingChip(
                          icon: Iconsax.timer_1,
                          label: step.duration!,
                          color: Colors.blue,
                        ),
                      if (step.waterLevel != null)
                        _buildSettingChip(
                          icon: Iconsax.drop,
                          label: step.waterLevel!,
                          color: Colors.cyan,
                        ),
                    ],
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: (index * 100).ms)
                .slideX(begin: 0.1, end: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Widget _buildEditor() {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // Editor header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _isEditing = false),
                    icon: const Icon(Iconsax.arrow_left),
                  ),
                  Expanded(
                    child: Text(
                      _stages[_currentStage],
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Progress bar
            Container(
              height: 4,
              color: Colors.grey.shade200,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (_currentStage + 1) / _stages.length,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Editor content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildStageContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageContent() {
    switch (_currentStage) {
      case 0:
        return _buildStationSelection();
      case 1:
        return _buildToolSelection();
      case 2:
        return _buildIngredientSelection();
      case 3:
        return _buildActionSelection();
      case 4:
        return _buildDetailsSelection();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStationSelection() {
    final stations = [
      {
        'id': 'prep',
        'name': 'Prep Station',
        'desc': 'Chop, Mix, Peel',
        'icon': '🥬',
        'color': Colors.green
      },
      {
        'id': 'cook',
        'name': 'Hot Station',
        'desc': 'Stove, Oven, Grill',
        'icon': '🔥',
        'color': Colors.red
      },
      {
        'id': 'finish',
        'name': 'Plating',
        'desc': 'Serve & Garnish',
        'icon': '🥗',
        'color': Colors.amber
      },
    ];

    return Column(
      children: stations.map((s) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentStep['station'] = s['id'];
              _currentStage = s['id'] == 'finish' ? 3 : 1;
            });
            HapticFeedback.selectionClick();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _currentStep['station'] == s['id']
                    ? AppColors.secondary
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: (s['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(s['icon'] as String,
                        style: const TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['name'] as String,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        s['desc'] as String,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(Iconsax.arrow_right_3, color: AppColors.textLight),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(delay: (stations.indexOf(s) * 100).ms)
            .slideX(begin: 0.1, end: 0);
      }).toList(),
    );
  }

  Widget _buildToolSelection() {
    final station = _currentStep['station'] as String?;
    final tools = _tools.where((t) {
      if (station == 'prep') return t['type'] == 'prep';
      if (station == 'cook') {
        return t['type'] == 'cook' || t['type'] == 'appliance';
      }
      return true;
    }).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        final isSelected = _currentStep['toolId'] == tool['id'];

        return GestureDetector(
          onTap: () {
            setState(() {
              _currentStep['toolId'] = tool['id'];
              _currentStep['toolName'] = tool['name'];
              _currentStep['toolIcon'] = tool['icon'];
              _currentStage = 2;
            });
            HapticFeedback.selectionClick();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tool['icon'] as String,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 8),
                Text(
                  tool['name'] as String,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(delay: (index * 50).ms)
            .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
      },
    );
  }

  Widget _buildIngredientSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected ingredients
        if (_selectedIngredients.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedIngredients.map((ing) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${ing['emoji']} ${ing['name']}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIngredients
                              .removeWhere((i) => i['id'] == ing['id']);
                        });
                      },
                      child: const Icon(Icons.close,
                          size: 16, color: Colors.white),
                    ),
                  ],
                ),
              ).animate().scale(duration: 200.ms);
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Ingredient grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: _ingredients.length,
          itemBuilder: (context, index) {
            final ing = _ingredients[index];
            final isSelected =
                _selectedIngredients.any((i) => i['id'] == ing['id']);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedIngredients
                        .removeWhere((i) => i['id'] == ing['id']);
                  } else {
                    _selectedIngredients.add({
                      ...ing,
                      'amount': '1',
                      'unit': ing['unit'],
                    });
                  }
                });
                HapticFeedback.selectionClick();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : Colors.grey.shade100,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      ing['emoji'] as String,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ing['name'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        CustomButton(
          text: 'Done with Ingredients',
          onPressed: _selectedIngredients.isEmpty
              ? null
              : () => setState(() => _currentStage = 3),
        ),
      ],
    );
  }

  Widget _buildActionSelection() {
    final toolId = _currentStep['toolId'] as String?;
    final actions = _actions.where((a) {
      final requiresToolId = a['requiresToolId'] as String?;
      return requiresToolId == toolId || requiresToolId == null;
    }).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];

        return GestureDetector(
          onTap: () {
            setState(() {
              _currentStep['actionId'] = action['id'];
              _currentStep['actionName'] = action['name'];
              _currentStep['actionEmoji'] = action['icon'];
              _currentStep['requiresHeat'] = action['requiresHeat'];
              _currentStage = 4;
            });
            HapticFeedback.selectionClick();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  action['icon'] as String,
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 8),
                Text(
                  action['name'] as String,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (index * 50).ms);
      },
    );
  }

  Widget _buildDetailsSelection() {
    final requiresHeat = _currentStep['requiresHeat'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Temperature
        if (requiresHeat) ...[
          Text('🌡️ Temperature',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _temperatures.map((t) {
              final isSelected = _currentStep['temperature'] == t;
              return GestureDetector(
                onTap: () {
                  setState(() => _currentStep['temperature'] = t);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.red.shade500 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.red.shade500
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Text(
                    t,
                    style: TextStyle(
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Duration
        Text('⏱️ Duration', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _times.map((t) {
            final isSelected = _currentStep['duration'] == t;
            return GestureDetector(
              onTap: () {
                setState(() => _currentStep['duration'] = t);
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade500 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.blue.shade500
                        : Colors.grey.shade200,
                  ),
                ),
                child: Text(
                  t,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 32),

        CustomButton(
          text: 'Add Step to Recipe',
          onPressed: _finishStep,
        ),
      ],
    );
  }
}
