import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_theme.dart';

class _TimerItem {
  final String id;
  String label;
  int totalSeconds;
  int remainingSeconds;
  bool isRunning = false;
  Color color;
  Timer? timer;

  _TimerItem({
    required this.id,
    required this.label,
    required this.totalSeconds,
    int? remainingSeconds,
    required this.color,
  }) : remainingSeconds = remainingSeconds ?? totalSeconds;

  double get progress => totalSeconds > 0 ? remainingSeconds / totalSeconds : 0;
  bool get isComplete => remainingSeconds <= 0;

  String get timeDisplay {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class CookingTimerScreen extends StatefulWidget {
  const CookingTimerScreen({super.key});

  @override
  State<CookingTimerScreen> createState() => _CookingTimerScreenState();
}

class _CookingTimerScreenState extends State<CookingTimerScreen>
    with TickerProviderStateMixin {
  final List<_TimerItem> _timers = [];
  final _timerColors = [
    AppColors.primary,
    AppColors.accent,
    AppColors.secondary,
    AppColors.success,
    AppColors.info,
    const Color(0xFF9B59B6),
    const Color(0xFFE74C3C),
    const Color(0xFF1ABC9C),
  ];

  final _presets = [
    {'label': 'Boil Eggs', 'minutes': 10, 'emoji': '🥚'},
    {'label': 'Boil Pasta', 'minutes': 12, 'emoji': '🍝'},
    {'label': 'Steam Rice', 'minutes': 18, 'emoji': '🍚'},
    {'label': 'Bake Chicken', 'minutes': 45, 'emoji': '🍗'},
    {'label': 'Sear Steak', 'minutes': 4, 'emoji': '🥩'},
    {'label': 'Rest Meat', 'minutes': 5, 'emoji': '🔪'},
    {'label': 'Brew Tea', 'minutes': 3, 'emoji': '🫖'},
    {'label': 'Marinate', 'minutes': 30, 'emoji': '🫙'},
    {'label': 'Proof Dough', 'minutes': 60, 'emoji': '🍞'},
    {'label': 'Roast Veggies', 'minutes': 25, 'emoji': '🥕'},
  ];

  @override
  void dispose() {
    for (final t in _timers) {
      t.timer?.cancel();
    }
    super.dispose();
  }

  void _addTimer({String? label, int? minutes}) {
    final colorIdx = _timers.length % _timerColors.length;
    final timer = _TimerItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: label ?? 'Timer ${_timers.length + 1}',
      totalSeconds: (minutes ?? 5) * 60,
      color: _timerColors[colorIdx],
    );
    setState(() => _timers.add(timer));
  }

  void _toggleTimer(_TimerItem item) {
    setState(() {
      if (item.isRunning) {
        item.timer?.cancel();
        item.isRunning = false;
      } else {
        if (item.isComplete) {
          item.remainingSeconds = item.totalSeconds;
        }
        item.isRunning = true;
        item.timer = Timer.periodic(const Duration(seconds: 1), (t) {
          setState(() {
            if (item.remainingSeconds > 0) {
              item.remainingSeconds--;
            } else {
              t.cancel();
              item.isRunning = false;
              HapticFeedback.heavyImpact();
            }
          });
        });
      }
    });
  }

  void _resetTimer(_TimerItem item) {
    item.timer?.cancel();
    setState(() {
      item.remainingSeconds = item.totalSeconds;
      item.isRunning = false;
    });
  }

  void _removeTimer(_TimerItem item) {
    item.timer?.cancel();
    setState(() => _timers.remove(item));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Cooking Timers',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: scheme.surface,
        elevation: 0,
        actions: [
          if (_timers.isNotEmpty)
            TextButton(
              onPressed: () {
                for (final t in _timers) {
                  t.timer?.cancel();
                }
                setState(() => _timers.clear());
              },
              child: const Text('Clear All'),
            ),
        ],
      ),
      body:
          _timers.isEmpty ? _buildEmptyState(scheme) : _buildTimersList(scheme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTimerSheet(context),
        icon: const Icon(Iconsax.add),
        label: const Text('Add Timer'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme scheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text('⏱️', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text(
            'Multi-Step Cooking Timers',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Run multiple timers simultaneously\nfor complex recipes',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 32),
          Text('Quick Presets',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _presets.map((preset) {
              return ActionChip(
                avatar: Text(preset['emoji'] as String,
                    style: const TextStyle(fontSize: 16)),
                label: Text('${preset['label']} (${preset['minutes']}m)'),
                onPressed: () {
                  _addTimer(
                    label: preset['label'] as String,
                    minutes: preset['minutes'] as int,
                  );
                },
                backgroundColor:
                    scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              );
            }).toList(),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildTimersList(ColorScheme scheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _timers.length,
      itemBuilder: (context, index) {
        final timer = _timers[index];
        return _buildTimerCard(scheme, timer, index);
      },
    );
  }

  Widget _buildTimerCard(ColorScheme scheme, _TimerItem timer, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: timer.color.withValues(alpha: timer.isRunning ? 0.15 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: timer.isComplete
            ? Border.all(color: AppColors.success, width: 2)
            : timer.isRunning
                ? Border.all(
                    color: timer.color.withValues(alpha: 0.3), width: 1.5)
                : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color:
                            timer.isComplete ? AppColors.success : timer.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      timer.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Iconsax.close_circle,
                      size: 20, color: scheme.onSurfaceVariant),
                  onPressed: () => _removeTimer(timer),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: timer.progress,
                      strokeWidth: 8,
                      backgroundColor: timer.color.withValues(alpha: 0.1),
                      color: timer.isComplete ? AppColors.success : timer.color,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timer.timeDisplay,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: timer.isComplete
                              ? AppColors.success
                              : scheme.onSurface,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (timer.isComplete)
                        Text('Done!',
                            style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600))
                      else
                        Text(
                          timer.isRunning ? 'Running' : 'Paused',
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  onPressed: () => _resetTimer(timer),
                  icon: const Icon(Iconsax.refresh, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.surfaceContainerHighest,
                    foregroundColor: scheme.onSurface,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 64,
                  height: 64,
                  child: IconButton.filled(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _toggleTimer(timer);
                    },
                    icon: Icon(
                      timer.isRunning ? Iconsax.pause5 : Iconsax.play5,
                      size: 28,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          timer.isComplete ? AppColors.success : timer.color,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton.filled(
                  onPressed: () {
                    setState(() {
                      timer.totalSeconds += 60;
                      timer.remainingSeconds += 60;
                    });
                  },
                  icon: const Icon(Iconsax.add, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.surfaceContainerHighest,
                    foregroundColor: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 80).ms).fadeIn().slideY(begin: 0.1);
  }

  void _showAddTimerSheet(BuildContext context) {
    final labelCtrl = TextEditingController();
    final minutesCtrl = TextEditingController(text: '5');
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: scheme.outline.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('New Timer',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface)),
              const SizedBox(height: 8),
              Text('Quick presets:',
                  style:
                      TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets.take(6).map((p) {
                  return ActionChip(
                    avatar: Text(p['emoji'] as String),
                    label: Text('${p['label']}'),
                    onPressed: () {
                      _addTimer(
                          label: p['label'] as String,
                          minutes: p['minutes'] as int);
                      Navigator.pop(ctx);
                    },
                    backgroundColor:
                        scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('Or custom:',
                  style:
                      TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              TextField(
                controller: labelCtrl,
                decoration: InputDecoration(
                  labelText: 'Timer label',
                  hintText: 'e.g., Boil pasta',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Iconsax.tag),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: minutesCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Minutes',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Iconsax.clock),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    final mins = int.tryParse(minutesCtrl.text) ?? 5;
                    _addTimer(
                      label: labelCtrl.text.isEmpty
                          ? 'Timer ${_timers.length + 1}'
                          : labelCtrl.text,
                      minutes: mins,
                    );
                    Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: const Text('Start Timer',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
