import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// Fun animated loading indicator
class FunLoadingIndicator extends StatefulWidget {
  final String? text;
  final String? emoji;
  final List<String>? frames;

  const FunLoadingIndicator({
    super.key,
    this.text,
    this.emoji,
    this.frames,
  });

  @override
  State<FunLoadingIndicator> createState() => _FunLoadingIndicatorState();
}

class _FunLoadingIndicatorState extends State<FunLoadingIndicator> {
  int _frameIndex = 0;
  Timer? _timer;

  static const _defaultLoadings = [
    {
      'emoji': '🍳',
      'frames': ['🥚', '🍳', '✨'],
      'text': 'Cracking the code...'
    },
    {
      'emoji': '🍲',
      'frames': ['🍲', '🌶️', '💨'],
      'text': 'Simmering ideas...'
    },
    {
      'emoji': '👨‍🍳',
      'frames': ['👨‍🍳', '🔪', '🥗'],
      'text': 'Chef is preparing...'
    },
    {
      'emoji': '🍜',
      'frames': ['🍜', '🔄', '✨'],
      'text': 'Tossing up something good...'
    },
  ];

  late Map<String, dynamic> _currentLoading;

  @override
  void initState() {
    super.initState();
    _currentLoading =
        _defaultLoadings[math.Random().nextInt(_defaultLoadings.length)];
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() {
        _frameIndex = (_frameIndex + 1) %
            (widget.frames ?? _currentLoading['frames'] as List).length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frames = widget.frames ?? _currentLoading['frames'] as List<String>;
    final text = widget.text ?? _currentLoading['text'] as String;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          frames[_frameIndex],
          style: const TextStyle(fontSize: 64),
        ).animate(onPlay: (c) => c.repeat()).scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1.1, 1.1),
            duration: 500.ms),
        const SizedBox(height: 16),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ).animate().fadeIn(),
      ],
    );
  }
}

/// Floating food particles background
class FloatingFoodParticles extends StatefulWidget {
  final List<String> particles;
  final int count;
  final Widget child;

  const FloatingFoodParticles({
    super.key,
    this.particles = const ['🍕', '🍔', '🥬', '🍓', '🧀', '🍇', '🍎'],
    this.count = 15,
    required this.child,
  });

  @override
  State<FloatingFoodParticles> createState() => _FloatingFoodParticlesState();
}

class _FloatingFoodParticlesState extends State<FloatingFoodParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    final random = math.Random();
    _particles = List.generate(widget.count, (index) {
      return _Particle(
        emoji: widget.particles[random.nextInt(widget.particles.length)],
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 16 + random.nextDouble() * 16,
        speed: 0.5 + random.nextDouble() * 0.5,
        wobble: random.nextDouble() * 2 * math.pi,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _controller.value,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Particle {
  final String emoji;
  final double x;
  final double y;
  final double size;
  final double speed;
  final double wobble;

  _Particle({
    required this.emoji,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.wobble,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final particle in particles) {
      final y = (particle.y + progress * particle.speed) % 1.0;
      final x = particle.x +
          math.sin(progress * 2 * math.pi + particle.wobble) * 0.02;

      textPainter.text = TextSpan(
        text: particle.emoji,
        style: TextStyle(fontSize: particle.size),
      );
      textPainter.layout();

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(math.sin(progress * 4 * math.pi + particle.wobble) * 0.3);

      // Paint object would be used if drawing shapes instead of text
      textPainter.paint(canvas, Offset(-particle.size / 2, -particle.size / 2));

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      progress != oldDelegate.progress;
}

/// Shake to discover animation
class ShakeToDiscover extends StatefulWidget {
  final Widget child;
  final VoidCallback? onShake;
  final bool enabled;

  const ShakeToDiscover({
    super.key,
    required this.child,
    this.onShake,
    this.enabled = true,
  });

  @override
  State<ShakeToDiscover> createState() => _ShakeToDiscoverState();
}

class _ShakeToDiscoverState extends State<ShakeToDiscover>
    with SingleTickerProviderStateMixin {
  late AnimationController _hintController;
  bool _showHint = true;

  @override
  void initState() {
    super.initState();
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.enabled && _showHint)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _hintController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                        math.sin(_hintController.value * 2 * math.pi) * 10, 0),
                    child: child,
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('📱', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text(
                        'Shake for a surprise!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn().then().fadeOut(delay: 4000.ms),
            ),
          ),
      ],
    );
  }
}

/// Daily spin wheel
class DailySpinWheel extends StatefulWidget {
  final List<SpinPrize> prizes;
  final Function(SpinPrize)? onSpinComplete;

  const DailySpinWheel({
    super.key,
    required this.prizes,
    this.onSpinComplete,
  });

  @override
  State<DailySpinWheel> createState() => _DailySpinWheelState();
}

class _DailySpinWheelState extends State<DailySpinWheel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isSpinning = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spin() {
    if (_isSpinning) return;

    setState(() => _isSpinning = true);
    HapticFeedback.mediumImpact();

    // Weight-based random selection
    final random = math.Random();
    final totalWeight = widget.prizes.fold<int>(0, (sum, p) => sum + p.weight);
    var randomWeight = random.nextInt(totalWeight);

    for (int i = 0; i < widget.prizes.length; i++) {
      randomWeight -= widget.prizes[i].weight;
      if (randomWeight < 0) {
        _selectedIndex = i;
        break;
      }
    }

    final rotations = 5 + random.nextDouble() * 2;
    // Target angle calculation reserved for advanced wheel animation
    final _ = rotations * 2 * math.pi +
        (_selectedIndex / widget.prizes.length) * 2 * math.pi;

    _controller.reset();
    _controller
        .animateTo(
      1.0,
      curve: Curves.easeOutCubic,
    )
        .then((_) {
      setState(() => _isSpinning = false);
      HapticFeedback.heavyImpact();
      widget.onSpinComplete?.call(widget.prizes[_selectedIndex]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pointer
        const Text('⬇️', style: TextStyle(fontSize: 32)),

        const SizedBox(height: 8),

        // Wheel
        SizedBox(
          width: 280,
          height: 280,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final angle = _controller.value * (5 + 2) * 2 * math.pi;
              return Transform.rotate(
                angle: angle,
                child: child,
              );
            },
            child: CustomPaint(
              painter: _WheelPainter(prizes: widget.prizes),
              child: const SizedBox.expand(),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Spin button
        ElevatedButton(
          onPressed: _isSpinning ? null : _spin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isSpinning)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              else
                const Text('🎰', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                _isSpinning ? 'Spinning...' : 'SPIN!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<SpinPrize> prizes;

  _WheelPainter({required this.prizes});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = 2 * math.pi / prizes.length;

    for (int i = 0; i < prizes.length; i++) {
      final paint = Paint()
        ..color = prizes[i].color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweepAngle - math.pi / 2,
        sweepAngle,
        true,
        paint,
      );

      // Draw emoji
      final angle = i * sweepAngle + sweepAngle / 2 - math.pi / 2;
      final emojiOffset = Offset(
        center.dx + radius * 0.6 * math.cos(angle),
        center.dy + radius * 0.6 * math.sin(angle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: prizes[i].emoji,
          style: const TextStyle(fontSize: 28),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        emojiOffset - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    // Center circle
    canvas.drawCircle(
      center,
      20,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      center,
      18,
      Paint()..color = AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(_WheelPainter oldDelegate) => false;
}

class SpinPrize {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final int weight;
  final String value;

  const SpinPrize({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    this.weight = 1,
    required this.value,
  });
}

/// Mystery box unwrap animation
class MysteryBox extends StatefulWidget {
  final String content;
  final String contentEmoji;
  final VoidCallback? onUnwrap;

  const MysteryBox({
    super.key,
    required this.content,
    required this.contentEmoji,
    this.onUnwrap,
  });

  @override
  State<MysteryBox> createState() => _MysteryBoxState();
}

class _MysteryBoxState extends State<MysteryBox> {
  bool _isOpened = false;

  void _open() {
    if (_isOpened) return;
    HapticFeedback.heavyImpact();
    setState(() => _isOpened = true);
    widget.onUnwrap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _open,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _isOpened
            ? _OpenedBox(
                content: widget.content,
                emoji: widget.contentEmoji,
              )
            : _ClosedBox(),
      ),
    );
  }
}

class _ClosedBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade400,
            Colors.purple.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎁', style: TextStyle(fontSize: 48))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 800.ms),
          const SizedBox(height: 8),
          const Text(
            'Tap to open!',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    )
        .animate()
        .shimmer(duration: 2000.ms, color: Colors.white.withValues(alpha: 0.3));
  }
}

class _OpenedBox extends StatelessWidget {
  final String content;
  final String emoji;

  const _OpenedBox({
    required this.content,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 56))
              .animate()
              .scale(begin: const Offset(0, 0), curve: Curves.elasticOut),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }
}

/// Chef joke card
class ChefJokeCard extends StatefulWidget {
  final String setup;
  final String punchline;

  const ChefJokeCard({
    super.key,
    required this.setup,
    required this.punchline,
  });

  @override
  State<ChefJokeCard> createState() => _ChefJokeCardState();
}

class _ChefJokeCardState extends State<ChefJokeCard> {
  bool _showPunchline = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showPunchline = true),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade300, Colors.orange.shade500],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😄', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 12),
            Text(
              widget.setup,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            AnimatedCrossFade(
              firstChild: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Tap for punchline! 👇',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              secondChild: Text(
                widget.punchline,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
              crossFadeState: _showPunchline
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }
}

/// Food personality result card
class FoodPersonalityCard extends StatelessWidget {
  final String name;
  final String emoji;
  final String description;
  final Color color;
  final VoidCallback? onShare;

  const FoodPersonalityCard({
    super.key,
    required this.name,
    required this.emoji,
    required this.description,
    required this.color,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 80))
              .animate()
              .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text(
            name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 24),
          if (onShare != null)
            ElevatedButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share),
              label: const Text('Share Result'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: color,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}
