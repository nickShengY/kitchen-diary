import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:confetti/confetti.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/decider_provider.dart';
import '../../providers/subscription_provider.dart';

class DeciderScreen extends StatefulWidget {
  const DeciderScreen({super.key});

  @override
  State<DeciderScreen> createState() => _DeciderScreenState();
}

class _DeciderScreenState extends State<DeciderScreen>
    with SingleTickerProviderStateMixin {
  String _mode = 'wheel'; // 'wheel' or 'scan'
  String _phase = 'cuisine'; // 'cuisine' or 'dish'

  CuisineCategory? _selectedCuisine;
  String? _selectedDish;

  bool _isSpinning = false;
  double _wheelRotation = 0;

  late AnimationController _spinController;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _spin() {
    if (_isSpinning) return;

    final deciderProvider = context.read<DeciderProvider>();
    final cuisines = deciderProvider.cuisines;

    HapticFeedback.mediumImpact();

    setState(() => _isSpinning = true);

    final items =
        _phase == 'cuisine' ? cuisines : _selectedCuisine?.dishes ?? [];

    if (items.isEmpty) {
      setState(() => _isSpinning = false);
      return;
    }

    final random = Random();
    final selectedIndex = random.nextInt(items.length);
    final spins = 5 + random.nextDouble() * 3;
    final anglePerItem = 360 / items.length;
    final targetRotation = spins * 360 + (selectedIndex * anglePerItem);

    _spinController.reset();

    final animation = Tween<double>(
      begin: _wheelRotation,
      end: _wheelRotation + targetRotation,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutCubic,
    ));

    animation.addListener(() {
      setState(() => _wheelRotation = animation.value);
    });

    _spinController.forward().then((_) {
      setState(() {
        _isSpinning = false;

        if (_phase == 'cuisine') {
          _selectedCuisine = cuisines[selectedIndex];
        } else {
          final dishes = _selectedCuisine!.dishes;
          _selectedDish = dishes[selectedIndex];
          _confettiController.play();

          // Record the spin in history
          deciderProvider.recordSpin(
            cuisineName: _selectedCuisine!.name,
            cuisineEmoji: _selectedCuisine!.emoji,
            dish: _selectedDish!,
          );
        }
      });

      HapticFeedback.heavyImpact();
    });
  }

  void _goToDishPhase() {
    setState(() {
      _phase = 'dish';
      _wheelRotation = 0;
      _selectedDish = null;
    });
  }

  void _reset() {
    setState(() {
      _phase = 'cuisine';
      _selectedCuisine = null;
      _selectedDish = null;
      _wheelRotation = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child:
                      _mode == 'wheel' ? _buildWheelMode() : _buildScanMode(),
                ),
              ],
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              colors: const [
                AppColors.primary,
                AppColors.secondary,
                AppColors.accent,
                Colors.pink,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Decider',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          Row(
            children: [
              // Settings button
              IconButton(
                onPressed: () => context.push('/wheel-settings'),
                icon: const Icon(Iconsax.setting_2),
                tooltip: 'Customize Wheel',
              ),

              const SizedBox(width: 8),

              // Mode toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildModeButton('Wheel', 'wheel', Iconsax.chart),
                    _buildModeButton('Scan', 'scan', Iconsax.scan),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String label, String mode, IconData icon) {
    final isActive = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.textPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : AppColors.textLight,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textLight,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWheelMode() {
    return Column(
      children: [
        // Phase indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPhaseChip('1. Cuisine', _phase == 'cuisine'),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Iconsax.arrow_right_3,
                    size: 16, color: AppColors.textLight),
              ),
              _buildPhaseChip('2. Dish', _phase == 'dish'),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Wheel or Result
        Expanded(
          child: _selectedDish != null
              ? _buildFinalResult()
              : _selectedCuisine != null && _phase == 'cuisine'
                  ? _buildCuisineSelected()
                  : _buildWheel(),
        ),

        // Controls
        _buildControls(),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildPhaseChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : AppColors.textLight,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildWheel() {
    final cuisines = context.watch<DeciderProvider>().cuisines;
    final items = _phase == 'cuisine'
        ? cuisines.map((c) => {'text': c.name, 'icon': c.emoji}).toList()
        : _selectedCuisine?.dishes
                .map((d) => {'text': d, 'icon': '🥗'})
                .toList() ??
            [];

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.note_remove,
                size: 64, color: AppColors.textLight),
            const SizedBox(height: 16),
            const Text('No items to display'),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => context.push('/wheel-settings'),
              icon: const Icon(Iconsax.setting_2),
              label: const Text('Customize Wheel'),
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Wheel
        Transform.rotate(
          angle: _wheelRotation * pi / 180,
          child: SizedBox(
            width: 300,
            height: 300,
            child: CustomPaint(
              painter: WheelPainter(
                items: items,
                colors: [
                  AppColors.primary,
                  AppColors.secondary,
                  AppColors.accent,
                  Colors.pink.shade300,
                  Colors.purple.shade300,
                  Colors.blue.shade300,
                  Colors.green.shade300,
                  Colors.orange.shade300,
                  Colors.teal.shade300,
                  Colors.indigo.shade300,
                ],
              ),
            ),
          ),
        ).animate(target: _isSpinning ? 1 : 0).shake(hz: 2, duration: 500.ms),

        // Center button
        GestureDetector(
          onTap: _spin,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: _isSpinning
                  ? const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    )
                  : const Text(
                      '🎯',
                      style: TextStyle(fontSize: 32),
                    ),
            ),
          ),
        ),

        // Pointer
        Positioned(
          top: 0,
          child: Container(
            width: 0,
            height: 0,
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(width: 15, color: Colors.transparent),
                right: BorderSide(width: 15, color: Colors.transparent),
                bottom: BorderSide(width: 25, color: AppColors.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCuisineSelected() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _selectedCuisine!.emoji,
          style: const TextStyle(fontSize: 80),
        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 16),
        Text(
          _selectedCuisine!.name,
          style: Theme.of(context).textTheme.displaySmall,
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 8),
        Text(
          '${_selectedCuisine!.dishes.length} dishes available',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _goToDishPhase,
          icon: const Icon(Iconsax.arrow_right_3),
          label: const Text('Find a Dish'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildFinalResult() {
    final isFavorite =
        context.watch<DeciderProvider>().favoriteDishes.contains(_selectedDish);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _selectedCuisine!.emoji,
          style: const TextStyle(fontSize: 100),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
              duration: 1000.ms,
            ),

        const SizedBox(height: 16),

        Text(
          _selectedDish!,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms).scale(),

        const SizedBox(height: 4),

        Text(
          _selectedCuisine!.name,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 16),

        // Favorite button
        IconButton(
          onPressed: () =>
              context.read<DeciderProvider>().toggleFavorite(_selectedDish!),
          icon: Icon(
            isFavorite ? Iconsax.heart5 : Iconsax.heart,
            color: isFavorite ? AppColors.error : AppColors.textLight,
            size: 32,
          ),
        ).animate().fadeIn(delay: 350.ms),

        const SizedBox(height: 8),

        Text(
          'Bon Appétit! 🎉',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 2,
              ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (_selectedDish == null &&
              !(_selectedCuisine != null && _phase == 'cuisine'))
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSpinning ? null : _spin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSpinning
                          ? 'Rolling...'
                          : _phase == 'cuisine'
                              ? 'Spin Cuisine'
                              : 'Spin Dish',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Iconsax.refresh,
                      size: 20,
                    )
                        .animate(target: _isSpinning ? 1 : 0)
                        .rotate(duration: 500.ms),
                  ],
                ),
              ),
            ),
          if (_selectedDish != null) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedDish = null;
                        _wheelRotation = 0;
                      });
                      Future.delayed(const Duration(milliseconds: 100), _spin);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Respin Dish'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reset,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('New Cuisine'),
                  ),
                ),
              ],
            ),
          ],
          if (_phase == 'dish' && _selectedDish == null && !_isSpinning)
            TextButton(
              onPressed: _reset,
              child: const Text('← Back to Cuisines'),
            ),
        ],
      ),
    );
  }

  Widget _buildScanMode() {
    final isVip = context.watch<SubscriptionProvider>().isVip;
    final hasAccess = isVip;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              if (hasAccess) {
                context.push('/menu-scanner');
              } else {
                context.push('/subscription');
              }
            },
            child: Container(
              width: double.infinity,
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.textLight.withValues(alpha: 0.3),
                  width: 3,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(32),
                color: Colors.white.withValues(alpha: 0.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Iconsax.camera,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Snap a Menu',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasAccess
                        ? 'AI will pick a random dish for you'
                        : 'VIP feature - Upgrade to unlock',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  if (!hasAccess) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppColors.premiumGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.crown, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'VIP Feature',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
              .animate()
              .fadeIn()
              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
        ],
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> items;
  final List<Color> colors;

  WheelPainter({required this.items, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = 2 * pi / items.length;

    for (int i = 0; i < items.length; i++) {
      final startAngle = i * sweepAngle - pi / 2;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw text
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(startAngle + sweepAngle / 2);

      final textPainter = TextPainter(
        text: TextSpan(
          text: items[i]['icon'] as String,
          style: const TextStyle(fontSize: 24),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(radius * 0.6 - textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
