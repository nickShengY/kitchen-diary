import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// Quick actions bottom sheet
class QuickActionsSheet extends StatelessWidget {
  final List<QuickAction> actions;
  final String? title;

  const QuickActionsSheet({
    super.key,
    required this.actions,
    this.title,
  });

  static Future<String?> show(
    BuildContext context, {
    required List<QuickAction> actions,
    String? title,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickActionsSheet(actions: actions, title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Divider(color: AppColors.divider, height: 1),
            ],

            // Actions grid
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: actions.asMap().entries.map((entry) {
                  final action = entry.value;
                  return _ActionButton(
                    action: action,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context, action.id);
                    },
                  )
                      .animate(delay: Duration(milliseconds: entry.key * 50))
                      .fadeIn()
                      .slideY(begin: 0.2, end: 0);
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final QuickAction action;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 56) / 3;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: action.destructive
              ? Colors.red.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(action.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: action.destructive ? Colors.red : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class QuickAction {
  final String id;
  final String label;
  final String emoji;
  final bool destructive;

  const QuickAction({
    required this.id,
    required this.label,
    required this.emoji,
    this.destructive = false,
  });
}

/// Create options bottom sheet
class CreateOptionsSheet extends StatelessWidget {
  final List<CreateOption> options;

  const CreateOptionsSheet({
    super.key,
    required this.options,
  });

  static Future<String?> show(
    BuildContext context, {
    required List<CreateOption> options,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateOptionsSheet(options: options),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Text('✨', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 10),
                      Text(
                        'Create',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...options.asMap().entries.map((entry) {
                    final option = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CreateOptionTile(
                        option: option,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context, option.id);
                        },
                      )
                          .animate(
                              delay: Duration(milliseconds: entry.key * 80))
                          .fadeIn()
                          .slideX(begin: 0.1, end: 0),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateOptionTile extends StatelessWidget {
  final CreateOption option;
  final VoidCallback? onTap;

  const _CreateOptionTile({
    required this.option,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(option.emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (option.description != null)
                    Text(
                      option.description!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class CreateOption {
  final String id;
  final String label;
  final String emoji;
  final String? description;

  const CreateOption({
    required this.id,
    required this.label,
    required this.emoji,
    this.description,
  });
}

/// Error state widget
class ErrorStateWidget extends StatelessWidget {
  final String emoji;
  final String title;
  final String message;
  final String? primaryAction;
  final String? secondaryAction;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;

  const ErrorStateWidget({
    super.key,
    required this.emoji,
    required this.title,
    required this.message,
    this.primaryAction,
    this.secondaryAction,
    this.onPrimaryAction,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    duration: 1000.ms),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (primaryAction != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPrimaryAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(primaryAction!),
                ),
              ),
            if (secondaryAction != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(secondaryAction!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Toast/Snackbar helper
class ToastHelper {
  static void show(
    BuildContext context, {
    required String message,
    String? emoji,
    Duration duration = const Duration(seconds: 3),
    String? action,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (emoji != null) ...[
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: action != null
            ? SnackBarAction(
                label: action,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onAction?.call();
                },
              )
            : null,
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(context, message: message, emoji: '✅');
  }

  static void error(BuildContext context, String message) {
    show(context,
        message: message, emoji: '❌', duration: const Duration(seconds: 4));
  }

  static void info(BuildContext context, String message) {
    show(context, message: message, emoji: '🤔');
  }
}

/// Feature spotlight/coach mark
class FeatureSpotlight extends StatelessWidget {
  final Widget child;
  final String title;
  final String description;
  final bool isVisible;
  final VoidCallback? onDismiss;

  const FeatureSpotlight({
    super.key,
    required this.child,
    required this.title,
    required this.description,
    this.isVisible = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (isVisible)
          Positioned(
            top: -80,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onDismiss,
                        child: const Icon(Icons.close,
                            color: Colors.white70, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.2, end: 0),
          ),
      ],
    );
  }
}

/// Gesture guide overlay
class GestureGuideOverlay extends StatelessWidget {
  final List<GestureHint> gestures;
  final VoidCallback? onDismiss;

  const GestureGuideOverlay({
    super.key,
    required this.gestures,
    this.onDismiss,
  });

  static void show(BuildContext context, List<GestureHint> gestures) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => GestureGuideOverlay(
        gestures: gestures,
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Gesture Guide',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          ...gestures.asMap().entries.map((entry) {
            final gesture = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(gesture.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gesture.gesture,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        gesture.action,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              )
                  .animate(delay: Duration(milliseconds: entry.key * 100))
                  .fadeIn()
                  .slideX(begin: 0.2, end: 0),
            );
          }),
          const SizedBox(height: 24),
          TextButton(
            onPressed: onDismiss,
            child: const Text(
              'Got it!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GestureHint {
  final String gesture;
  final String action;
  final String emoji;

  const GestureHint({
    required this.gesture,
    required this.action,
    required this.emoji,
  });
}

/// Contextual tip widget
class ContextualTip extends StatelessWidget {
  final String message;
  final String? emoji;
  final VoidCallback? onDismiss;

  const ContextualTip({
    super.key,
    required this.message,
    this.emoji,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Text(emoji ?? '💡', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade800,
              ),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, size: 18, color: Colors.blue.shade400),
            ),
        ],
      ),
    );
  }
}
