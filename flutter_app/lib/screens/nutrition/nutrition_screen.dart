import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_theme.dart';
import '../../models/nutrition_model.dart';
import '../../providers/nutrition_provider.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<NutritionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: true,
                pinned: true,
                backgroundColor: scheme.surface,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Health & Nutrition',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Iconsax.setting_2),
                    onPressed: () => _showGoalsSheet(context, provider),
                    tooltip: 'Nutrition goals',
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SliverToBoxAdapter(child: _buildDailyOverview(scheme, provider)),
              SliverToBoxAdapter(child: _buildMacroBreakdown(scheme, provider)),
              SliverToBoxAdapter(child: _buildWaterTracker(scheme, provider)),
              SliverToBoxAdapter(child: _buildStreakCard(scheme, provider)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text('Achievements',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface)),
                ),
              ),
              _buildAchievements(scheme, provider),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Collections',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface)),
                      IconButton(
                        icon: const Icon(Iconsax.add_circle, size: 22),
                        onPressed: () =>
                            _showCreateCollectionSheet(context, provider),
                      ),
                    ],
                  ),
                ),
              ),
              _buildCollections(scheme, provider),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogMealSheet(context),
        icon: const Icon(Iconsax.add),
        label: const Text('Log Meal'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
    );
  }

  Widget _buildDailyOverview(ColorScheme scheme, NutritionProvider provider) {
    final log = provider.todayLog;
    final goal = provider.goal;
    final consumed = log?.totals.calories ?? 0;
    final remaining = goal.targetCalories - consumed;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Today\'s Calories',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text(
                '${log?.mealsLogged ?? 0} meals logged',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            width: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 140,
                  width: 140,
                  child: CircularProgressIndicator(
                    value: provider.calorieProgress.clamp(0.0, 1.0),
                    strokeWidth: 10,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${consumed.round()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text('kcal consumed',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _calorieStatItem(
                  'Goal', '${goal.targetCalories.round()}', Colors.white),
              Container(width: 1, height: 30, color: Colors.white24),
              _calorieStatItem('Consumed', '${consumed.round()}', Colors.white),
              Container(width: 1, height: 30, color: Colors.white24),
              _calorieStatItem('Remaining', '${remaining.round()}',
                  remaining > 0 ? Colors.white : Colors.redAccent),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _calorieStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.w700)),
        Text(label,
            style:
                TextStyle(color: color.withValues(alpha: 0.7), fontSize: 11)),
      ],
    );
  }

  Widget _buildMacroBreakdown(ColorScheme scheme, NutritionProvider provider) {
    final goal = provider.goal;
    final log = provider.todayLog;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Macros',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface)),
          const SizedBox(height: 16),
          _macroRow('Protein', log?.totals.protein ?? 0, goal.targetProtein,
              AppColors.primary, 'g'),
          const SizedBox(height: 12),
          _macroRow('Carbs', log?.totals.carbs ?? 0, goal.targetCarbs,
              AppColors.accent, 'g'),
          const SizedBox(height: 12),
          _macroRow('Fat', log?.totals.fat ?? 0, goal.targetFat,
              AppColors.secondary, 'g'),
          const SizedBox(height: 12),
          _macroRow('Fiber', log?.totals.fiber ?? 0, goal.targetFiber,
              AppColors.success, 'g'),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05);
  }

  Widget _macroRow(
      String label, double current, double target, Color color, String unit) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('${current.round()} / ${target.round()} $unit',
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withValues(alpha: 0.12),
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildWaterTracker(ColorScheme scheme, NutritionProvider provider) {
    final glasses = (provider.todayWaterMl / 250).floor();
    const totalGlasses = 10; // 2.5L in 250ml glasses

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Water Intake',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface)),
              Text('${provider.todayWaterMl.round()} ml / 2500 ml',
                  style:
                      TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalGlasses, (i) {
              final isFilled = i < glasses;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  provider.addWater(250);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isFilled
                        ? AppColors.info
                        : AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isFilled
                          ? AppColors.info
                          : AppColors.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '💧',
                      style: TextStyle(fontSize: isFilled ? 16 : 12),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Center(
            child: FilledButton.tonal(
              onPressed: () {
                HapticFeedback.lightImpact();
                provider.addWater(250);
              },
              child: const Text('+ Add Glass (250ml)'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildStreakCard(ColorScheme scheme, NutritionProvider provider) {
    final streak = provider.streak;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.premiumGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${streak.currentStreak}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🔥 Cooking Streak',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: scheme.onSurface)),
                const SizedBox(height: 4),
                Text(
                  'Best: ${streak.longestStreak} days · ${streak.totalMealsCooked} meals cooked',
                  style:
                      TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: () => provider.recordCook(),
            child: const Text('Log'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05);
  }

  Widget _buildAchievements(ColorScheme scheme, NutritionProvider provider) {
    final achievements = provider.achievements;

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 140,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final a = achievements[index];
            return Container(
              width: 120,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: a.isUnlocked
                    ? AppColors.premiumGradient.colors.first
                        .withValues(alpha: 0.1)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: a.isUnlocked
                    ? Border.all(
                        color: AppColors.premiumGradient.colors.first
                            .withValues(alpha: 0.3))
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(a.emoji,
                      style: TextStyle(fontSize: a.isUnlocked ? 32 : 24)),
                  const SizedBox(height: 8),
                  Text(
                    a.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: a.isUnlocked
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!a.isUnlocked)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: a.progress,
                        backgroundColor: scheme.surfaceContainerHighest,
                        color: scheme.primary,
                        minHeight: 4,
                      ),
                    )
                  else
                    const Text('✅', style: TextStyle(fontSize: 14)),
                ],
              ),
            ).animate(delay: (index * 60).ms).fadeIn().slideX(begin: 0.2);
          },
        ),
      ),
    );
  }

  Widget _buildCollections(ColorScheme scheme, NutritionProvider provider) {
    final collections = provider.collections;

    if (collections.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text('📚', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text('No collections yet',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text('Create one to organize your recipes',
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final col = collections[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: scheme.primary.withValues(alpha: 0.1),
                  child: Text(col.emoji, style: const TextStyle(fontSize: 20)),
                ),
                title: Text(col.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${col.recipeIds.length} recipes'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (col.isPublic)
                      Icon(Iconsax.global,
                          size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Icon(Iconsax.arrow_right_3,
                        size: 18, color: scheme.onSurfaceVariant),
                  ],
                ),
              ),
            ).animate(delay: (index * 60).ms).fadeIn().slideY(begin: 0.1);
          },
          childCount: collections.length,
        ),
      ),
    );
  }

  void _showGoalsSheet(BuildContext context, NutritionProvider provider) {
    final calCtrl =
        TextEditingController(text: '${provider.goal.targetCalories.round()}');
    final protCtrl =
        TextEditingController(text: '${provider.goal.targetProtein.round()}');
    final carbCtrl =
        TextEditingController(text: '${provider.goal.targetCarbs.round()}');
    final fatCtrl =
        TextEditingController(text: '${provider.goal.targetFat.round()}');
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
              Text('Nutrition Goals',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface)),
              const SizedBox(height: 20),
              _goalField(calCtrl, 'Daily Calories', 'kcal', Iconsax.flash_1),
              const SizedBox(height: 12),
              _goalField(protCtrl, 'Protein', 'g', Iconsax.health),
              const SizedBox(height: 12),
              _goalField(carbCtrl, 'Carbs', 'g', Iconsax.chart_2),
              const SizedBox(height: 12),
              _goalField(fatCtrl, 'Fat', 'g', Iconsax.drop),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    provider.updateGoal(NutritionGoal(
                      targetCalories: double.tryParse(calCtrl.text) ?? 2000,
                      targetProtein: double.tryParse(protCtrl.text) ?? 50,
                      targetCarbs: double.tryParse(carbCtrl.text) ?? 250,
                      targetFat: double.tryParse(fatCtrl.text) ?? 65,
                    ));
                    Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: const Text('Save Goals',
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

  Widget _goalField(
      TextEditingController ctrl, String label, String suffix, IconData icon) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(icon),
      ),
    );
  }

  void _showLogMealSheet(BuildContext context) {
    final calCtrl = TextEditingController();
    final protCtrl = TextEditingController();
    final carbCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
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
              Text('Log Meal Nutrition',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface)),
              const SizedBox(height: 20),
              _goalField(calCtrl, 'Calories', 'kcal', Iconsax.flash_1),
              const SizedBox(height: 12),
              _goalField(protCtrl, 'Protein', 'g', Iconsax.health),
              const SizedBox(height: 12),
              _goalField(carbCtrl, 'Carbs', 'g', Iconsax.chart_2),
              const SizedBox(height: 12),
              _goalField(fatCtrl, 'Fat', 'g', Iconsax.drop),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    final nutrition = NutritionInfo(
                      calories: double.tryParse(calCtrl.text) ?? 0,
                      protein: double.tryParse(protCtrl.text) ?? 0,
                      carbs: double.tryParse(carbCtrl.text) ?? 0,
                      fat: double.tryParse(fatCtrl.text) ?? 0,
                    );
                    context.read<NutritionProvider>().logMeal(nutrition);
                    Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: const Text('Log Meal',
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

  void _showCreateCollectionSheet(
      BuildContext context, NutritionProvider provider) {
    final nameCtrl = TextEditingController();
    String emoji = '📚';
    bool isPublic = false;
    final scheme = Theme.of(context).colorScheme;
    final emojis = [
      '📚',
      '🍳',
      '🥗',
      '🍰',
      '🌮',
      '🍜',
      '🥘',
      '🍕',
      '🧁',
      '❤️',
      '⭐',
      '🌿'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
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
                  Text('New Collection',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Collection name',
                      hintText: 'e.g., Quick Weeknight Dinners',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon:
                          Text(emoji, style: const TextStyle(fontSize: 20)),
                      prefixIconConstraints: const BoxConstraints(minWidth: 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Choose Icon',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: emojis
                        .map((e) => GestureDetector(
                              onTap: () => setSheetState(() => emoji = e),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: emoji == e
                                      ? scheme.primary.withValues(alpha: 0.15)
                                      : scheme.surfaceContainerHighest
                                          .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: emoji == e
                                      ? Border.all(color: scheme.primary)
                                      : null,
                                ),
                                child: Center(
                                    child: Text(e,
                                        style: const TextStyle(fontSize: 22))),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Public collection'),
                    subtitle: const Text('Others can discover and follow'),
                    value: isPublic,
                    onChanged: (v) => setSheetState(() => isPublic = v),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () {
                        if (nameCtrl.text.isEmpty) return;
                        provider.addCollection(RecipeCollection(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameCtrl.text,
                          emoji: emoji,
                          isPublic: isPublic,
                          authorId: 'current_user',
                          createdAt: DateTime.now(),
                        ));
                        Navigator.pop(ctx);
                      },
                      style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: const Text('Create Collection',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
