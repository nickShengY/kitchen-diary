import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';

class ShareRecipeScreen extends StatefulWidget {
  final String recipeId;
  final String recipeTitle;
  final String? recipeImageUrl;

  const ShareRecipeScreen({
    super.key,
    required this.recipeId,
    required this.recipeTitle,
    this.recipeImageUrl,
  });

  @override
  State<ShareRecipeScreen> createState() => _ShareRecipeScreenState();
}

class _ShareRecipeScreenState extends State<ShareRecipeScreen> {
  int _selectedStyle = 0;

  final _cardStyles = [
    {'name': 'Classic', 'gradient': AppColors.primaryGradient},
    {'name': 'Ocean', 'gradient': AppColors.accentGradient},
    {'name': 'Premium', 'gradient': AppColors.premiumGradient},
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Share Recipe', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: scheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview card
            _buildShareCard(scheme).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 24),

            // Style selector
            Text('Card Style', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: scheme.onSurface)),
            const SizedBox(height: 12),
            Row(
              children: List.generate(_cardStyles.length, (index) {
                final style = _cardStyles[index];
                final isSelected = _selectedStyle == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedStyle = index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: style['gradient'] as LinearGradient,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: (style['gradient'] as LinearGradient).colors.first.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ] : null,
                      ),
                      child: Center(
                        child: Text(
                          style['name'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // Share options
            Text('Share via', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: scheme.onSurface)),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _shareOption(scheme, 'Copy Link', Iconsax.link, AppColors.primary, () {
                  Clipboard.setData(ClipboardData(text: 'https://kitchendiary.app/recipe/${widget.recipeId}'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Link copied! 🔗'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }),
                _shareOption(scheme, 'Message', Iconsax.message, AppColors.accent, () => _shareText()),
                _shareOption(scheme, 'Social', Iconsax.share, AppColors.secondary, () => _shareText()),
                _shareOption(scheme, 'More', Iconsax.more, scheme.onSurfaceVariant, () => _shareText()),
              ],
            ),

            const SizedBox(height: 32),

            // Quick share button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () => _shareText(),
                icon: const Icon(Iconsax.share),
                label: const Text('Share Recipe', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareCard(ColorScheme scheme) {
    final gradient = _cardStyles[_selectedStyle]['gradient'] as LinearGradient;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // App logo area
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Text('🍳', style: TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 8),
              Text(
                'Kitchen Diary',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recipe title
          const Text('🍽️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            widget.recipeTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // QR/deep link hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Tap to view recipe in Kitchen Diary',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shareOption(ColorScheme scheme, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  void _shareText() {
    Share.share(
      'Check out this recipe: ${widget.recipeTitle}\nhttps://kitchendiary.app/recipe/${widget.recipeId}',
      subject: widget.recipeTitle,
    );
  }
}
