/// Modular Cooking Animation System Models
///
/// This file contains all the models needed for the composable cooking animation
/// system that tracks ingredient transformations through cooking steps.
library;

import 'package:flutter/animation.dart';

/// Represents the visual and logical state of an ingredient
class IngredientState {
  final String id;
  final String label;
  final String suffix;
  final String visualModifier;

  const IngredientState({
    required this.id,
    required this.label,
    required this.suffix,
    required this.visualModifier,
  });

  factory IngredientState.fromJson(Map<String, dynamic> json) {
    return IngredientState(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      suffix: json['suffix'] ?? '',
      visualModifier: json['visualModifier'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'suffix': suffix,
        'visualModifier': visualModifier,
      };
}

/// Defines how an action transforms ingredient states
class ActionTransformation {
  final String actionId;
  final List<String> inputStates;
  final String outputState;
  final String animationType;

  const ActionTransformation({
    required this.actionId,
    required this.inputStates,
    required this.outputState,
    required this.animationType,
  });

  factory ActionTransformation.fromJson(
      String actionId, Map<String, dynamic> json) {
    return ActionTransformation(
      actionId: actionId,
      inputStates: List<String>.from(json['inputStates'] ?? []),
      outputState: json['outputState'] ?? '',
      animationType: json['animationType'] ?? '',
    );
  }

  bool canTransform(String currentState) => inputStates.contains(currentState);
}

/// Animation type configuration with timing and effects
class AnimationType {
  final String id;
  final String name;
  final int frames;
  final int duration;
  final String easing;
  final bool loop;
  final List<String> particleEffects;
  final String? soundId;

  const AnimationType({
    required this.id,
    required this.name,
    required this.frames,
    required this.duration,
    required this.easing,
    this.loop = false,
    required this.particleEffects,
    this.soundId,
  });

  factory AnimationType.fromJson(Map<String, dynamic> json) {
    return AnimationType(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      frames: json['frames'] ?? 8,
      duration: json['duration'] ?? 800,
      easing: json['easing'] ?? 'easeInOutCubic',
      loop: json['loop'] ?? false,
      particleEffects: List<String>.from(json['particleEffects'] ?? []),
      soundId: json['soundId'],
    );
  }

  Duration get animationDuration => Duration(milliseconds: duration);

  Curve get curve {
    switch (easing) {
      case 'linear':
        return Curves.linear;
      case 'easeInOutCubic':
        return Curves.easeInOutCubic;
      case 'easeOutQuad':
        return Curves.easeOutQuad;
      case 'easeInOutSine':
        return Curves.easeInOutSine;
      case 'easeOutBack':
        return Curves.easeOutBack;
      case 'easeOutCubic':
        return Curves.easeOutCubic;
      default:
        return Curves.easeInOutCubic;
    }
  }
}

/// Particle effect configuration
class ParticleEffect {
  final String id;
  final String type;
  final String color;
  final int count;
  final int lifetime;
  final double? gravity;
  final String? direction;
  final String? animation;

  const ParticleEffect({
    required this.id,
    required this.type,
    required this.color,
    required this.count,
    required this.lifetime,
    this.gravity,
    this.direction,
    this.animation,
  });

  factory ParticleEffect.fromJson(String id, Map<String, dynamic> json) {
    return ParticleEffect(
      id: id,
      type: json['type'] ?? 'particle',
      color: json['color'] ?? 'white',
      count: json['count'] ?? 10,
      lifetime: json['lifetime'] ?? 500,
      gravity: json['gravity']?.toDouble(),
      direction: json['direction'],
      animation: json['animation'],
    );
  }

  Duration get lifetimeDuration => Duration(milliseconds: lifetime);
}

/// A composable cooking technique block
class ComposableBlock {
  final String id;
  final String name;
  final String description;
  final List<String> sequence;
  final List<String> applicableTo;
  final String estimatedTime;
  final bool requiresHeat;

  const ComposableBlock({
    required this.id,
    required this.name,
    required this.description,
    required this.sequence,
    required this.applicableTo,
    required this.estimatedTime,
    this.requiresHeat = false,
  });

  factory ComposableBlock.fromJson(Map<String, dynamic> json) {
    return ComposableBlock(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      sequence: List<String>.from(json['sequence'] ?? []),
      applicableTo: List<String>.from(json['applicableTo'] ?? []),
      estimatedTime: json['estimatedTime'] ?? '',
      requiresHeat: json['requiresHeat'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'sequence': sequence,
        'applicableTo': applicableTo,
        'estimatedTime': estimatedTime,
        'requiresHeat': requiresHeat,
      };

  bool isApplicableTo(String category) =>
      applicableTo.contains('any') || applicableTo.contains(category);
}

/// Represents a single step in a recipe animation
class AnimationStep {
  final String id;
  final int order;
  final String? blockId;
  final String? actionId;
  final String? ingredientId;
  final List<String>? ingredientIds;
  final List<String>? ingredientNames;
  final String? toolId;
  final String fromState;
  final String toState;
  final AnimationType? animationType;
  final Duration duration;
  final bool isCompleted;

  const AnimationStep({
    required this.id,
    required this.order,
    this.blockId,
    this.actionId,
    this.ingredientId,
    this.ingredientIds,
    this.ingredientNames,
    this.toolId,
    required this.fromState,
    required this.toState,
    this.animationType,
    this.duration = const Duration(milliseconds: 800),
    this.isCompleted = false,
  });

  AnimationStep copyWith({
    String? id,
    int? order,
    String? blockId,
    String? actionId,
    String? ingredientId,
    List<String>? ingredientIds,
    List<String>? ingredientNames,
    String? toolId,
    String? fromState,
    String? toState,
    AnimationType? animationType,
    Duration? duration,
    bool? isCompleted,
  }) {
    return AnimationStep(
      id: id ?? this.id,
      order: order ?? this.order,
      blockId: blockId ?? this.blockId,
      actionId: actionId ?? this.actionId,
      ingredientId: ingredientId ?? this.ingredientId,
      ingredientIds: ingredientIds ?? this.ingredientIds,
      ingredientNames: ingredientNames ?? this.ingredientNames,
      toolId: toolId ?? this.toolId,
      fromState: fromState ?? this.fromState,
      toState: toState ?? this.toState,
      animationType: animationType ?? this.animationType,
      duration: duration ?? this.duration,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  List<String> get allIngredientIds {
    if (ingredientIds != null && ingredientIds!.isNotEmpty) {
      return ingredientIds!;
    }
    if (ingredientId != null) {
      return [ingredientId!];
    }
    return [];
  }

  List<String> get allIngredientNames {
    if (ingredientNames != null && ingredientNames!.isNotEmpty) {
      return ingredientNames!;
    }
    return allIngredientIds;
  }
}

/// Tracks the current state of an ingredient during animation
class IngredientAnimationState {
  final String ingredientId;
  final String ingredientName;
  final String emoji;
  final String currentState;
  final String? assetKey;
  final List<String> stateHistory;
  final List<Color> colorPalette;
  final double animationProgress;
  final bool isAnimating;

  const IngredientAnimationState({
    required this.ingredientId,
    required this.ingredientName,
    required this.emoji,
    required this.currentState,
    this.assetKey,
    this.stateHistory = const [],
    this.colorPalette = const [],
    this.animationProgress = 0.0,
    this.isAnimating = false,
  });

  IngredientAnimationState copyWith({
    String? ingredientId,
    String? ingredientName,
    String? emoji,
    String? currentState,
    String? assetKey,
    List<String>? stateHistory,
    List<Color>? colorPalette,
    double? animationProgress,
    bool? isAnimating,
  }) {
    return IngredientAnimationState(
      ingredientId: ingredientId ?? this.ingredientId,
      ingredientName: ingredientName ?? this.ingredientName,
      emoji: emoji ?? this.emoji,
      currentState: currentState ?? this.currentState,
      assetKey: assetKey ?? this.assetKey,
      stateHistory: stateHistory ?? this.stateHistory,
      colorPalette: colorPalette ?? this.colorPalette,
      animationProgress: animationProgress ?? this.animationProgress,
      isAnimating: isAnimating ?? this.isAnimating,
    );
  }

  IngredientAnimationState transitionTo(String newState) {
    return copyWith(
      currentState: newState,
      stateHistory: [...stateHistory, currentState],
      animationProgress: 0.0,
      isAnimating: true,
    );
  }
}

/// Complete recipe animation with all steps and state tracking
class RecipeAnimation {
  final String id;
  final String title;
  final String description;
  final List<AnimationStep> steps;
  final Map<String, IngredientAnimationState> ingredientStates;
  final int currentStepIndex;
  final bool isPlaying;
  final bool isCompleted;
  final Duration totalDuration;
  final String? thumbnailUrl;

  const RecipeAnimation({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
    this.ingredientStates = const {},
    this.currentStepIndex = 0,
    this.isPlaying = false,
    this.isCompleted = false,
    this.totalDuration = Duration.zero,
    this.thumbnailUrl,
  });

  factory RecipeAnimation.fromJson(Map<String, dynamic> json) {
    return RecipeAnimation(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      steps: [], // Steps are built dynamically from blocks
      totalDuration: Duration(seconds: json['animationDuration'] ?? 30),
    );
  }

  RecipeAnimation copyWith({
    String? id,
    String? title,
    String? description,
    List<AnimationStep>? steps,
    Map<String, IngredientAnimationState>? ingredientStates,
    int? currentStepIndex,
    bool? isPlaying,
    bool? isCompleted,
    Duration? totalDuration,
    String? thumbnailUrl,
  }) {
    return RecipeAnimation(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      steps: steps ?? this.steps,
      ingredientStates: ingredientStates ?? this.ingredientStates,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isCompleted: isCompleted ?? this.isCompleted,
      totalDuration: totalDuration ?? this.totalDuration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }

  AnimationStep? get currentStep =>
      currentStepIndex < steps.length ? steps[currentStepIndex] : null;

  double get progress => steps.isEmpty ? 0.0 : currentStepIndex / steps.length;

  bool get hasNextStep => currentStepIndex < steps.length - 1;

  bool get hasPreviousStep => currentStepIndex > 0;

  RecipeAnimation nextStep() {
    if (!hasNextStep) return copyWith(isCompleted: true, isPlaying: false);
    return copyWith(currentStepIndex: currentStepIndex + 1);
  }

  RecipeAnimation previousStep() {
    if (!hasPreviousStep) return this;
    return copyWith(currentStepIndex: currentStepIndex - 1);
  }

  RecipeAnimation reset() {
    return copyWith(
      currentStepIndex: 0,
      isPlaying: false,
      isCompleted: false,
    );
  }
}

/// Animation timeline for visual representation
class AnimationTimeline {
  final List<TimelineNode> nodes;
  final Duration totalDuration;

  const AnimationTimeline({
    required this.nodes,
    required this.totalDuration,
  });

  factory AnimationTimeline.fromSteps(List<AnimationStep> steps) {
    Duration accumulated = Duration.zero;
    final nodes = <TimelineNode>[];

    for (final step in steps) {
      nodes.add(TimelineNode(
        step: step,
        startTime: accumulated,
        endTime: accumulated + step.duration,
      ));
      accumulated += step.duration;
    }

    return AnimationTimeline(
      nodes: nodes,
      totalDuration: accumulated,
    );
  }

  TimelineNode? nodeAtTime(Duration time) {
    for (final node in nodes) {
      if (time >= node.startTime && time < node.endTime) {
        return node;
      }
    }
    return nodes.isNotEmpty ? nodes.last : null;
  }
}

/// A single node in the animation timeline
class TimelineNode {
  final AnimationStep step;
  final Duration startTime;
  final Duration endTime;

  const TimelineNode({
    required this.step,
    required this.startTime,
    required this.endTime,
  });

  Duration get duration => endTime - startTime;

  double progressAt(Duration currentTime) {
    if (currentTime <= startTime) return 0.0;
    if (currentTime >= endTime) return 1.0;
    return (currentTime - startTime).inMilliseconds / duration.inMilliseconds;
  }
}

/// Animation preset configuration
class AnimationPreset {
  final String id;
  final String type;
  final Map<String, dynamic> parameters;

  const AnimationPreset({
    required this.id,
    required this.type,
    required this.parameters,
  });

  factory AnimationPreset.fromJson(String id, Map<String, dynamic> json) {
    return AnimationPreset(
      id: id,
      type: json['type'] ?? '',
      parameters: Map<String, dynamic>.from(json)..remove('type'),
    );
  }

  double? get stiffness => parameters['stiffness']?.toDouble();
  double? get damping => parameters['damping']?.toDouble();
  double? get amplitude => parameters['amplitude']?.toDouble();
  double? get frequency => parameters['frequency']?.toDouble();
  double? get min => parameters['min']?.toDouble();
  double? get max => parameters['max']?.toDouble();
  int? get duration => parameters['duration'];
  int? get count => parameters['count'];
  double? get angle => parameters['angle']?.toDouble();
  int? get speed => parameters['speed'];
  String? get direction => parameters['direction'];
  int? get spread => parameters['spread'];
  int? get lifetime => parameters['lifetime'];
  String? get curve => parameters['curve'];
}

/// Builder class to compose recipe animations from blocks
class RecipeAnimationBuilder {
  final String id;
  final String title;
  String description;
  final List<AnimationStep> _steps = [];
  final Map<String, IngredientAnimationState> _ingredientStates = {};
  int _stepCounter = 0;

  RecipeAnimationBuilder({
    required this.id,
    required this.title,
    this.description = '',
  });

  void addIngredient(String ingredientId, String name, String emoji,
      {String initialState = 'raw',
      List<Color> colors = const [],
      String? assetKey}) {
    _ingredientStates[ingredientId] = IngredientAnimationState(
      ingredientId: ingredientId,
      ingredientName: name,
      emoji: emoji,
      currentState: initialState,
      assetKey: assetKey,
      colorPalette: colors,
    );
  }

  void addStep({
    String? blockId,
    String? actionId,
    String? ingredientId,
    List<String>? ingredientIds,
    List<String>? ingredientNames,
    String? toolId,
    required String fromState,
    required String toState,
    AnimationType? animationType,
    Duration duration = const Duration(milliseconds: 800),
  }) {
    _steps.add(AnimationStep(
      id: 'step_${_stepCounter++}',
      order: _steps.length,
      blockId: blockId,
      actionId: actionId,
      ingredientId: ingredientId,
      ingredientIds: ingredientIds,
      ingredientNames: ingredientNames,
      toolId: toolId,
      fromState: fromState,
      toState: toState,
      animationType: animationType,
      duration: duration,
    ));
  }

  void addBlock(
      ComposableBlock block,
      List<String> ingredientIds,
      Map<String, ActionTransformation> transformations,
      Map<String, AnimationType> animationTypes) {
    for (final actionId in block.sequence) {
      final transform = transformations[actionId];
      if (transform == null) continue;

      final animType = animationTypes[transform.animationType];

      addStep(
        blockId: block.id,
        actionId: actionId,
        ingredientIds: ingredientIds,
        fromState: transform.inputStates.first,
        toState: transform.outputState,
        animationType: animType,
        duration:
            animType?.animationDuration ?? const Duration(milliseconds: 800),
      );
    }
  }

  RecipeAnimation build() {
    Duration total = Duration.zero;
    for (final step in _steps) {
      total += step.duration;
    }

    return RecipeAnimation(
      id: id,
      title: title,
      description: description,
      steps: List.unmodifiable(_steps),
      ingredientStates: Map.unmodifiable(_ingredientStates),
      totalDuration: total,
    );
  }
}
