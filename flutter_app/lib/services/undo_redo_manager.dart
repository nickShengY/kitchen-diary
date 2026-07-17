import 'dart:collection';
import 'package:flutter/foundation.dart';

/// A generic undo/redo manager for animation composer actions.
/// Supports action grouping, history limits, and snapshot triggers.
class UndoRedoManager<T> extends ChangeNotifier {
  final int maxHistorySize;
  final Duration groupingDelay;

  final Queue<UndoableAction<T>> _undoStack = Queue();
  final Queue<UndoableAction<T>> _redoStack = Queue();

  DateTime? _lastActionTime;
  String? _lastActionType;

  UndoRedoManager({
    this.maxHistorySize = 50,
    this.groupingDelay = const Duration(milliseconds: 500),
  });

  /// Whether undo is available
  bool get canUndo => _undoStack.isNotEmpty;

  /// Whether redo is available
  bool get canRedo => _redoStack.isNotEmpty;

  /// Number of actions in undo history
  int get undoCount => _undoStack.length;

  /// Number of actions in redo history
  int get redoCount => _redoStack.length;

  /// Execute an action and add it to history
  void execute(UndoableAction<T> action) {
    // Execute the action
    action.execute();

    // Check if we should group with previous action
    final now = DateTime.now();
    final shouldGroup = _lastActionTime != null &&
        _lastActionType == action.type &&
        now.difference(_lastActionTime!) < groupingDelay;

    if (shouldGroup && _undoStack.isNotEmpty) {
      // Merge with previous action
      final previous = _undoStack.removeLast();
      final merged = GroupedAction<T>(
        type: action.type,
        actions: [
          if (previous is GroupedAction<T>) ...previous.actions else previous,
          action,
        ],
      );
      _undoStack.addLast(merged);
    } else {
      // Add as new action
      _undoStack.addLast(action);
    }

    // Enforce history limit
    while (_undoStack.length > maxHistorySize) {
      _undoStack.removeFirst();
    }

    // Clear redo stack on new action
    _redoStack.clear();

    // Update tracking
    _lastActionTime = now;
    _lastActionType = action.type;

    notifyListeners();
  }

  /// Undo the last action
  void undo() {
    if (!canUndo) return;

    final action = _undoStack.removeLast();
    action.undo();
    _redoStack.addLast(action);

    _lastActionTime = null;
    _lastActionType = null;

    notifyListeners();
  }

  /// Redo the last undone action
  void redo() {
    if (!canRedo) return;

    final action = _redoStack.removeLast();
    action.execute();
    _undoStack.addLast(action);

    notifyListeners();
  }

  /// Clear all history
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _lastActionTime = null;
    _lastActionType = null;
    notifyListeners();
  }

  /// Create a snapshot for later restoration
  UndoSnapshot createSnapshot() {
    return UndoSnapshot(
      undoCount: _undoStack.length,
      redoCount: _redoStack.length,
      timestamp: DateTime.now(),
    );
  }
}

/// Abstract base class for undoable actions
abstract class UndoableAction<T> {
  /// Action type for grouping
  String get type;

  /// Human-readable description
  String get description;

  /// Execute the action
  void execute();

  /// Undo the action
  void undo();
}

/// A simple undoable action with execute/undo callbacks
class SimpleAction<T> implements UndoableAction<T> {
  @override
  final String type;

  @override
  final String description;

  final VoidCallback _execute;
  final VoidCallback _undo;

  SimpleAction({
    required this.type,
    required this.description,
    required VoidCallback onExecute,
    required VoidCallback onUndo,
  })  : _execute = onExecute,
        _undo = onUndo;

  @override
  void execute() => _execute();

  @override
  void undo() => _undo();
}

/// A grouped action containing multiple actions
class GroupedAction<T> implements UndoableAction<T> {
  @override
  final String type;

  final List<UndoableAction<T>> actions;

  GroupedAction({
    required this.type,
    required this.actions,
  });

  @override
  String get description => '${actions.length} ${type}s';

  @override
  void execute() {
    for (final action in actions) {
      action.execute();
    }
  }

  @override
  void undo() {
    for (final action in actions.reversed) {
      action.undo();
    }
  }
}

/// Snapshot of undo/redo state
class UndoSnapshot {
  final int undoCount;
  final int redoCount;
  final DateTime timestamp;

  UndoSnapshot({
    required this.undoCount,
    required this.redoCount,
    required this.timestamp,
  });
}

/// Pre-defined action types for the animation composer
class AnimationActionTypes {
  static const String addIngredient = 'add_ingredient';
  static const String removeIngredient = 'remove_ingredient';
  static const String addStep = 'add_step';
  static const String removeStep = 'remove_step';
  static const String reorderSteps = 'reorder_steps';
  static const String changeAction = 'change_action';
  static const String changeState = 'change_state';
}

/// Extension for creating common animation actions
extension AnimationUndoActions on UndoRedoManager {
  void addIngredient({
    required String ingredientId,
    required VoidCallback onAdd,
    required VoidCallback onRemove,
  }) {
    execute(SimpleAction(
      type: AnimationActionTypes.addIngredient,
      description: 'Add ingredient',
      onExecute: onAdd,
      onUndo: onRemove,
    ));
  }

  void removeIngredient({
    required String ingredientId,
    required VoidCallback onRemove,
    required VoidCallback onRestore,
  }) {
    execute(SimpleAction(
      type: AnimationActionTypes.removeIngredient,
      description: 'Remove ingredient',
      onExecute: onRemove,
      onUndo: onRestore,
    ));
  }

  void addStep({
    required int index,
    required VoidCallback onAdd,
    required VoidCallback onRemove,
  }) {
    execute(SimpleAction(
      type: AnimationActionTypes.addStep,
      description: 'Add step',
      onExecute: onAdd,
      onUndo: onRemove,
    ));
  }

  void removeStep({
    required int index,
    required VoidCallback onRemove,
    required VoidCallback onRestore,
  }) {
    execute(SimpleAction(
      type: AnimationActionTypes.removeStep,
      description: 'Remove step',
      onExecute: onRemove,
      onUndo: onRestore,
    ));
  }

  void reorderSteps({
    required int oldIndex,
    required int newIndex,
    required VoidCallback onReorder,
    required VoidCallback onRevert,
  }) {
    execute(SimpleAction(
      type: AnimationActionTypes.reorderSteps,
      description: 'Reorder steps',
      onExecute: onReorder,
      onUndo: onRevert,
    ));
  }
}
