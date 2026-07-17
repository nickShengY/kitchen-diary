import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/procedure_model.dart';
import '../../widgets/common/custom_button.dart';

class GuidedStepResult {
  final List<String> inputLotIds;
  final String? prepActionId;
  final String? prepToolId;
  final String? prepDuration;
  final String? prepNotes;
  final String? cookActionId;
  final String? cookToolId;
  final String? cookTemperature;
  final String? cookDuration;
  final String? cookWaterLevel;
  final String? cookNotes;
  final String? resultName;

  const GuidedStepResult({
    required this.inputLotIds,
    required this.prepActionId,
    required this.prepToolId,
    required this.prepDuration,
    required this.prepNotes,
    required this.cookActionId,
    required this.cookToolId,
    required this.cookTemperature,
    required this.cookDuration,
    required this.cookWaterLevel,
    required this.cookNotes,
    required this.resultName,
  });
}

class GuidedStepSheet extends StatefulWidget {
  final List<Map<String, dynamic>> actions;
  final List<Map<String, dynamic>> tools;
  final List<MaterialLot> lots;
  final List<String> temperatures;
  final List<String> times;
  final List<String> waterLevels;

  const GuidedStepSheet({
    super.key,
    required this.actions,
    required this.tools,
    required this.lots,
    required this.temperatures,
    required this.times,
    required this.waterLevels,
  });

  @override
  State<GuidedStepSheet> createState() => _GuidedStepSheetState();
}

class _GuidedStepSheetState extends State<GuidedStepSheet> {
  static const _finishActionIds = {
    'plate',
    'garnish',
    'drizzle',
    'sprinkle',
  };

  final Set<String> _selectedInputLotIds = <String>{};
  final TextEditingController _resultNameController = TextEditingController();
  final TextEditingController _prepNotesController = TextEditingController();
  final TextEditingController _cookNotesController = TextEditingController();

  Map<String, dynamic>? _selectedPrepAction;
  Map<String, dynamic>? _selectedPrepTool;
  String? _prepDuration;

  bool _includeCookStage = true;
  Map<String, dynamic>? _selectedCookAction;
  Map<String, dynamic>? _selectedCookTool;
  String? _cookTemperature;
  String? _cookDuration;
  String? _cookWaterLevel;

  @override
  void dispose() {
    _resultNameController.dispose();
    _prepNotesController.dispose();
    _cookNotesController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _prepActions => widget.actions.where((action) {
        final requiresHeat = action['requiresHeat'] == true;
        final id = action['id'] as String? ?? '';
        return !requiresHeat && !_finishActionIds.contains(id);
      }).toList();

  List<Map<String, dynamic>> get _cookActions => widget.actions.where((action) {
        return action['requiresHeat'] == true;
      }).toList();

  List<Map<String, dynamic>> _toolOptionsForAction(
      Map<String, dynamic>? action) {
    final requiredToolId = action?['requiresToolId'] as String?;
    if (requiredToolId == null || requiredToolId.isEmpty) {
      return widget.tools;
    }
    return widget.tools.where((tool) => tool['id'] == requiredToolId).toList();
  }

  void _selectPrepAction(Map<String, dynamic> action) {
    setState(() {
      _selectedPrepAction = action;
      final toolOptions = _toolOptionsForAction(action);
      _selectedPrepTool = toolOptions.isNotEmpty ? toolOptions.first : null;
    });
    HapticFeedback.selectionClick();
  }

  void _selectCookAction(Map<String, dynamic> action) {
    setState(() {
      _selectedCookAction = action;
      final toolOptions = _toolOptionsForAction(action);
      _selectedCookTool = toolOptions.isNotEmpty ? toolOptions.first : null;
      _cookTemperature = null;
      _cookWaterLevel = null;
    });
    HapticFeedback.selectionClick();
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceWrap({
    required List<String> values,
    required String? selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        return ChoiceChip(
          label: Text(value),
          selected: selectedValue == value,
          onSelected: (_) => onSelected(value),
        );
      }).toList(),
    );
  }

  Widget _buildActionGrid({
    required List<Map<String, dynamic>> actions,
    required Map<String, dynamic>? selectedAction,
    required ValueChanged<Map<String, dynamic>> onTap,
  }) {
    if (actions.isEmpty) {
      return const Text('No actions available for this step yet.');
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.35,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        final isSelected = selectedAction?['id'] == action['id'];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap(action),
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.10)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.12),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    action['icon'] as String? ?? '*',
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action['name'] as String? ?? 'Action',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasPrep = _selectedPrepAction != null;
    final hasCook = _includeCookStage && _selectedCookAction != null;
    final requiresNamedOutput = _selectedInputLotIds.length > 1;
    final hasNamedOutput = _resultNameController.text.trim().isNotEmpty;
    final isValid = _selectedInputLotIds.isNotEmpty &&
        (hasPrep || hasCook) &&
        (!requiresNamedOutput || hasNamedOutput);

    return DraggableScrollableSheet(
      initialChildSize: 0.94,
      minChildSize: 0.65,
      maxChildSize: 0.98,
      builder: (context, scrollController) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Guided Animation Step',
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
              const SizedBox(height: 4),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildSectionTitle(
                      '1. Choose ingredients',
                      'Select the lots that will be transformed in this step.',
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.lots.map((lot) {
                        final isSelected =
                            _selectedInputLotIds.contains(lot.id);
                        return FilterChip(
                          label:
                              Text('${lot.emoji} ${lot.name} (${lot.state})'),
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
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle(
                      '2. Prep the ingredients',
                      'Optional but recommended. Pick how the ingredients are processed before cooking.',
                    ),
                    _buildActionGrid(
                      actions: _prepActions,
                      selectedAction: _selectedPrepAction,
                      onTap: _selectPrepAction,
                    ),
                    if (_selectedPrepAction != null) ...[
                      const SizedBox(height: 14),
                      _buildSectionTitle(
                        'Prep tool and time',
                        'These choices help the animation compiler understand the processing stage.',
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _toolOptionsForAction(_selectedPrepAction)
                            .map((tool) {
                          return ChoiceChip(
                            label: Text(
                                '${tool['icon'] ?? ''} ${tool['name'] ?? ''}'),
                            selected: _selectedPrepTool?['id'] == tool['id'],
                            onSelected: (_) {
                              setState(() => _selectedPrepTool = tool);
                              HapticFeedback.selectionClick();
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      _buildChoiceWrap(
                        values: widget.times,
                        selectedValue: _prepDuration,
                        onSelected: (value) {
                          setState(() => _prepDuration = value);
                          HapticFeedback.selectionClick();
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _prepNotesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Prep notes',
                          filled: true,
                          fillColor: scheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SwitchListTile.adaptive(
                      value: _includeCookStage,
                      onChanged: (value) {
                        setState(() {
                          _includeCookStage = value;
                          if (!value) {
                            _selectedCookAction = null;
                            _selectedCookTool = null;
                            _cookTemperature = null;
                            _cookDuration = null;
                            _cookWaterLevel = null;
                          }
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        '3. Add a cooking stage',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text(
                        'Turn the prepared ingredients into a pan, pot, oven, or grill animation step.',
                      ),
                    ),
                    if (_includeCookStage) ...[
                      const SizedBox(height: 8),
                      _buildActionGrid(
                        actions: _cookActions,
                        selectedAction: _selectedCookAction,
                        onTap: _selectCookAction,
                      ),
                      if (_selectedCookAction != null) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _toolOptionsForAction(_selectedCookAction)
                              .map((tool) {
                            return ChoiceChip(
                              label: Text(
                                  '${tool['icon'] ?? ''} ${tool['name'] ?? ''}'),
                              selected: _selectedCookTool?['id'] == tool['id'],
                              onSelected: (_) {
                                setState(() => _selectedCookTool = tool);
                                HapticFeedback.selectionClick();
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        _buildSectionTitle(
                          'Heat, timing, and liquid',
                          'Use these controls to make the animation readable and instructive.',
                        ),
                        _buildChoiceWrap(
                          values: widget.temperatures,
                          selectedValue: _cookTemperature,
                          onSelected: (value) {
                            setState(() => _cookTemperature = value);
                            HapticFeedback.selectionClick();
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildChoiceWrap(
                          values: widget.times,
                          selectedValue: _cookDuration,
                          onSelected: (value) {
                            setState(() => _cookDuration = value);
                            HapticFeedback.selectionClick();
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildChoiceWrap(
                          values: widget.waterLevels,
                          selectedValue: _cookWaterLevel,
                          onSelected: (value) {
                            setState(() => _cookWaterLevel = value);
                            HapticFeedback.selectionClick();
                          },
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _cookNotesController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Cook notes',
                            filled: true,
                            fillColor: scheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 20),
                    _buildSectionTitle(
                      '4. Name the output',
                      'Optional. This is most helpful when several inputs become one new mixture or dish.',
                    ),
                    TextField(
                      controller: _resultNameController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText:
                            'Example: Aromatic curry base or seared mushroom filling',
                        helperText: requiresNamedOutput
                            ? 'Name the combined result so animation assets and recipe playback stay readable.'
                            : 'Optional for single-ingredient steps.',
                        filled: true,
                        fillColor: scheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GradientButton(
                      text: 'Build Animation Step',
                      icon: Iconsax.magic_star,
                      onPressed: !isValid
                          ? null
                          : () {
                              Navigator.pop(
                                context,
                                GuidedStepResult(
                                  inputLotIds: _selectedInputLotIds.toList(),
                                  prepActionId:
                                      _selectedPrepAction?['id'] as String?,
                                  prepToolId:
                                      _selectedPrepTool?['id'] as String?,
                                  prepDuration: _prepDuration,
                                  prepNotes:
                                      _prepNotesController.text.trim().isEmpty
                                          ? null
                                          : _prepNotesController.text.trim(),
                                  cookActionId:
                                      _selectedCookAction?['id'] as String?,
                                  cookToolId:
                                      _selectedCookTool?['id'] as String?,
                                  cookTemperature: _cookTemperature,
                                  cookDuration: _cookDuration,
                                  cookWaterLevel: _cookWaterLevel,
                                  cookNotes:
                                      _cookNotesController.text.trim().isEmpty
                                          ? null
                                          : _cookNotesController.text.trim(),
                                  resultName:
                                      _resultNameController.text.trim().isEmpty
                                          ? null
                                          : _resultNameController.text.trim(),
                                ),
                              );
                            },
                    ),
                    const SizedBox(height: 24),
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
