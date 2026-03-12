enum ProcedureStation { prep, cook, finish }

class MaterialLot {
  final String id;
  final String ingredientId;
  final String name;
  final String emoji;
  final String amount;
  final String unit;
  final String state;
  final String assetKey;
  final List<String>? componentLotIds;
  final String? containerId;
  final String? producedByOperationId;
  final String? derivedFromLotId;
  final String? notes;

  const MaterialLot({
    required this.id,
    required this.ingredientId,
    required this.name,
    required this.emoji,
    required this.amount,
    required this.unit,
    required this.state,
    required this.assetKey,
    this.componentLotIds,
    this.containerId,
    this.producedByOperationId,
    this.derivedFromLotId,
    this.notes,
  });

  MaterialLot copyWith({
    String? id,
    String? ingredientId,
    String? name,
    String? emoji,
    String? amount,
    String? unit,
    String? state,
    String? assetKey,
    List<String>? componentLotIds,
    String? containerId,
    String? producedByOperationId,
    String? derivedFromLotId,
    String? notes,
  }) {
    return MaterialLot(
      id: id ?? this.id,
      ingredientId: ingredientId ?? this.ingredientId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      state: state ?? this.state,
      assetKey: assetKey ?? this.assetKey,
      componentLotIds: componentLotIds ?? this.componentLotIds,
      containerId: containerId ?? this.containerId,
      producedByOperationId:
          producedByOperationId ?? this.producedByOperationId,
      derivedFromLotId: derivedFromLotId ?? this.derivedFromLotId,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ingredientId': ingredientId,
        'name': name,
        'emoji': emoji,
        'amount': amount,
        'unit': unit,
        'state': state,
        'assetKey': assetKey,
        'componentLotIds': componentLotIds,
        'containerId': containerId,
        'producedByOperationId': producedByOperationId,
        'derivedFromLotId': derivedFromLotId,
        'notes': notes,
      };

  factory MaterialLot.fromJson(Map<String, dynamic> json) {
    return MaterialLot(
      id: json['id'] ?? '',
      ingredientId: json['ingredientId'] ?? '',
      name: json['name'] ?? '',
      emoji: json['emoji'] ?? '',
      amount: json['amount'] ?? '1',
      unit: json['unit'] ?? 'pcs',
      state: json['state'] ?? 'raw',
      assetKey: json['assetKey'] ?? ((json['ingredientId'] ?? '') + '_' + (json['state'] ?? 'raw')),
      componentLotIds: json['componentLotIds'] != null
          ? List<String>.from(json['componentLotIds'] as List)
          : null,
      containerId: json['containerId'],
      producedByOperationId: json['producedByOperationId'],
      derivedFromLotId: json['derivedFromLotId'],
      notes: json['notes'],
    );
  }
}

class ProcedureOperation {
  final String id;
  final ProcedureStation station;
  final String actionId;
  final String actionName;
  final String actionEmoji;
  final String? toolId;
  final String? toolName;
  final String? toolIcon;
  final String? temperature;
  final String? duration;
  final String? waterLevel;
  final String? notes;
  final List<String> inputLotIds;
  final List<String> outputLotIds;

  const ProcedureOperation({
    required this.id,
    required this.station,
    required this.actionId,
    required this.actionName,
    required this.actionEmoji,
    this.toolId,
    this.toolName,
    this.toolIcon,
    this.temperature,
    this.duration,
    this.waterLevel,
    this.notes,
    required this.inputLotIds,
    required this.outputLotIds,
  });

  ProcedureOperation copyWith({
    String? id,
    ProcedureStation? station,
    String? actionId,
    String? actionName,
    String? actionEmoji,
    String? toolId,
    String? toolName,
    String? toolIcon,
    String? temperature,
    String? duration,
    String? waterLevel,
    String? notes,
    List<String>? inputLotIds,
    List<String>? outputLotIds,
  }) {
    return ProcedureOperation(
      id: id ?? this.id,
      station: station ?? this.station,
      actionId: actionId ?? this.actionId,
      actionName: actionName ?? this.actionName,
      actionEmoji: actionEmoji ?? this.actionEmoji,
      toolId: toolId ?? this.toolId,
      toolName: toolName ?? this.toolName,
      toolIcon: toolIcon ?? this.toolIcon,
      temperature: temperature ?? this.temperature,
      duration: duration ?? this.duration,
      waterLevel: waterLevel ?? this.waterLevel,
      notes: notes ?? this.notes,
      inputLotIds: inputLotIds ?? this.inputLotIds,
      outputLotIds: outputLotIds ?? this.outputLotIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'station': station.name,
        'actionId': actionId,
        'actionName': actionName,
        'actionEmoji': actionEmoji,
        'toolId': toolId,
        'toolName': toolName,
        'toolIcon': toolIcon,
        'temperature': temperature,
        'duration': duration,
        'waterLevel': waterLevel,
        'notes': notes,
        'inputLotIds': inputLotIds,
        'outputLotIds': outputLotIds,
      };

  factory ProcedureOperation.fromJson(Map<String, dynamic> json) {
    return ProcedureOperation(
      id: json['id'] ?? '',
      station: ProcedureStation.values.firstWhere(
        (e) => e.name == json['station'],
        orElse: () => ProcedureStation.prep,
      ),
      actionId: json['actionId'] ?? '',
      actionName: json['actionName'] ?? '',
      actionEmoji: json['actionEmoji'] ?? '*',
      toolId: json['toolId'],
      toolName: json['toolName'],
      toolIcon: json['toolIcon'],
      temperature: json['temperature'],
      duration: json['duration'],
      waterLevel: json['waterLevel'],
      notes: json['notes'],
      inputLotIds: List<String>.from(json['inputLotIds'] ?? const []),
      outputLotIds: List<String>.from(json['outputLotIds'] ?? const []),
    );
  }
}

class RecipeProcedure {
  final String version;
  final List<MaterialLot> lots;
  final List<ProcedureOperation> operations;

  const RecipeProcedure({
    required this.version,
    required this.lots,
    required this.operations,
  });

  factory RecipeProcedure.empty() {
    return const RecipeProcedure(version: '1.0.0', lots: [], operations: []);
  }

  RecipeProcedure copyWith({
    String? version,
    List<MaterialLot>? lots,
    List<ProcedureOperation>? operations,
  }) {
    return RecipeProcedure(
      version: version ?? this.version,
      lots: lots ?? this.lots,
      operations: operations ?? this.operations,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'lots': lots.map((l) => l.toJson()).toList(),
        'operations': operations.map((o) => o.toJson()).toList(),
      };

  factory RecipeProcedure.fromJson(Map<String, dynamic> json) {
    return RecipeProcedure(
      version: json['version'] ?? '1.0.0',
      lots: (json['lots'] as List? ?? const [])
          .map((l) => MaterialLot.fromJson(Map<String, dynamic>.from(l)))
          .toList(),
      operations: (json['operations'] as List? ?? const [])
          .map((o) => ProcedureOperation.fromJson(Map<String, dynamic>.from(o)))
          .toList(),
    );
  }
}

