import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/decider_provider.dart';

class WheelSettingsScreen extends StatefulWidget {
  const WheelSettingsScreen({super.key});

  @override
  State<WheelSettingsScreen> createState() => _WheelSettingsScreenState();
}

class _WheelSettingsScreenState extends State<WheelSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCuisineId;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Wheel'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => context.pop(),
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(Iconsax.more),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Iconsax.refresh, size: 20),
                    SizedBox(width: 12),
                    Text('Clear Wheel'),
                  ],
                ),
                onTap: () => _showResetDialog(),
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Iconsax.trash, size: 20, color: AppColors.error),
                    SizedBox(width: 12),
                    Text('Clear History',
                        style: TextStyle(color: AppColors.error)),
                  ],
                ),
                onTap: () => _showClearHistoryDialog(),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Cuisines'),
            Tab(text: 'History'),
            Tab(text: 'Favorites'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: Consumer<DeciderProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildCuisinesTab(provider),
              _buildHistoryTab(provider),
              _buildFavoritesTab(provider),
            ],
          );
        },
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddCuisineDialog(),
              icon: const Icon(Iconsax.add),
              label: const Text('Add Cuisine'),
              backgroundColor: AppColors.primary,
            ).animate().scale(delay: 200.ms)
          : null,
    );
  }

  Widget _buildCuisinesTab(DeciderProvider provider) {
    return _selectedCuisineId != null
        ? _buildDishesView(provider)
        : _buildCuisinesView(provider);
  }

  Widget _buildCuisinesView(DeciderProvider provider) {
    if (provider.cuisines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Iconsax.note_remove,
                size: 56,
                color: AppColors.textLight,
              ),
              const SizedBox(height: 16),
              Text(
                'Your wheel is empty',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add cuisines and dishes you actually want to choose from.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.cuisines.length,
      onReorder: (oldIndex, newIndex) {
        provider.reorderCuisines(oldIndex, newIndex);
        HapticFeedback.lightImpact();
      },
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(16),
              child: child,
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final cuisine = provider.cuisines[index];
        return KeyedSubtree(
          key: ValueKey(cuisine.id),
          child: _buildCuisineCard(cuisine, provider, index),
        );
      },
    );
  }

  Widget _buildCuisineCard(
      CuisineCategory cuisine, DeciderProvider provider, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedCuisineId = cuisine.id),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Drag handle
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Iconsax.menu,
                      color: AppColors.textLight,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Emoji
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(cuisine.emoji,
                        style: const TextStyle(fontSize: 24)),
                  ),
                ),

                const SizedBox(width: 16),

                // Name and dish count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            cuisine.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          if (cuisine.isCustom) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Custom',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${cuisine.dishes.length} dishes',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Iconsax.edit, size: 20),
                      color: AppColors.textSecondary,
                      onPressed: () => _showEditCuisineDialog(cuisine),
                    ),
                    if (cuisine.isCustom)
                      IconButton(
                        icon: const Icon(Iconsax.trash, size: 20),
                        color: AppColors.error,
                        onPressed: () => _showDeleteCuisineDialog(cuisine),
                      ),
                    const Icon(Iconsax.arrow_right_3,
                        color: AppColors.textLight, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildDishesView(DeciderProvider provider) {
    if (provider.cuisines.isEmpty) {
      return _buildCuisinesView(provider);
    }

    final cuisine = provider.cuisines.firstWhere(
      (c) => c.id == _selectedCuisineId,
      orElse: () => provider.cuisines.first,
    );

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.primary.withValues(alpha: 0.1),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Iconsax.arrow_left),
                onPressed: () => setState(() => _selectedCuisineId = null),
              ),
              Text(cuisine.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cuisine.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '${cuisine.dishes.length} dishes',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Iconsax.add_circle),
                color: AppColors.primary,
                onPressed: () => _showAddDishDialog(cuisine),
              ),
            ],
          ),
        ),

        // Dishes list
        Expanded(
          child: cuisine.dishes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconsax.note_remove,
                          size: 64, color: AppColors.textLight),
                      const SizedBox(height: 16),
                      const Text(
                        'No dishes yet',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _showAddDishDialog(cuisine),
                        icon: const Icon(Iconsax.add),
                        label: const Text('Add a dish'),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cuisine.dishes.length,
                  onReorder: (oldIndex, newIndex) {
                    provider.reorderDishes(cuisine.id, oldIndex, newIndex);
                    HapticFeedback.lightImpact();
                  },
                  itemBuilder: (context, index) {
                    final dish = cuisine.dishes[index];
                    final isFavorite = provider.favoriteDishes.contains(dish);

                    return Container(
                      key: ValueKey('${cuisine.id}_$dish'),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Iconsax.menu,
                              color: AppColors.textLight),
                        ),
                        title: Text(dish,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isFavorite ? Iconsax.heart5 : Iconsax.heart,
                                color: isFavorite
                                    ? AppColors.error
                                    : AppColors.textLight,
                              ),
                              onPressed: () => provider.toggleFavorite(dish),
                            ),
                            IconButton(
                              icon: const Icon(Iconsax.edit, size: 20),
                              color: AppColors.textSecondary,
                              onPressed: () =>
                                  _showEditDishDialog(cuisine, index, dish),
                            ),
                            IconButton(
                              icon: const Icon(Iconsax.trash, size: 20),
                              color: AppColors.error,
                              onPressed: () =>
                                  _showDeleteDishDialog(cuisine, dish),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab(DeciderProvider provider) {
    if (provider.spinHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.clock, size: 64, color: AppColors.textLight),
            SizedBox(height: 16),
            Text(
              'No spin history yet',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start spinning to see your history!',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.spinHistory.length,
      itemBuilder: (context, index) {
        final spin = provider.spinHistory[index];
        final timestamp = DateTime.parse(spin['timestamp']);
        final timeAgo = _formatTimeAgo(timestamp);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(spin['cuisineEmoji'],
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            title: Text(
              spin['dish'],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${spin['cuisineName']} • $timeAgo',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            trailing: IconButton(
              icon: Icon(
                provider.favoriteDishes.contains(spin['dish'])
                    ? Iconsax.heart5
                    : Iconsax.heart,
                color: provider.favoriteDishes.contains(spin['dish'])
                    ? AppColors.error
                    : AppColors.textLight,
              ),
              onPressed: () => provider.toggleFavorite(spin['dish']),
            ),
          ),
        ).animate().fadeIn(delay: (30 * index).ms);
      },
    );
  }

  Widget _buildFavoritesTab(DeciderProvider provider) {
    if (provider.favoriteDishes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.heart, size: 64, color: AppColors.textLight),
            SizedBox(height: 16),
            Text(
              'No favorites yet',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the heart icon to save dishes',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.favoriteDishes.length,
      itemBuilder: (context, index) {
        final dish = provider.favoriteDishes[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Iconsax.heart5, color: AppColors.error),
            ),
            title:
                Text(dish, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: IconButton(
              icon: const Icon(Iconsax.trash, color: AppColors.error),
              onPressed: () => provider.toggleFavorite(dish),
            ),
          ),
        ).animate().fadeIn(delay: (30 * index).ms);
      },
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.month}/${timestamp.day}';
  }

  // Dialogs
  void _showAddCuisineDialog() {
    final nameController = TextEditingController();
    String selectedEmoji = '🥗';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Add Cuisine'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji selector
              Wrap(
                spacing: 8,
                children: [
                  '🥗',
                  '🍜',
                  '🍕',
                  '🍔',
                  '🍣',
                  '🌮',
                  '🍱',
                  '🍛',
                  '🥘',
                  '🍝'
                ].map((emoji) {
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedEmoji = emoji),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selectedEmoji == emoji
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: selectedEmoji == emoji
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: Center(
                          child: Text(emoji,
                              style: const TextStyle(fontSize: 24))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Cuisine Name',
                  hintText: 'e.g., Vietnamese',
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  context.read<DeciderProvider>().addCuisine(
                        name: nameController.text.trim(),
                        emoji: selectedEmoji,
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCuisineDialog(CuisineCategory cuisine) {
    final nameController = TextEditingController(text: cuisine.name);
    String selectedEmoji = cuisine.emoji;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Edit Cuisine'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                children: {
                  '🥗',
                  '🍜',
                  '🍕',
                  '🍔',
                  '🍣',
                  '🌮',
                  '🍱',
                  '🍛',
                  '🥘',
                  '🍝',
                  cuisine.emoji
                }.map((emoji) {
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedEmoji = emoji),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selectedEmoji == emoji
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: selectedEmoji == emoji
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: Center(
                          child: Text(emoji,
                              style: const TextStyle(fontSize: 24))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Cuisine Name'),
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  context.read<DeciderProvider>().updateCuisine(
                        cuisine.copyWith(
                          name: nameController.text.trim(),
                          emoji: selectedEmoji,
                          isCustom: true,
                        ),
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteCuisineDialog(CuisineCategory cuisine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Cuisine'),
        content: Text('Delete "${cuisine.name}" and all its dishes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DeciderProvider>().deleteCuisine(cuisine.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddDishDialog(CuisineCategory cuisine) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Add Dish to ${cuisine.name}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Dish Name',
            hintText: 'e.g., Pad Thai',
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context
                    .read<DeciderProvider>()
                    .addDish(cuisine.id, controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDishDialog(CuisineCategory cuisine, int index, String dish) {
    final controller = TextEditingController(text: dish);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit Dish'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Dish Name'),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<DeciderProvider>().updateDish(
                      cuisine.id,
                      index,
                      controller.text.trim(),
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDishDialog(CuisineCategory cuisine, String dish) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Dish'),
        content: Text('Delete "$dish" from ${cuisine.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DeciderProvider>().deleteDish(cuisine.id, dish);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Clear Wheel'),
        content: const Text(
            'This will remove all saved cuisines from the wheel. You can add them back manually at any time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DeciderProvider>().resetToDefaults();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Clear History'),
        content: const Text(
            'This will remove all spin history. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DeciderProvider>().clearHistory();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
