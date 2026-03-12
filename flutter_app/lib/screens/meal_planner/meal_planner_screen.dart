import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/meal_plan_model.dart';
import '../../providers/meal_plan_provider.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDayIndex = DateTime.now().weekday - 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      body: Consumer<MealPlanProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(context, scheme, provider),
              SliverToBoxAdapter(
                  child: _buildWeekStrip(context, scheme, provider)),
              SliverToBoxAdapter(
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Meal Plan'),
                    Tab(text: 'Grocery List'),
                  ],
                  labelColor: scheme.primary,
                  unselectedLabelColor: scheme.onSurfaceVariant,
                  indicatorColor: scheme.primary,
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMealPlanTab(context, scheme, provider),
                    _buildGroceryTab(context, scheme, provider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMealSheet(context),
        icon: const Icon(Iconsax.add),
        label: const Text('Add Meal'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
    );
  }

  Widget _buildAppBar(
      BuildContext context, ColorScheme scheme, MealPlanProvider provider) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: scheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Meal Planner',
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
          icon: const Icon(Iconsax.calendar_1),
          onPressed: () => _selectDate(context, provider),
          tooltip: 'Pick date',
        ),
        IconButton(
          icon: const Icon(Iconsax.shopping_cart),
          onPressed: () {
            _tabController.animateTo(1);
            provider.generateGroceryListFromWeek();
          },
          tooltip: 'Generate grocery list',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildWeekStrip(
      BuildContext context, ColorScheme scheme, MealPlanProvider provider) {
    final weekStart = provider.focusedWeekStart;
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Iconsax.arrow_left_2, size: 20),
                  onPressed: () => provider.navigateWeek(-1),
                ),
                Text(
                  '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekStart.add(const Duration(days: 6)))}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Iconsax.arrow_right_3, size: 20),
                  onPressed: () => provider.navigateWeek(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 7,
              itemBuilder: (context, index) {
                final day = days[index];
                final isSelected = index == _selectedDayIndex;
                final isToday = day.isAtSameMomentAs(today);

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedDayIndex = index);
                    provider.selectDay(day);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? scheme.primary
                          : isToday
                              ? scheme.primary.withValues(alpha: 0.1)
                              : scheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: isToday && !isSelected
                          ? Border.all(color: scheme.primary, width: 1.5)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayNames[index],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? scheme.onPrimary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? scheme.onPrimary
                                : scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.2);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPlanTab(
      BuildContext context, ColorScheme scheme, MealPlanProvider provider) {
    final weekStart = provider.focusedWeekStart;
    final selectedDate = weekStart.add(Duration(days: _selectedDayIndex));
    final plan = provider.currentWeekPlan;

    DayPlan? dayPlan;
    if (plan != null) {
      dayPlan = plan.days.cast<DayPlan?>().firstWhere(
            (d) => d!.date.isAtSameMomentAs(DateTime(
                selectedDate.year, selectedDate.month, selectedDate.day)),
            orElse: () => null,
          );
    }

    final meals = dayPlan?.meals ?? [];

    if (meals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🍽️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'No meals planned',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add a meal for this day',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ).animate().fadeIn(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: MealSlot.values.length,
      itemBuilder: (context, index) {
        final slot = MealSlot.values[index];
        final slotMeals = meals.where((m) => m.slot == slot).toList();

        if (slotMeals.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(slot.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    slot.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            ...slotMeals.map((meal) =>
                _buildMealCard(context, scheme, provider, selectedDate, meal)),
            const SizedBox(height: 8),
          ],
        ).animate(delay: (index * 80).ms).fadeIn().slideY(begin: 0.1);
      },
    );
  }

  Widget _buildMealCard(BuildContext context, ColorScheme scheme,
      MealPlanProvider provider, DateTime date, PlannedMeal meal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: meal.isCooked
              ? AppColors.success.withValues(alpha: 0.15)
              : scheme.primary.withValues(alpha: 0.1),
          child: Icon(
            meal.isCooked ? Iconsax.tick_circle5 : Iconsax.reserve,
            color: meal.isCooked ? AppColors.success : scheme.primary,
          ),
        ),
        title: Text(
          meal.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: meal.isCooked ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          children: [
            if (meal.estimatedCalories > 0) ...[
              Icon(Iconsax.flash_1, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('${meal.estimatedCalories} cal'),
              const SizedBox(width: 12),
            ],
            if (meal.prepTimeMinutes > 0) ...[
              Icon(Iconsax.clock, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('${meal.prepTimeMinutes} min'),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                meal.isCooked ? Iconsax.tick_circle5 : Iconsax.tick_circle,
                color:
                    meal.isCooked ? AppColors.success : scheme.onSurfaceVariant,
              ),
              onPressed: () => provider.toggleMealCooked(date, meal.id),
            ),
            IconButton(
              icon: Icon(Iconsax.trash, color: scheme.error, size: 20),
              onPressed: () => provider.removeMealFromDay(date, meal.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroceryTab(
      BuildContext context, ColorScheme scheme, MealPlanProvider provider) {
    final lists = provider.groceryLists;

    if (lists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🛒', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'No grocery lists yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate one from your meal plan',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => provider.generateGroceryListFromWeek(),
              icon: const Icon(Iconsax.add),
              label: const Text('Generate List'),
            ),
          ],
        ).animate().fadeIn(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      list.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    Text(
                      '${list.items.length} items',
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
                if (list.items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: list.progress,
                      backgroundColor: scheme.surfaceContainerHighest,
                      color: AppColors.success,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${list.purchasedCount}/${list.items.length} purchased',
                    style:
                        TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ).animate(delay: (index * 60).ms).fadeIn().slideY(begin: 0.1);
      },
    );
  }

  Future<void> _selectDate(
      BuildContext context, MealPlanProvider provider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDayIndex = picked.weekday - 1;
      });
      provider.selectDay(picked);
    }
  }

  void _showAddMealSheet(BuildContext context) {
    final titleController = TextEditingController();
    final caloriesController = TextEditingController();
    final timeController = TextEditingController();
    MealSlot selectedSlot = MealSlot.lunch;
    final scheme = Theme.of(context).colorScheme;
    final provider = context.read<MealPlanProvider>();
    final weekStart = provider.focusedWeekStart;
    final selectedDate = weekStart.add(Duration(days: _selectedDayIndex));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
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
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Add Meal',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Meal name',
                      hintText: 'e.g., Grilled Chicken Salad',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Iconsax.reserve),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<MealSlot>(
                    value: selectedSlot,
                    decoration: InputDecoration(
                      labelText: 'Meal slot',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Iconsax.calendar_1),
                    ),
                    items: MealSlot.values.map((slot) {
                      return DropdownMenuItem(
                          value: slot,
                          child: Text('${slot.emoji} ${slot.label}'));
                    }).toList(),
                    onChanged: (v) => setSheetState(() => selectedSlot = v!),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: caloriesController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Calories',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Iconsax.flash_1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: timeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Prep (min)',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Iconsax.clock),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () {
                        if (titleController.text.isEmpty) return;
                        final meal = PlannedMeal(
                          id: const Uuid().v4(),
                          title: titleController.text,
                          slot: selectedSlot,
                          estimatedCalories:
                              int.tryParse(caloriesController.text) ?? 0,
                          prepTimeMinutes:
                              int.tryParse(timeController.text) ?? 0,
                        );
                        provider.addMealToDay(selectedDate, meal);
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Add Meal',
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
