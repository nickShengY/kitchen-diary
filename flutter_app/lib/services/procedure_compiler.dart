import 'package:uuid/uuid.dart';

import '../data/kitchen_data_repository.dart';
import '../models/animation_model.dart';
import '../models/procedure_model.dart';
import '../models/recipe_model.dart';

class ProcedureCompiler {
  static const _uuid = Uuid();

  static List<CookingStep> compileCookingSteps(RecipeProcedure procedure) {
    final lotsById = <String, MaterialLot>{
      for (final l in procedure.lots) l.id: l,
    };

    return procedure.operations.asMap().entries.map((entry) {
      final index = entry.key;
      final op = entry.value;

      final ingredients = op.inputLotIds
          .map((lotId) => lotsById[lotId])
          .whereType<MaterialLot>()
          .map(
            (lot) => RecipeIngredient(
              ingredientId: lot.ingredientId,
              name: lot.name,
              emoji: lot.emoji,
              amount: lot.amount,
              unit: lot.unit,
            ),
          )
          .toList();

      return CookingStep(
        id: op.id,
        stepNumber: index + 1,
        station: StationCategory.values.firstWhere(
          (s) => s.name == op.station.name,
          orElse: () => StationCategory.prep,
        ),
        ingredients: ingredients,
        toolId: op.toolId ?? '',
        toolName: op.toolName ?? '',
        toolIcon: op.toolIcon ?? '',
        actionId: op.actionId,
        actionName: op.actionName,
        actionEmoji: op.actionEmoji,
        temperature: op.temperature,
        duration: op.duration,
        waterLevel: op.waterLevel,
        notes: op.notes,
      );
    }).toList();
  }

  static RecipeAnimation compileAnimation({
    required String id,
    required String title,
    required String description,
    required RecipeProcedure procedure,
    required KitchenDataRepository kitchenData,
  }) {
    final raw = kitchenData.rawData;

    final transformationsRaw =
        raw['actionTransformations'] as Map<String, dynamic>? ?? const {};
    final animationTypesRaw =
        raw['animationTypes'] as Map<String, dynamic>? ?? const {};

    final transformations = <String, ActionTransformation>{
      for (final entry in transformationsRaw.entries)
        entry.key: ActionTransformation.fromJson(
          entry.key,
          Map<String, dynamic>.from(entry.value as Map),
        ),
    };

    final animationTypes = <String, AnimationType>{
      for (final entry in animationTypesRaw.entries)
        entry.key: AnimationType.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        ),
    };

    final builder = RecipeAnimationBuilder(
      id: id,
      title: title,
      description: description,
    );

    for (final lot in procedure.lots) {
      builder.addIngredient(
        lot.id,
        lot.name,
        lot.emoji,
        initialState: lot.state,
        assetKey: lot.assetKey,
      );
    }

    final lotsById = <String, MaterialLot>{
      for (final l in procedure.lots) l.id: l,
    };

    for (final op in procedure.operations) {
      final inputLots = op.inputLotIds
          .map((id) => lotsById[id])
          .whereType<MaterialLot>()
          .toList();

      final ingredientIds = inputLots.map((l) => l.id).toSet().toList();
      final ingredientNames = inputLots.map((l) => l.name).toList();

      final fromState = inputLots.isNotEmpty ? inputLots.first.state : 'raw';

      final transform = transformations[op.actionId];
      final derivedOutputState = op.outputLotIds.isNotEmpty
          ? lotsById[op.outputLotIds.first]?.state
          : null;
      final toState = transform?.outputState ?? derivedOutputState ?? fromState;
      final animType =
          transform != null ? animationTypes[transform.animationType] : null;

      builder.addStep(
        actionId: op.actionId,
        ingredientIds: ingredientIds,
        ingredientNames: ingredientNames,
        toolId: op.toolId,
        fromState: fromState,
        toState: toState,
        animationType: animType,
        duration:
            animType?.animationDuration ?? const Duration(milliseconds: 800),
      );
    }

    return builder.build();
  }

  static RecipeProcedure migrateFromCookingSteps({
    required List<CookingStep> steps,
    required KitchenDataRepository kitchenData,
  }) {
    final raw = kitchenData.rawData;
    final transformationsRaw =
        raw['actionTransformations'] as Map<String, dynamic>? ?? const {};

    final transformations = <String, ActionTransformation>{
      for (final entry in transformationsRaw.entries)
        entry.key: ActionTransformation.fromJson(
          entry.key,
          Map<String, dynamic>.from(entry.value as Map),
        ),
    };

    final baseLotsByIngredientId = <String, MaterialLot>{};
    final currentLotIdByIngredientId = <String, String>{};

    for (final step in steps) {
      for (final ing in step.ingredients) {
        if (baseLotsByIngredientId.containsKey(ing.ingredientId)) continue;
        final id = _uuid.v4();
        final lot = MaterialLot(
          id: id,
          ingredientId: ing.ingredientId,
          name: ing.name,
          emoji: ing.emoji,
          amount: ing.amount,
          unit: ing.unit,
          state: 'raw',
          assetKey: ing.ingredientId + '_raw',
        );
        baseLotsByIngredientId[ing.ingredientId] = lot;
        currentLotIdByIngredientId[ing.ingredientId] = id;
      }
    }

    final lots = <MaterialLot>[...baseLotsByIngredientId.values];
    final operations = <ProcedureOperation>[];

    for (final step in steps) {
      final opId = step.id;

      final inputLotIds = step.ingredients.map((ing) {
        final existing = currentLotIdByIngredientId[ing.ingredientId];
        if (existing != null) return existing;

        final id = _uuid.v4();
        final lot = MaterialLot(
          id: id,
          ingredientId: ing.ingredientId,
          name: ing.name,
          emoji: ing.emoji,
          amount: ing.amount,
          unit: ing.unit,
          state: 'raw',
          assetKey: ing.ingredientId + '_raw',
        );
        lots.add(lot);
        currentLotIdByIngredientId[ing.ingredientId] = id;
        return id;
      }).toList();

      final station = ProcedureStation.values.firstWhere(
        (s) => s.name == step.station.name,
        orElse: () => ProcedureStation.prep,
      );

      final transform = transformations[step.actionId];
      final outputState = transform?.outputState;

      final outputLotIds = <String>[];
      for (final ing in step.ingredients) {
        final priorLotId = currentLotIdByIngredientId[ing.ingredientId];

        final id = _uuid.v4();
        final lot = MaterialLot(
          id: id,
          ingredientId: ing.ingredientId,
          name: ing.name,
          emoji: ing.emoji,
          amount: ing.amount,
          unit: ing.unit,
          state: outputState ?? 'raw',
          assetKey: ing.ingredientId + '_' + (outputState ?? 'raw'),
          producedByOperationId: opId,
          derivedFromLotId: priorLotId,
        );
        lots.add(lot);
        currentLotIdByIngredientId[ing.ingredientId] = id;
        outputLotIds.add(id);
      }

      operations.add(
        ProcedureOperation(
          id: opId,
          station: station,
          actionId: step.actionId,
          actionName: step.actionName,
          actionEmoji: step.actionEmoji,
          toolId: step.toolId,
          toolName: step.toolName,
          toolIcon: step.toolIcon,
          temperature: step.temperature,
          duration: step.duration,
          waterLevel: step.waterLevel,
          notes: step.notes,
          inputLotIds: inputLotIds,
          outputLotIds: outputLotIds,
        ),
      );
    }

    return RecipeProcedure(
      version: '1.0.0',
      lots: lots,
      operations: operations,
    );
  }
}
