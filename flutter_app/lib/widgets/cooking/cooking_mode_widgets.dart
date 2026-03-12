import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

/// Cooking mode step display
class CookingStepCard extends StatelessWidget {
  final int stepNumber;
  final int totalSteps;
  final String instruction;
  final String? tip;
  final Duration? duration;
  final List<String>? ingredients;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onStartTimer;

  const CookingStepCard({
    super.key,
    required this.stepNumber,
    required this.totalSteps,
    required this.instruction,
    this.tip,
    this.duration,
    this.ingredients,
    this.onPrevious,
    this.onNext,
    this.onStartTimer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Step $stepNumber of $totalSteps',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              if (duration != null)
                GestureDetector(
                  onTap: onStartTimer,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer,
                            size: 16, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(duration!),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Instruction
          Text(
            instruction,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),

          // Tip
          if (tip != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Ingredients for this step
          if (ingredients != null && ingredients!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'You\'ll need:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ingredients!
                  .map((ing) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          ing,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ))
                  .toList(),
            ),
          ],

          const SizedBox(height: 32),

          // Navigation buttons
          Row(
            children: [
              if (stepNumber > 1)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPrevious,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                )
              else
                const Expanded(child: SizedBox()),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onNext,
                  icon: Icon(stepNumber < totalSteps
                      ? Icons.arrow_forward
                      : Icons.check),
                  label: Text(stepNumber < totalSteps ? 'Next' : 'Done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes} min';
    }
    return '${duration.inSeconds}s';
  }
}

/// Cooking progress indicator
class CookingProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final double height;

  const CookingProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep - 1;

        return Expanded(
          child: Container(
            height: height,
            margin: EdgeInsets.only(right: index < totalSteps - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.primary
                  : (isCurrent
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : AppColors.divider),
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
        );
      }),
    );
  }
}

/// Cooking timer widget
class CookingTimer extends StatefulWidget {
  final Duration duration;
  final String? label;
  final VoidCallback? onComplete;
  final bool autoStart;

  const CookingTimer({
    super.key,
    required this.duration,
    this.label,
    this.onComplete,
    this.autoStart = false,
  });

  @override
  State<CookingTimer> createState() => _CookingTimerState();
}

class _CookingTimerState extends State<CookingTimer> {
  late Duration _remaining;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration;
    if (widget.autoStart) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remaining -= const Duration(seconds: 1);
        if (_remaining.inSeconds <= 0) {
          _timer?.cancel();
          _isRunning = false;
          HapticFeedback.heavyImpact();
          widget.onComplete?.call();
        }
      });
    });
  }

  void _pauseTimer() {
    setState(() => _isRunning = false);
    _timer?.cancel();
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remaining = widget.duration;
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (_remaining.inSeconds / widget.duration.inSeconds);
    final isComplete = _remaining.inSeconds <= 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isComplete ? Colors.green.shade50 : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isComplete ? Colors.green : AppColors.divider,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Timer display
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation(
                    isComplete ? Colors.green : AppColors.primary,
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    _formatTime(_remaining),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isComplete ? Colors.green : AppColors.textPrimary,
                    ),
                  ),
                  if (isComplete)
                    const Text(
                      'Done!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _resetTimer,
                icon: const Icon(Icons.refresh),
                tooltip: 'Reset',
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: isComplete
                    ? null
                    : (_isRunning ? _pauseTimer : _startTimer),
                icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(_isRunning ? 'Pause' : 'Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Quick timer presets
class QuickTimerPresets extends StatelessWidget {
  final List<TimerPreset> presets;
  final Function(TimerPreset)? onSelect;

  const QuickTimerPresets({
    super.key,
    required this.presets,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: presets.map((preset) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect?.call(preset),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(preset.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(
                      preset.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatDuration(preset.duration),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    }
    return '${duration.inMinutes} min';
  }
}

/// Timer preset data
class TimerPreset {
  final String name;
  final Duration duration;
  final String emoji;

  const TimerPreset({
    required this.name,
    required this.duration,
    required this.emoji,
  });
}

/// Voice command indicator
class VoiceCommandIndicator extends StatelessWidget {
  final bool isListening;
  final String? lastCommand;

  const VoiceCommandIndicator({
    super.key,
    required this.isListening,
    this.lastCommand,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isListening ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isListening ? AppColors.primary : AppColors.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isListening ? Icons.mic : Icons.mic_none,
            size: 18,
            color: isListening ? Colors.white : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            isListening ? 'Listening...' : (lastCommand ?? 'Say "Hey Chef"'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isListening ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
