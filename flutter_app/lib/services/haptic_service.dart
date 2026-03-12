import 'package:flutter/services.dart';

/// Service for managing haptic feedback patterns in the animation system.
/// Maps action-specific haptic patterns to Flutter's HapticFeedback API.
class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  bool _enabled = true;

  /// Enable or disable haptic feedback
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Check if haptic feedback is enabled
  bool get isEnabled => _enabled;

  /// Trigger haptic feedback based on pattern name from kitchen_data.json
  Future<void> trigger(String patternName) async {
    if (!_enabled) return;

    switch (patternName) {
      // Impact patterns
      case 'impact-medium':
        await HapticFeedback.mediumImpact();
        break;
      case 'impact-light':
      case 'impact-soft':
        await HapticFeedback.lightImpact();
        break;
      case 'impact-heavy':
      case 'impact-heavy-single':
        await HapticFeedback.heavyImpact();
        break;
      case 'impact-light-rapid':
        await _rapidLightImpact(3);
        break;
      case 'impact-light-continuous':
        await _rapidLightImpact(5);
        break;
      case 'impact-medium-rhythm':
        await _rhythmicImpact(3, HapticFeedback.mediumImpact);
        break;
      case 'impact-heavy-rhythm':
      case 'impact-rhythm-fast':
        await _rhythmicImpact(4, HapticFeedback.heavyImpact);
        break;

      // Selection patterns
      case 'selection':
      case 'selection-light':
        await HapticFeedback.selectionClick();
        break;

      // Soft patterns
      case 'soft-continuous':
      case 'soft-sustained':
      case 'soft-flow':
        await HapticFeedback.lightImpact();
        break;
      case 'soft-rapid':
        await _rapidLightImpact(4);
        break;
      case 'soft-pulse':
        await _pulsePattern();
        break;

      // Rigid patterns
      case 'rigid-continuous':
      case 'rigid-rapid':
        await _rapidMediumImpact(4);
        break;

      // Notification patterns
      case 'notification':
      case 'notification-warm':
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        await HapticFeedback.lightImpact();
        break;
      case 'notification-success':
      case 'success':
        await _successPattern();
        break;

      // Default fallback
      default:
        await HapticFeedback.selectionClick();
    }
  }

  /// Trigger haptic for a specific action by looking up its pattern
  Future<void> triggerForAction(Map<String, dynamic> actionData) async {
    final patternName = actionData['hapticPattern'] as String?;
    if (patternName != null) {
      await trigger(patternName);
    } else {
      // Fallback based on difficulty
      final difficulty = actionData['difficulty'] as int? ?? 1;
      switch (difficulty) {
        case 1:
          await HapticFeedback.lightImpact();
          break;
        case 2:
          await HapticFeedback.mediumImpact();
          break;
        case 3:
          await HapticFeedback.heavyImpact();
          break;
        default:
          await HapticFeedback.selectionClick();
      }
    }
  }

  /// Trigger haptic when animation step completes
  Future<void> triggerStepComplete() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Trigger haptic when animation finishes
  Future<void> triggerAnimationComplete() async {
    if (!_enabled) return;
    await _successPattern();
  }

  /// Trigger haptic when dragging starts
  Future<void> triggerDragStart() async {
    if (!_enabled) return;
    await HapticFeedback.selectionClick();
  }

  /// Trigger haptic when item is dropped
  Future<void> triggerDrop() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Trigger haptic for error/incompatible action
  Future<void> triggerError() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.heavyImpact();
  }

  // Helper patterns

  Future<void> _rapidLightImpact(int count) async {
    for (int i = 0; i < count; i++) {
      await HapticFeedback.lightImpact();
      if (i < count - 1) {
        await Future.delayed(const Duration(milliseconds: 40));
      }
    }
  }

  Future<void> _rapidMediumImpact(int count) async {
    for (int i = 0; i < count; i++) {
      await HapticFeedback.mediumImpact();
      if (i < count - 1) {
        await Future.delayed(const Duration(milliseconds: 60));
      }
    }
  }

  Future<void> _rhythmicImpact(int count, Future<void> Function() impactFn) async {
    for (int i = 0; i < count; i++) {
      await impactFn();
      if (i < count - 1) {
        await Future.delayed(const Duration(milliseconds: 120));
      }
    }
  }

  Future<void> _pulsePattern() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    await HapticFeedback.lightImpact();
  }

  Future<void> _successPattern() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
  }
}

/// Extension to easily trigger haptics from action maps
extension HapticActionExtension on Map<String, dynamic> {
  Future<void> triggerHaptic() async {
    await HapticService().triggerForAction(this);
  }
}
