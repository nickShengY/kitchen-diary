import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../data/kitchen_data_repository.dart';
import '../../models/procedure_model.dart';
import '../../models/recipe_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../services/procedure_compiler.dart';
import '../../widgets/animation/recipe_animation_player.dart';
import '../../widgets/common/custom_button.dart';
import 'guided_step_builder_sheet.dart';

class ProcedureBuilderScreen extends StatefulWidget {
  final String? recipeId;

  const ProcedureBuilderScreen({super.key, this.recipeId});

  @override
  State<ProcedureBuilderScreen> createState() => _ProcedureBuilderScreenState();
}

class _ProcedureBuilderScreenState extends State<ProcedureBuilderScreen> {
  static const _uuid = Uuid();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  KitchenDataRepository? _kitchenData;
  RecipeModel? _loadedRecipe;

  List<MaterialLot> _lots = [];
  List<ProcedureOperation> _operations = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
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

  List<String> get _waterLevels =>
      _kitchenData?.waterLevels ?? const ['Splash', '1 cup', 'Covered'];

  Future<void> _init() async {
    final recipeProvider = context.read<RecipeProvider>();
    final kitchenData = await KitchenDataRepository.load();

    RecipeModel? recipe;
    if (widget.recipeId != null) {
      recipe = await recipeProvider.getRecipe(widget.recipeId!);
    }

    if (!mounted) return;

    RecipeProcedure? procedure;
    if (recipe != null) {
      _titleController.text = recipe.title;
      _descController.text = recipe.description ?? '';
      procedure = recipe.procedure;

      if (procedure == null && recipe.steps.isNotEmpty) {
        procedure = ProcedureCompiler.migrateFromCookingSteps(
          steps: recipe.steps,
          kitchenData: kitchenData,
        );
      }
    }

    setState(() {
      _kitchenData = kitchenData;
      _loadedRecipe = recipe;
      _lots = procedure?.lots.toList() ?? [];
      _operations = procedure?.operations.toList() ?? [];
      _isLoading = false;
    });
  }

  String _getOutputState(String actionId, String fallbackState) {
    final raw = _kitchenData?.rawData;
    final transforms = raw?['actionTransformations'];

    if (transforms is Map) {
      final transform = transforms[actionId];
      if (transform is Map) {
        final output = transform['outputState'];
        if (output is String && output.isNotEmpty) return output;
      }
    }

    return fallbackState;
  }

  RecipeProcedure _buildProcedure() {
    return RecipeProcedure(
      version: '1.0.0',
      lots: _lots,
      operations: _operations,
    );
  }

  Map<String, dynamic>? _findActionById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final action in _actions) {
      if (action['id'] == id) return action;
    }
    return null;
  }

  Map<String, dynamic>? _findToolById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final tool in _tools) {
      if (tool['id'] == id) return tool;
    }
    return null;
  }

  String _suggestOutputName(
    List<MaterialLot> inputLots,
    String actionName, {
    String? preferredName,
  }) {
    final trimmed = preferredName?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    if (inputLots.length == 1) return inputLots.first.name;

    final action = actionName.toLowerCase();
    if (action.contains('mix') ||
        action.contains('whisk') ||
        action.contains('blend') ||
        action.contains('marinate')) {
      return 'Mix Base';
    }
    if (action.contains('boil') ||
        action.contains('simmer') ||
        action.contains('steam') ||
        action.contains('bake') ||
        action.contains('roast') ||
        action.contains('grill') ||
        action.contains('fry') ||
        action.contains('sear')) {
      return 'Cooked Dish';
    }
    return 'Prepared Ingredients';
  }

  String _buildAssetKey({
    required String baseName,
    required String fallbackId,
    required String state,
  }) {
    final normalized = baseName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final base = normalized.isEmpty ? fallbackId : normalized;
    return base + '_' + state;
  }

  List<MaterialLot> _createOutputLots({
    required List<MaterialLot> inputLots,
    required String operationId,
    required String outputState,
    required String outputName,
  }) {
    if (inputLots.length == 1) {
      final lot = inputLots.first;
      return [
        lot.copyWith(
          id: _uuid.v4(),
          name: outputName,
          state: outputState,
          assetKey: _buildAssetKey(
            baseName: outputName,
            fallbackId: lot.ingredientId,
            state: outputState,
          ),
          producedByOperationId: operationId,
          derivedFromLotId: lot.id,
          componentLotIds: null,
        ),
      ];
    }

    return [
      MaterialLot(
        id: _uuid.v4(),
        ingredientId: 'mixture',
        name: outputName,
        emoji: 'mix',
        amount: '1',
        unit: 'batch',
        state: outputState,
        assetKey: _buildAssetKey(
          baseName: outputName,
          fallbackId: 'mixture',
          state: outputState,
        ),
        componentLotIds: inputLots.map((lot) => lot.id).toList(),
        producedByOperationId: operationId,
      ),
    ];
  }

  Future<void> _addLot() async {
    final lot = await showModalBottomSheet<MaterialLot>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddLotSheet(ingredients: _ingredients),
    );

    if (!mounted) return;
    if (lot == null) return;

    setState(() {
      _lots = [..._lots, lot];
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _addGuidedStep() async {
    if (_lots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Add ingredients, spices, or liquids before building a step.'),
        ),
      );
      return;
    }

    final draft = await showModalBottomSheet<GuidedStepResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GuidedStepSheet(
        actions: _actions,
        tools: _tools,
        lots: _lots,
        temperatures: _temperatures,
        times: _times,
        waterLevels: _waterLevels,
      ),
    );

    if (!mounted) return;
    if (draft == null) return;

    List<MaterialLot> currentInputLots = draft.inputLotIds
        .map((id) => _lots.firstWhere((lot) => lot.id == id))
        .toList();

    final appendedLots = <MaterialLot>[];
    final appendedOperations = <ProcedureOperation>[];

    void addStage({
      required String actionId,
      required ProcedureStation station,
      String? toolId,
      String? duration,
      String? temperature,
      String? waterLevel,
      String? notes,
      String? preferredOutputName,
    }) {
      final action = _findActionById(actionId);
      if (action == null) return;

      final opId = _uuid.v4();
      final tool = _findToolById(toolId);
      final fallbackState =
          currentInputLots.isNotEmpty ? currentInputLots.first.state : 'raw';
      final outputState = _getOutputState(actionId, fallbackState);
      final outputName = _suggestOutputName(
        currentInputLots,
        action['name'] as String? ?? 'Step',
        preferredName: preferredOutputName,
      );

      final outputLots = _createOutputLots(
        inputLots: currentInputLots,
        operationId: opId,
        outputState: outputState,
        outputName: outputName,
      );

      appendedLots.addAll(outputLots);
      appendedOperations.add(
        ProcedureOperation(
          id: opId,
          station: station,
          actionId: actionId,
          actionName: action['name'] as String? ?? '',
          actionEmoji: action['icon'] as String? ?? '*',
          toolId: tool?['id'] as String?,
          toolName: tool?['name'] as String?,
          toolIcon: tool?['icon'] as String?,
          temperature: temperature,
          duration: duration,
          waterLevel: waterLevel,
          notes: notes?.trim().isEmpty ?? true ? null : notes!.trim(),
          inputLotIds: currentInputLots.map((lot) => lot.id).toList(),
          outputLotIds: outputLots.map((lot) => lot.id).toList(),
        ),
      );

      currentInputLots = outputLots;
    }

    if (draft.prepActionId != null) {
      addStage(
        actionId: draft.prepActionId!,
        station: ProcedureStation.prep,
        toolId: draft.prepToolId,
        duration: draft.prepDuration,
        notes: draft.prepNotes,
        preferredOutputName:
            draft.cookActionId == null ? draft.resultName : null,
      );
    }

    if (draft.cookActionId != null) {
      addStage(
        actionId: draft.cookActionId!,
        station: ProcedureStation.cook,
        toolId: draft.cookToolId,
        duration: draft.cookDuration,
        temperature: draft.cookTemperature,
        waterLevel: draft.cookWaterLevel,
        notes: draft.cookNotes,
        preferredOutputName: draft.resultName,
      );
    }

    if (appendedOperations.isEmpty) return;

    setState(() {
      _lots = [..._lots, ...appendedLots];
      _operations = [..._operations, ...appendedOperations];
    });
    HapticFeedback.mediumImpact();
  }

  Future<void> _editLot(MaterialLot lot) async {
    final nameController = TextEditingController(text: lot.name);
    final emojiController = TextEditingController(text: lot.emoji);
    final amountController = TextEditingController(text: lot.amount);
    final unitController = TextEditingController(text: lot.unit);
    final stateController = TextEditingController(text: lot.state);

    final updated = await showDialog<MaterialLot>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Edit Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emojiController,
                  decoration: const InputDecoration(labelText: 'Emoji'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: amountController,
                        decoration: const InputDecoration(labelText: 'Amount'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: unitController,
                        decoration: const InputDecoration(labelText: 'Unit'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stateController,
                  decoration: const InputDecoration(labelText: 'State'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  lot.copyWith(
                    name: nameController.text.trim().isEmpty
                        ? lot.name
                        : nameController.text.trim(),
                    emoji: emojiController.text.trim().isEmpty
                        ? lot.emoji
                        : emojiController.text.trim(),
                    amount: amountController.text.trim().isEmpty
                        ? lot.amount
                        : amountController.text.trim(),
                    unit: unitController.text.trim().isEmpty
                        ? lot.unit
                        : unitController.text.trim(),
                    state: stateController.text.trim().isEmpty
                        ? lot.state
                        : stateController.text.trim(),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    emojiController.dispose();
    amountController.dispose();
    unitController.dispose();
    stateController.dispose();

    if (!mounted) return;
    if (updated == null) return;

    setState(() {
      _lots = _lots.map((l) => l.id == lot.id ? updated : l).toList();
    });
  }

  void _deleteLot(MaterialLot lot) {
    final isReferenced = _operations.any(
      (op) =>
          op.inputLotIds.contains(lot.id) || op.outputLotIds.contains(lot.id),
    );

    if (isReferenced) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This item is used in the procedure.')),
      );
      return;
    }

    setState(() {
      _lots = _lots.where((l) => l.id != lot.id).toList();
    });
  }

  Future<void> _addOperation() async {
    if (_lots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Add ingredients to your inventory first.')),
      );
      return;
    }

    final draft = await showModalBottomSheet<_OperationDraftResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddOperationSheet(
        actions: _actions,
        tools: _tools,
        lots: _lots,
        temperatures: _temperatures,
        times: _times,
        waterLevels: _waterLevels,
      ),
    );

    if (!mounted) return;
    if (draft == null) return;

    final opId = _uuid.v4();

    final inputLots = draft.inputLotIds
        .map((id) => _lots.firstWhere((l) => l.id == id))
        .toList();

    final fallbackState = inputLots.isNotEmpty ? inputLots.first.state : 'raw';
    final outputState = _getOutputState(draft.actionId, fallbackState);

    final outputLots = <MaterialLot>[];

    if (inputLots.length == 1) {
      final inLot = inputLots.first;
      final outLotId = _uuid.v4();
      outputLots.add(
        inLot.copyWith(
          id: outLotId,
          state: outputState,
          assetKey: _buildAssetKey(
            baseName: inLot.name,
            fallbackId: inLot.ingredientId,
            state: outputState,
          ),
          producedByOperationId: opId,
          derivedFromLotId: inLot.id,
        ),
      );
    } else {
      final outLotId = _uuid.v4();
      outputLots.add(
        MaterialLot(
          id: outLotId,
          ingredientId: 'mixture',
          name: 'Mix Base',
          emoji: 'mix',
          amount: '1',
          unit: 'batch',
          state: outputState,
          assetKey: _buildAssetKey(
            baseName: 'Mix Base',
            fallbackId: 'mixture',
            state: outputState,
          ),
          componentLotIds: draft.inputLotIds,
          producedByOperationId: opId,
        ),
      );
    }

    final op = ProcedureOperation(
      id: opId,
      station: draft.station,
      actionId: draft.actionId,
      actionName: draft.actionName,
      actionEmoji: draft.actionEmoji,
      toolId: draft.toolId,
      toolName: draft.toolName,
      toolIcon: draft.toolIcon,
      temperature: draft.temperature,
      duration: draft.duration,
      waterLevel: draft.waterLevel,
      notes: draft.notes,
      inputLotIds: draft.inputLotIds,
      outputLotIds: outputLots.map((l) => l.id).toList(),
    );

    setState(() {
      _lots = [..._lots, ...outputLots];
      _operations = [..._operations, op];
    });
    HapticFeedback.mediumImpact();
  }

  void _reorderOperations(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _operations.removeAt(oldIndex);
      _operations.insert(newIndex, item);
    });
  }

  void _deleteOperation(ProcedureOperation op) {
    final usedElsewhere = _operations.any(
      (o) => o.id != op.id && o.inputLotIds.any(op.outputLotIds.contains),
    );

    if (usedElsewhere) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete: outputs are used later.')),
      );
      return;
    }

    setState(() {
      _operations = _operations.where((o) => o.id != op.id).toList();
      _lots = _lots.where((l) => !op.outputLotIds.contains(l.id)).toList();
    });
  }

  Future<void> _previewAnimation() async {
    final kitchenData = _kitchenData;
    if (kitchenData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Kitchen data is still loading. Try again.')),
      );
      return;
    }

    if (_operations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add some operations first.')),
      );
      return;
    }

    final procedure = _buildProcedure();
    final animation = ProcedureCompiler.compileAnimation(
      id: widget.recipeId ?? 'preview',
      title: _titleController.text.trim().isEmpty
          ? 'Recipe Preview'
          : _titleController.text.trim(),
      description: _descController.text.trim(),
      procedure: procedure,
      kitchenData: kitchenData,
    );

    if (animation.steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No animation steps could be generated.')),
      );
      return;
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.6,
          maxChildSize: 0.98,
          builder: (context, scrollController) {
            return Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Iconsax.video_play,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Animation Preview',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Iconsax.close_circle),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: RecipeAnimationPlayer(
                      animation: animation,
                      autoPlay: true,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveRecipe() async {
    if (_isSaving) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please name your recipe')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final procedure = _buildProcedure();

      final now = DateTime.now();
      final base = _loadedRecipe;

      final recipe = (base != null)
          ? base.copyWith(
              title: title,
              description: _descController.text.trim().isNotEmpty
                  ? _descController.text.trim()
                  : null,
              steps: const [],
              procedure: procedure,
              updatedAt: now,
            )
          : RecipeModel(
              id: widget.recipeId ?? _uuid.v4(),
              title: title,
              description: _descController.text.trim().isNotEmpty
                  ? _descController.text.trim()
                  : null,
              authorId: user.id,
              authorName: user.displayName,
              authorAvatar: user.avatarEmoji,
              authorPhotoUrl: user.photoUrl,
              steps: const [],
              procedure: procedure,
              tags: const [],
              createdAt: now,
              updatedAt: now,
            );

      final provider = context.read<RecipeProvider>();
      final bool saveSucceeded;

      if (widget.recipeId != null) {
        saveSucceeded = await provider.updateRecipe(recipe);
      } else {
        final createdId = await provider.createRecipe(recipe);
        saveSucceeded = createdId != null;
      }

      if (!saveSucceeded) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? 'Unable to save recipe right now.',
            ),
          ),
        );
        return;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe saved!')),
      );
      context.pop();
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shadowColor = theme.shadowColor.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.35 : 0.10,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(
                  bottom:
                      BorderSide(color: scheme.outline.withValues(alpha: 0.12)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Semantics(
                        button: true,
                        label: 'Back',
                        child: Material(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () => context.pop(),
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(Iconsax.arrow_left,
                                  color: scheme.onSurface),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          style: Theme.of(context).textTheme.headlineSmall,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Name your recipe...',
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _previewAnimation,
                        icon: const Icon(Iconsax.video_play),
                        color: scheme.onSurfaceVariant,
                      ),
                      IconButton(
                        onPressed: _isSaving ? null : _saveRecipe,
                        icon: _isSaving
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: scheme.primary,
                                ),
                              )
                            : const Icon(Iconsax.tick_circle),
                        color: scheme.primary,
                      ),
                    ],
                  ),
                  TextField(
                    controller: _descController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Description (optional)',
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _InventorySection(
                    lots: _lots,
                    onAdd: _addLot,
                    onEdit: _editLot,
                    onDelete: _deleteLot,
                  ),
                  const SizedBox(height: 16),
                  _ProcedureSection(
                    lots: _lots,
                    operations: _operations,
                    onReorder: _reorderOperations,
                    onDelete: _deleteOperation,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: scheme.outline.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Build animation-ready steps',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Choose the ingredients, apply prep actions, then add the cooking method, temperature, and timing.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GradientButton(
                          text: 'Guided Step Builder',
                          icon: Icons.auto_awesome,
                          onPressed: _addGuidedStep,
                        ),
                        const SizedBox(height: 10),
                        CustomButton(
                          text: 'Advanced Operation Editor',
                          icon: Icons.tune,
                          onPressed: _addOperation,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventorySection extends StatelessWidget {
  final List<MaterialLot> lots;
  final VoidCallback onAdd;
  final Future<void> Function(MaterialLot) onEdit;
  final void Function(MaterialLot) onDelete;

  const _InventorySection({
    required this.lots,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shadowColor = theme.shadowColor.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.35 : 0.10,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.box, color: scheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Selected Ingredients',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${lots.length} items',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (lots.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Start with the ingredients, spices, sauces, and liquids you want to animate.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            )
          else
            ...lots.map((lot) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: scheme.outline.withValues(alpha: 0.10)),
                ),
                child: Row(
                  children: [
                    Text(lot.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lot.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${lot.amount} ${lot.unit} 闂?${lot.state}',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => onEdit(lot),
                      icon: const Icon(Iconsax.edit_2, size: 18),
                      color: scheme.onSurfaceVariant,
                    ),
                    IconButton(
                      onPressed: () => onDelete(lot),
                      icon: const Icon(Iconsax.trash, size: 18),
                      color: scheme.error,
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 8),
          GradientButton(
            text: 'Add Ingredient or Spice',
            icon: Iconsax.add_circle,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _ProcedureSection extends StatelessWidget {
  final List<MaterialLot> lots;
  final List<ProcedureOperation> operations;
  final void Function(int, int) onReorder;
  final void Function(ProcedureOperation) onDelete;

  const _ProcedureSection({
    required this.lots,
    required this.operations,
    required this.onReorder,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shadowColor = theme.shadowColor.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.35 : 0.10,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.task, color: scheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Animation Timeline',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${operations.length} ops',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (operations.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Build your recipe one guided step at a time. Each step becomes one animation beat.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: onReorder,
              itemCount: operations.length,
              itemBuilder: (context, index) {
                final op = operations[index];
                return Container(
                  key: ValueKey(op.id),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: scheme.outline.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: scheme.onPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(op.actionEmoji,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  op.toolName != null && op.toolName!.isNotEmpty
                                      ? '${op.actionName} with ${op.toolName}'
                                      : op.actionName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${op.station.name.toUpperCase()}${op.duration != null ? ' 闂?${op.duration}' : ''}',
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => onDelete(op),
                            icon: const Icon(Iconsax.trash, size: 18),
                            color: scheme.error,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: op.inputLotIds
                            .map((lotId) =>
                                lots.where((l) => l.id == lotId).toList())
                            .expand((x) => x)
                            .map((lot) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      scheme.outline.withValues(alpha: 0.18)),
                            ),
                            child: Text(
                              '${lot.emoji} ${lot.name}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (op.notes != null && op.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          op.notes!.trim(),
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _AddLotSheet extends StatefulWidget {
  final List<Map<String, dynamic>> ingredients;

  const _AddLotSheet({required this.ingredients});

  @override
  State<_AddLotSheet> createState() => _AddLotSheetState();
}

class _AddLotSheetState extends State<_AddLotSheet> {
  final _searchController = TextEditingController();
  final _amountController = TextEditingController(text: '1');
  final _unitController = TextEditingController();
  final _stateController = TextEditingController(text: 'raw');

  Map<String, dynamic>? _selected;

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    _unitController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shadowColor = theme.shadowColor.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.35 : 0.10,
    );

    final query = _searchController.text.trim().toLowerCase();

    final filtered = widget.ingredients.where((ing) {
      if (query.isEmpty) return true;
      final name = (ing['name'] as String? ?? '').toLowerCase();
      return name.contains(query);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.98,
      builder: (context, scrollController) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Add Ingredient or Spice',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Iconsax.close_circle),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search ingredients, sauces, or seasonings...',
                  prefixIcon: const Icon(Iconsax.search_normal),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final ing = filtered[index];
                    final isSelected = _selected?['id'] == ing['id'];
                    return ListTile(
                      leading: Text(
                        ing['emoji'] as String? ?? 'ing',
                        style: const TextStyle(fontSize: 20),
                      ),
                      title: Text(ing['name'] as String? ?? ''),
                      trailing: isSelected
                          ? Icon(Iconsax.tick_circle, color: scheme.primary)
                          : null,
                      onTap: () {
                        setState(() {
                          _selected = ing;
                          _unitController.text =
                              (ing['defaultUnit'] as String?) ??
                              (ing['unit'] as String?) ?? 'pcs';
                        });
                        HapticFeedback.selectionClick();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: scheme.outline.withValues(alpha: 0.10),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              filled: true,
                              fillColor: scheme.surface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _unitController,
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              filled: true,
                              fillColor: scheme.surface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _stateController,
                      decoration: InputDecoration(
                        labelText: 'State',
                        filled: true,
                        fillColor: scheme.surface,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GradientButton(
                      text: 'Add to Inventory',
                      icon: Iconsax.add_circle,
                      onPressed: _selected == null
                          ? null
                          : () {
                              final ing = _selected!;
                              Navigator.pop(
                                context,
                                MaterialLot(
                                  id: const Uuid().v4(),
                                  ingredientId: ing['id'] as String? ?? '',
                                  name: ing['name'] as String? ?? '',
                                  emoji: ing['emoji'] as String? ?? 'ing',
                                  amount: _amountController.text.trim().isEmpty
                                      ? '1'
                                      : _amountController.text.trim(),
                                  unit: _unitController.text.trim().isEmpty
                                      ? 'pcs'
                                      : _unitController.text.trim(),
                                  state: _stateController.text.trim().isEmpty
                                      ? 'raw'
                                      : _stateController.text.trim(),
                                  assetKey: (ing['id'] as String? ?? 'ingredient') + '_' +
                                      (_stateController.text.trim().isEmpty
                                          ? 'raw'
                                          : _stateController.text.trim()),
                                ),
                              );
                            },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OperationDraftResult {
  final ProcedureStation station;
  final String actionId;
  final String actionName;
  final String actionEmoji;
  final String? toolId;
  final String? toolName;
  final String? toolIcon;
  final List<String> inputLotIds;
  final String? temperature;
  final String? duration;
  final String? waterLevel;
  final String? notes;

  const _OperationDraftResult({
    required this.station,
    required this.actionId,
    required this.actionName,
    required this.actionEmoji,
    required this.toolId,
    required this.toolName,
    required this.toolIcon,
    required this.inputLotIds,
    required this.temperature,
    required this.duration,
    required this.waterLevel,
    required this.notes,
  });
}

class _AddOperationSheet extends StatefulWidget {
  final List<Map<String, dynamic>> actions;
  final List<Map<String, dynamic>> tools;
  final List<MaterialLot> lots;
  final List<String> temperatures;
  final List<String> times;
  final List<String> waterLevels;

  const _AddOperationSheet({
    required this.actions,
    required this.tools,
    required this.lots,
    required this.temperatures,
    required this.times,
    required this.waterLevels,
  });

  @override
  State<_AddOperationSheet> createState() => _AddOperationSheetState();
}

class _AddOperationSheetState extends State<_AddOperationSheet> {
  ProcedureStation _station = ProcedureStation.prep;
  Map<String, dynamic>? _selectedAction;
  Map<String, dynamic>? _selectedTool;
  final Set<String> _selectedInputLotIds = {};

  String? _temperature;
  String? _duration;
  String? _waterLevel;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final requiresHeat = _selectedAction?['requiresHeat'] == true;
    final requiredToolId = _selectedAction?['requiresToolId'] as String?;

    if (requiredToolId != null) {
      _selectedTool ??= widget.tools.firstWhere(
        (t) => t['id'] == requiredToolId,
        orElse: () => widget.tools.first,
      );
    }

    final isValid = _selectedAction != null && _selectedInputLotIds.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.98,
      builder: (context, scrollController) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Add Operation',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Iconsax.close_circle),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    const Text(
                      'Station',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: ProcedureStation.values.map((station) {
                        final isSelected = _station == station;
                        return ChoiceChip(
                          label: Text(station.name.toUpperCase()),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _station = station);
                            HapticFeedback.selectionClick();
                          },
                          selectedColor: scheme.primary.withValues(alpha: 0.18),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Inputs',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: widget.lots.map((lot) {
                        final isSelected =
                            _selectedInputLotIds.contains(lot.id);
                        return FilterChip(
                          label: Text('${lot.emoji} ${lot.name}'),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedInputLotIds.add(lot.id);
                              } else {
                                _selectedInputLotIds.remove(lot.id);
                              }
                            });
                            HapticFeedback.selectionClick();
                          },
                          selectedColor:
                              scheme.secondary.withValues(alpha: 0.18),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Action',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: widget.actions.length,
                      itemBuilder: (context, index) {
                        final action = widget.actions[index];
                        final isSelected =
                            _selectedAction?['id'] == action['id'];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedAction = action;
                                _selectedTool = null;
                                _temperature = null;
                              });
                              HapticFeedback.selectionClick();
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Ink(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? scheme.primary.withValues(alpha: 0.12)
                                    : scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? scheme.primary
                                      : scheme.outline.withValues(alpha: 0.18),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    action['icon'] as String? ?? '*',
                                    style: const TextStyle(fontSize: 26),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    action['name'] as String? ?? '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Tool',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: widget.tools.where((tool) {
                        if (requiredToolId == null) return true;
                        return tool['id'] == requiredToolId;
                      }).map((tool) {
                        final isSelected = _selectedTool?['id'] == tool['id'];
                        return ChoiceChip(
                          label: Text(
                              '${tool['icon'] ?? 'tool'} ${tool['name'] ?? ''}'),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _selectedTool = tool);
                            HapticFeedback.selectionClick();
                          },
                          selectedColor:
                              scheme.tertiary.withValues(alpha: 0.18),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    if (requiresHeat) ...[
                      const Text(
                        'Temperature',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: widget.temperatures.map((t) {
                          final isSelected = _temperature == t;
                          return ChoiceChip(
                            label: Text(t),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() => _temperature = t);
                              HapticFeedback.selectionClick();
                            },
                            selectedColor: scheme.error.withValues(alpha: 0.16),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                    ],
                    const Text(
                      'Duration',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: widget.times.map((t) {
                        final isSelected = _duration == t;
                        return ChoiceChip(
                          label: Text(t),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _duration = t);
                            HapticFeedback.selectionClick();
                          },
                          selectedColor:
                              scheme.tertiary.withValues(alpha: 0.16),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Water',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: widget.waterLevels.map((w) {
                        final isSelected = _waterLevel == w;
                        return ChoiceChip(
                          label: Text(w),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _waterLevel = w);
                            HapticFeedback.selectionClick();
                          },
                          selectedColor:
                              scheme.secondary.withValues(alpha: 0.16),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Notes',
                        filled: true,
                        fillColor: scheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GradientButton(
                      text: 'Add Operation',
                      icon: Iconsax.add,
                      onPressed: !isValid
                          ? null
                          : () {
                              final action = _selectedAction!;
                              final tool = _selectedTool;
                              Navigator.pop(
                                context,
                                _OperationDraftResult(
                                  station: _station,
                                  actionId: action['id'] as String,
                                  actionName:
                                      action['name'] as String? ?? 'Action',
                                  actionEmoji:
                                      action['icon'] as String? ?? '*',
                                  toolId: tool?['id'] as String?,
                                  toolName: tool?['name'] as String?,
                                  toolIcon: tool?['icon'] as String?,
                                  inputLotIds: _selectedInputLotIds.toList(),
                                  temperature: _temperature,
                                  duration: _duration,
                                  waterLevel: _waterLevel,
                                  notes: _notesController.text.trim().isEmpty
                                      ? null
                                      : _notesController.text.trim(),
                                ),
                              );
                            },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


