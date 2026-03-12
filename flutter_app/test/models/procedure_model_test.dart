import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_diary/models/procedure_model.dart';

void main() {
  group('ProcedureStation', () {
    test('has correct values', () {
      expect(ProcedureStation.values.length, 3);
      expect(ProcedureStation.prep.name, 'prep');
      expect(ProcedureStation.cook.name, 'cook');
      expect(ProcedureStation.finish.name, 'finish');
    });
  });

  group('MaterialLot', () {
    test('creation with required fields', () {
      const lot = MaterialLot(
        id: 'lot-1',
        ingredientId: 'tomato',
        name: 'Tomato',
        emoji: '馃崊',
        amount: '2',
        unit: 'pcs',
        state: 'raw', assetKey: 'tomato_raw',
      );
      expect(lot.id, 'lot-1');
      expect(lot.ingredientId, 'tomato');
      expect(lot.name, 'Tomato');
      expect(lot.emoji, '馃崊');
      expect(lot.amount, '2');
      expect(lot.unit, 'pcs');
      expect(lot.state, 'raw');
      expect(lot.componentLotIds, isNull);
      expect(lot.containerId, isNull);
      expect(lot.producedByOperationId, isNull);
      expect(lot.derivedFromLotId, isNull);
      expect(lot.notes, isNull);
    });

    test('creation with all fields', () {
      const lot = MaterialLot(
        id: 'lot-2',
        ingredientId: 'sauce',
        name: 'Tomato Sauce',
        emoji: '馃カ',
        amount: '500',
        unit: 'ml',
        state: 'cooked', assetKey: 'sauce_cooked',
        componentLotIds: ['lot-1', 'lot-3'],
        containerId: 'pot-1',
        producedByOperationId: 'op-2',
        derivedFromLotId: 'lot-1',
        notes: 'Simmered for 30 min',
      );
      expect(lot.componentLotIds, ['lot-1', 'lot-3']);
      expect(lot.containerId, 'pot-1');
      expect(lot.producedByOperationId, 'op-2');
      expect(lot.derivedFromLotId, 'lot-1');
      expect(lot.notes, 'Simmered for 30 min');
    });

    test('copyWith preserves unchanged values', () {
      const original = MaterialLot(
        id: 'lot-1', ingredientId: 'egg', name: 'Egg',
        emoji: '馃', amount: '3', unit: 'pcs', state: 'raw', assetKey: 'egg_raw',
      );
      final updated = original.copyWith(state: 'boiled');
      expect(updated.id, 'lot-1');
      expect(updated.name, 'Egg');
      expect(updated.state, 'boiled');
    });

    test('toJson produces correct map', () {
      const lot = MaterialLot(
        id: 'lot-1', ingredientId: 'flour', name: 'Flour',
        emoji: '馃尵', amount: '200', unit: 'g', state: 'dry', assetKey: 'flour_dry',
        notes: 'All purpose',
      );
      final json = lot.toJson();
      expect(json['id'], 'lot-1');
      expect(json['ingredientId'], 'flour');
      expect(json['state'], 'dry');
      expect(json['notes'], 'All purpose');
      expect(json['componentLotIds'], isNull);
    });

    test('fromJson creates correct object', () {
      final json = {
        'id': 'lot-3',
        'ingredientId': 'butter',
        'name': 'Butter',
        'emoji': '馃',
        'amount': '100',
        'unit': 'g',
        'state': 'melted',
        'componentLotIds': ['lot-a'],
      };
      final lot = MaterialLot.fromJson(json);
      expect(lot.id, 'lot-3');
      expect(lot.state, 'melted');
      expect(lot.componentLotIds, ['lot-a']);
    });

    test('fromJson with missing fields uses defaults', () {
      final json = <String, dynamic>{};
      final lot = MaterialLot.fromJson(json);
      expect(lot.id, '');
      expect(lot.ingredientId, '');
      expect(lot.name, '');
      expect(lot.emoji, '');
      expect(lot.amount, '1');
      expect(lot.unit, 'pcs');
      expect(lot.state, 'raw');
    });

    test('toJson/fromJson roundtrip', () {
      const original = MaterialLot(
        id: 'rt-1', ingredientId: 'chicken', name: 'Chicken Breast',
        emoji: '馃崡', amount: '500', unit: 'g', state: 'raw', assetKey: 'chicken_raw',
        containerId: 'pan-1', notes: 'Boneless',
      );
      final restored = MaterialLot.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.ingredientId, original.ingredientId);
      expect(restored.name, original.name);
      expect(restored.state, original.state);
      expect(restored.containerId, original.containerId);
      expect(restored.notes, original.notes);
    });
  });

  group('ProcedureOperation', () {
    test('creation with required fields', () {
      const op = ProcedureOperation(
        id: 'op-1',
        station: ProcedureStation.prep,
        actionId: 'chop',
        actionName: 'Chop',
        actionEmoji: '馃敧',
        inputLotIds: ['lot-1'],
        outputLotIds: ['lot-2'],
      );
      expect(op.id, 'op-1');
      expect(op.station, ProcedureStation.prep);
      expect(op.actionId, 'chop');
      expect(op.toolId, isNull);
      expect(op.toolName, isNull);
      expect(op.toolIcon, isNull);
      expect(op.temperature, isNull);
      expect(op.duration, isNull);
      expect(op.waterLevel, isNull);
      expect(op.notes, isNull);
      expect(op.inputLotIds, ['lot-1']);
      expect(op.outputLotIds, ['lot-2']);
    });

    test('creation with all fields', () {
      const op = ProcedureOperation(
        id: 'op-2',
        station: ProcedureStation.cook,
        actionId: 'fry',
        actionName: 'Fry',
        actionEmoji: '馃嵆',
        toolId: 'pan',
        toolName: 'Frying Pan',
        toolIcon: '馃嵆',
        temperature: 'Medium-High',
        duration: '10 mins',
        waterLevel: null,
        notes: 'Until golden brown',
        inputLotIds: ['lot-2', 'lot-3'],
        outputLotIds: ['lot-4'],
      );
      expect(op.toolId, 'pan');
      expect(op.temperature, 'Medium-High');
      expect(op.duration, '10 mins');
      expect(op.notes, 'Until golden brown');
    });

    test('copyWith', () {
      const original = ProcedureOperation(
        id: 'op-1', station: ProcedureStation.prep,
        actionId: 'chop', actionName: 'Chop', actionEmoji: '馃敧',
        inputLotIds: ['l1'], outputLotIds: ['l2'],
      );
      final updated = original.copyWith(
        station: ProcedureStation.cook,
        temperature: 'High',
      );
      expect(updated.station, ProcedureStation.cook);
      expect(updated.temperature, 'High');
      expect(updated.actionId, 'chop');
    });

    test('toJson/fromJson roundtrip', () {
      const original = ProcedureOperation(
        id: 'op-rt', station: ProcedureStation.finish,
        actionId: 'plate', actionName: 'Plate', actionEmoji: '*',
        toolId: 'plate', toolName: 'Plate', toolIcon: 'plate',
        notes: 'Garnish with herbs',
        inputLotIds: ['l5'], outputLotIds: ['l6'],
      );
      final restored = ProcedureOperation.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.station, original.station);
      expect(restored.actionId, original.actionId);
      expect(restored.toolId, original.toolId);
      expect(restored.notes, original.notes);
      expect(restored.inputLotIds, original.inputLotIds);
      expect(restored.outputLotIds, original.outputLotIds);
    });

    test('fromJson with missing fields uses defaults', () {
      final json = <String, dynamic>{};
      final op = ProcedureOperation.fromJson(json);
      expect(op.id, '');
      expect(op.station, ProcedureStation.prep);
      expect(op.actionId, '');
      expect(op.actionEmoji, '*');
      expect(op.inputLotIds, isEmpty);
      expect(op.outputLotIds, isEmpty);
    });

    test('fromJson with invalid station falls back to prep', () {
      final json = {
        'id': 'op-x',
        'station': 'invalid_station',
        'actionId': 'a',
        'actionName': 'A',
        'actionEmoji': '馃敧',
        'inputLotIds': <String>[],
        'outputLotIds': <String>[],
      };
      final op = ProcedureOperation.fromJson(json);
      expect(op.station, ProcedureStation.prep);
    });
  });

  group('RecipeProcedure', () {
    test('empty factory', () {
      final proc = RecipeProcedure.empty();
      expect(proc.version, '1.0.0');
      expect(proc.lots, isEmpty);
      expect(proc.operations, isEmpty);
    });

    test('creation', () {
      const proc = RecipeProcedure(
        version: '2.0.0',
        lots: [
          MaterialLot(id: 'l1', ingredientId: 'a', name: 'A', emoji: 'a', amount: '1', unit: 'pcs', state: 'raw', assetKey: 'a_raw'),
        ],
        operations: [
          ProcedureOperation(
            id: 'op1', station: ProcedureStation.prep,
            actionId: 'cut', actionName: 'Cut', actionEmoji: '馃敧',
            inputLotIds: ['l1'], outputLotIds: ['l2'],
          ),
        ],
      );
      expect(proc.version, '2.0.0');
      expect(proc.lots.length, 1);
      expect(proc.operations.length, 1);
    });

    test('copyWith', () {
      final original = RecipeProcedure.empty();
      final updated = original.copyWith(version: '3.0.0');
      expect(updated.version, '3.0.0');
      expect(updated.lots, isEmpty);
    });

    test('toJson/fromJson roundtrip', () {
      const original = RecipeProcedure(
        version: '1.5.0',
        lots: [
          MaterialLot(id: 'l1', ingredientId: 'rice', name: 'Rice', emoji: '馃崥', amount: '200', unit: 'g', state: 'raw', assetKey: 'rice_raw'),
          MaterialLot(id: 'l2', ingredientId: 'rice', name: 'Cooked Rice', emoji: '馃崥', amount: '200', unit: 'g', state: 'cooked', assetKey: 'rice_cooked', derivedFromLotId: 'l1'),
        ],
        operations: [
          ProcedureOperation(
            id: 'op1', station: ProcedureStation.cook,
            actionId: 'boil', actionName: 'Boil', actionEmoji: '鈾笍',
            toolId: 'pot', toolName: 'Pot', toolIcon: '馃嵅',
            temperature: 'High', duration: '15 mins',
            inputLotIds: ['l1'], outputLotIds: ['l2'],
          ),
        ],
      );
      final restored = RecipeProcedure.fromJson(original.toJson());
      expect(restored.version, '1.5.0');
      expect(restored.lots.length, 2);
      expect(restored.operations.length, 1);
      expect(restored.lots[1].derivedFromLotId, 'l1');
      expect(restored.operations[0].temperature, 'High');
    });

    test('fromJson with missing lists', () {
      final json = {'version': '1.0.0'};
      final proc = RecipeProcedure.fromJson(json);
      expect(proc.lots, isEmpty);
      expect(proc.operations, isEmpty);
    });

    test('fromJson with null version defaults', () {
      final json = <String, dynamic>{
        'lots': [],
        'operations': [],
      };
      final proc = RecipeProcedure.fromJson(json);
      expect(proc.version, '1.0.0');
    });
  });
}

