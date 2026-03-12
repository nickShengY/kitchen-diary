import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/subscription_provider.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shadowColor = theme.shadowColor.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.35 : 0.12,
    );
    final topColor = theme.brightness == Brightness.dark
        ? scheme.surfaceContainerHighest
        : scheme.secondaryContainer.withValues(alpha: 0.55);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              topColor,
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Iconsax.arrow_left),
                      ),
                    ],
                  ),
                ),

                // Crown icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppColors.premiumGradient,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Iconsax.crown5,
                    size: 48,
                    color: Colors.white,
                  ),
                )
                    .animate()
                    .scale(duration: 500.ms, curve: Curves.elasticOut)
                    .then()
                    .shimmer(duration: 2000.ms),

                const SizedBox(height: 24),

                Text(
                  'Upgrade to VIP',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 8),

                Text(
                  'Unlock all premium features',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 32),

                // Features
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _buildFeature(
                        context,
                        icon: Iconsax.scan,
                        title: 'AI Menu Scanner',
                        description: 'Scan any menu and let AI pick for you',
                        delay: 400,
                      ),
                      _buildFeature(
                        context,
                        icon: Iconsax.magic_star,
                        title: 'Premium Animations',
                        description: 'Beautiful animations in recipe builder',
                        delay: 500,
                      ),
                      _buildFeature(
                        context,
                        icon: Iconsax.cpu,
                        title: 'AI Meal Planning',
                        description: 'Get personalized weekly meal plans',
                        delay: 600,
                      ),
                      _buildFeature(
                        context,
                        icon: Iconsax.chart_2,
                        title: 'Advanced Nutrition',
                        description: 'Detailed nutritional analysis',
                        delay: 700,
                      ),
                      _buildFeature(
                        context,
                        icon: Iconsax.book_saved,
                        title: 'Unlimited Recipes',
                        description: 'Save unlimited recipes & collections',
                        delay: 800,
                      ),
                      _buildFeature(
                        context,
                        icon: Iconsax.slash,
                        title: 'No Ads',
                        description: 'Enjoy an ad-free experience',
                        delay: 900,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Pricing cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Consumer<SubscriptionProvider>(
                    builder: (context, provider, _) {
                      return Column(
                        children: [
                          // Monthly
                          _buildPricingCard(
                            context,
                            title: 'Monthly',
                            price: '\$5.99',
                            period: '/month',
                            isPopular: false,
                            onTap: provider.isLoading
                                ? null
                                : () => provider.purchaseMonthly(),
                          ),

                          const SizedBox(height: 16),

                          // Yearly
                          _buildPricingCard(
                            context,
                            title: 'Yearly',
                            price: '\$49.99',
                            period: '/year',
                            isPopular: true,
                            savings: 'Save 30%',
                            onTap: provider.isLoading
                                ? null
                                : () => provider.purchaseYearly(),
                          ),

                          const SizedBox(height: 24),

                          // Restore purchases
                          TextButton(
                            onPressed: provider.isLoading
                                ? null
                                : () => provider.restorePurchases(),
                            child: const Text('Restore Purchases'),
                          ),

                          // Error message
                          if (provider.errorMessage != null)
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: scheme.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: scheme.error.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                provider.errorMessage!,
                                style:
                                    TextStyle(color: scheme.onErrorContainer),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          // Already VIP
                          if (provider.isVip)
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: scheme.primary.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Iconsax.tick_circle,
                                    color: scheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'You are a VIP member!',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: scheme.primary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 24),

                // Terms
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Subscription automatically renews unless cancelled at least 24 hours before the end of the current period. You can manage your subscription in your App Store settings.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              scheme.onSurfaceVariant.withValues(alpha: 0.75),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required int delay,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: scheme.secondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Iconsax.tick_circle5,
            color: scheme.primary,
            size: 20,
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildPricingCard(
    BuildContext context, {
    required String title,
    required String price,
    required String period,
    required bool isPopular,
    String? savings,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shadowColor = theme.shadowColor.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.35 : 0.12,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isPopular
                  ? scheme.secondary
                  : scheme.outline.withValues(alpha: 0.12),
              width: isPopular ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              price,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: scheme.primary,
                                  ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 4, left: 2),
                              child: Text(
                                period,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isPopular ? scheme.secondary : scheme.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Iconsax.arrow_right_3,
                      color: scheme.onPrimary,
                    ),
                  ),
                ],
              ),
              if (isPopular && savings != null)
                Positioned(
                  top: -8,
                  right: 60,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppColors.premiumGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      savings,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
