import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// Base shimmer effect for skeleton loading
class ShimmerEffect extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor = const Color(0xFFE8E8E8),
    this.highlightColor = const Color(0xFFF5F5F5),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: duration,
          color: highlightColor,
        );
  }
}

/// Skeleton for ingredient cards
class IngredientCardSkeleton extends StatelessWidget {
  final double size;
  final double borderRadius;

  const IngredientCardSkeleton({
    super.key,
    this.size = 80,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: size * 0.5,
              height: size * 0.5,
              decoration: BoxDecoration(
                color: AppColors.divider.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: size * 0.6,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.divider.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for action cards
class ActionCardSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ActionCardSkeleton({
    super.key,
    this.width = 200,
    this.height = 80,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.divider.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.divider.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.divider.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for timeline steps
class TimelineStepSkeleton extends StatelessWidget {
  final double size;
  final bool showConnector;

  const TimelineStepSkeleton({
    super.key,
    this.size = 48,
    this.showConnector = true,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  color: AppColors.divider,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 40,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.divider.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          if (showConnector)
            Container(
              width: 32,
              height: 2,
              margin: const EdgeInsets.only(bottom: 12),
              color: AppColors.divider.withValues(alpha: 0.5),
            ),
        ],
      ),
    );
  }
}

/// Skeleton for recipe cards
class RecipeCardSkeleton extends StatelessWidget {
  final double width;
  final double aspectRatio;
  final double borderRadius;

  const RecipeCardSkeleton({
    super.key,
    this.width = 280,
    this.aspectRatio = 1.5,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        width: width,
        height: width / aspectRatio,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.divider.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(borderRadius),
                    topRight: Radius.circular(borderRadius),
                  ),
                ),
              ),
            ),
            // Content placeholder
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.divider.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.divider.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.divider.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 60,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.divider.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid of ingredient skeletons
class IngredientGridSkeleton extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double spacing;

  const IngredientGridSkeleton({
    super.key,
    this.itemCount = 8,
    this.crossAxisCount = 4,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const IngredientCardSkeleton()
            .animate(delay: Duration(milliseconds: index * 50))
            .fadeIn();
      },
    );
  }
}

/// List of action skeletons
class ActionListSkeleton extends StatelessWidget {
  final int itemCount;
  final double spacing;

  const ActionListSkeleton({
    super.key,
    this.itemCount = 4,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: spacing),
      itemBuilder: (context, index) {
        return const ActionCardSkeleton()
            .animate(delay: Duration(milliseconds: index * 80))
            .fadeIn()
            .slideX(begin: 0.1, end: 0);
      },
    );
  }
}

/// Timeline skeleton
class TimelineSkeleton extends StatelessWidget {
  final int stepCount;

  const TimelineSkeleton({
    super.key,
    this.stepCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(stepCount, (index) {
          return TimelineStepSkeleton(
            showConnector: index < stepCount - 1,
          ).animate(delay: Duration(milliseconds: index * 100)).fadeIn();
        }),
      ),
    );
  }
}

/// Full composer screen skeleton
class ComposerScreenSkeleton extends StatelessWidget {
  const ComposerScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header skeleton
        Container(
          padding: const EdgeInsets.all(16),
          child: const Row(
            children: [
              _SkeletonBox(width: 40, height: 40, radius: 12),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: 150, height: 16, radius: 8),
                    SizedBox(height: 6),
                    _SkeletonBox(width: 100, height: 12, radius: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const Divider(height: 1),
        
        // Timeline skeleton
        const SizedBox(height: 16),
        const SizedBox(
          height: 80,
          child: TimelineSkeleton(stepCount: 4),
        ),
        
        const SizedBox(height: 24),
        
        // Ingredients section
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(width: 120, height: 14, radius: 7),
              SizedBox(height: 12),
              IngredientGridSkeleton(itemCount: 6, crossAxisCount: 3),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Actions section
        const Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: 100, height: 14, radius: 7),
                SizedBox(height: 12),
                Expanded(child: ActionListSkeleton(itemCount: 3)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Animated skeleton that builds up content
class AnimatedSkeletonLoader extends StatefulWidget {
  final Widget skeleton;
  final Widget content;
  final bool isLoading;
  final Duration transitionDuration;

  const AnimatedSkeletonLoader({
    super.key,
    required this.skeleton,
    required this.content,
    required this.isLoading,
    this.transitionDuration = const Duration(milliseconds: 400),
  });

  @override
  State<AnimatedSkeletonLoader> createState() => _AnimatedSkeletonLoaderState();
}

class _AnimatedSkeletonLoaderState extends State<AnimatedSkeletonLoader> {
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: widget.transitionDuration,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: widget.isLoading
          ? KeyedSubtree(
              key: const ValueKey('skeleton'),
              child: widget.skeleton,
            )
          : KeyedSubtree(
              key: const ValueKey('content'),
              child: widget.content,
            ),
    );
  }
}

