import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/pantry_model.dart';
import '../../providers/pantry_provider.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<PantryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(context, scheme, provider),
              SliverToBoxAdapter(child: _buildStatsBar(scheme, provider)),
              SliverToBoxAdapter(
                  child: _buildSearchAndFilter(scheme, provider)),
              SliverToBoxAdapter(child: _buildCategoryChips(scheme, provider)),
              if (provider.expiringItems.isNotEmpty ||
                  provider.expiredItems.isNotEmpty)
                SliverToBoxAdapter(child: _buildAlerts(scheme, provider)),
              _buildItemsList(scheme, provider),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemSheet(context),
        icon: const Icon(Iconsax.add),
        label: const Text('Add Item'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
    );
  }

  Widget _buildAppBar(
      BuildContext context, ColorScheme scheme, PantryProvider provider) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: scheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'My Pantry',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Iconsax.sort),
          onSelected: provider.setSortBy,
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'expiry', child: Text('Sort by Expiry')),
            const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
            const PopupMenuItem(
                value: 'category', child: Text('Sort by Category')),
            const PopupMenuItem(value: 'recent', child: Text('Sort by Recent')),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatsBar(ColorScheme scheme, PantryProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('Total', '${provider.totalItems}', '📦', Colors.white),
          Container(width: 1, height: 40, color: Colors.white24),
          _statItem(
              'Expiring', '${provider.expiringCount}', '⚠️', Colors.white),
          Container(width: 1, height: 40, color: Colors.white24),
          _statItem('Expired', '${provider.expiredCount}', '❌', Colors.white),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _statItem(String label, String value, String emoji, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: color)),
        Text(label,
            style:
                TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8))),
      ],
    );
  }

  Widget _buildSearchAndFilter(ColorScheme scheme, PantryProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: provider.setSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search your pantry...',
          prefixIcon: const Icon(Iconsax.search_normal),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Iconsax.close_circle),
                  onPressed: () {
                    _searchController.clear();
                    provider.setSearchQuery('');
                  },
                )
              : null,
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(ColorScheme scheme, PantryProvider provider) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _categoryChip(scheme, provider, null, 'All', '🏠'),
          ...PantryCategory.values.map(
            (cat) => _categoryChip(scheme, provider, cat, cat.label, cat.emoji),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(ColorScheme scheme, PantryProvider provider,
      PantryCategory? category, String label, String emoji) {
    final isSelected = provider.selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text('$emoji $label'),
        onSelected: (_) {
          HapticFeedback.lightImpact();
          provider.setCategory(isSelected ? null : category);
        },
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        selectedColor: scheme.primary.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: isSelected ? scheme.primary : scheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildAlerts(ColorScheme scheme, PantryProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.warning_2, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Freshness Alerts',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: scheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (provider.expiredItems.isNotEmpty)
            Text(
              '${provider.expiredItems.length} item(s) expired: ${provider.expiredItems.map((i) => i.name).join(", ")}',
              style: TextStyle(fontSize: 13, color: scheme.error),
            ),
          if (provider.expiringItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${provider.expiringItems.length} item(s) expiring soon: ${provider.expiringItems.map((i) => i.name).join(", ")}',
                style: TextStyle(fontSize: 13, color: AppColors.warning),
              ),
            ),
        ],
      ),
    ).animate().fadeIn().shake(delay: 300.ms, hz: 2, curve: Curves.easeOut);
  }

  Widget _buildItemsList(ColorScheme scheme, PantryProvider provider) {
    final items = provider.items;

    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              children: [
                const Text('🧊', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  'Pantry is empty',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add items to track what you have',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            return _buildItemCard(scheme, provider, item, index);
          },
          childCount: items.length,
        ),
      ),
    );
  }

  Widget _buildItemCard(
      ColorScheme scheme, PantryProvider provider, PantryItem item, int index) {
    final statusColor = switch (item.freshnessStatus) {
      FreshnessStatus.fresh => AppColors.success,
      FreshnessStatus.good => AppColors.info,
      FreshnessStatus.expiringSoon => AppColors.warning,
      FreshnessStatus.expired => AppColors.error,
    };

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: scheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Iconsax.trash, color: scheme.error),
      ),
      onDismissed: (_) => provider.removeItem(item.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(item.emoji ?? item.category.emoji,
                  style: const TextStyle(fontSize: 24)),
            ),
          ),
          title: Text(item.name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Row(
            children: [
              Text('${item.quantity} ${item.unit}',
                  style:
                      TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
              if (item.expiryDate != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.daysUntilExpiry < 0
                        ? 'Expired'
                        : item.daysUntilExpiry == 0
                            ? 'Today'
                            : '${item.daysUntilExpiry}d left',
                    style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              if (item.isStaple) ...[
                const SizedBox(width: 6),
                Icon(Iconsax.star5, size: 14, color: AppColors.secondary),
              ],
            ],
          ),
          trailing: item.location != null
              ? Text(item.location!,
                  style:
                      TextStyle(fontSize: 11, color: scheme.onSurfaceVariant))
              : null,
        ),
      ),
    ).animate(delay: (index * 40).ms).fadeIn().slideX(begin: 0.1);
  }

  void _showAddItemSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final unitCtrl = TextEditingController();
    PantryCategory selectedCat = PantryCategory.other;
    String? selectedLocation;
    DateTime? expiryDate;
    bool isStaple = false;
    final scheme = Theme.of(context).colorScheme;

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
                  Text('Add Pantry Item',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Item name',
                      hintText: 'e.g., Chicken Breast',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Iconsax.box_1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: unitCtrl,
                          decoration: InputDecoration(
                            labelText: 'Unit',
                            hintText: 'g, ml, pcs',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<PantryCategory>(
                    value: selectedCat,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: PantryCategory.values
                        .map(
                          (c) => DropdownMenuItem(
                              value: c, child: Text('${c.emoji} ${c.label}')),
                        )
                        .toList(),
                    onChanged: (v) => setSheetState(() => selectedCat = v!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedLocation,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Iconsax.home_2),
                    ),
                    items: ['Fridge', 'Freezer', 'Pantry', 'Counter']
                        .map(
                          (l) => DropdownMenuItem(value: l, child: Text(l)),
                        )
                        .toList(),
                    onChanged: (v) => setSheetState(() => selectedLocation = v),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Iconsax.calendar_1),
                    title: Text(expiryDate != null
                        ? 'Expires: ${DateFormat('MMM d, yyyy').format(expiryDate!)}'
                        : 'Set expiry date'),
                    trailing: const Icon(Iconsax.arrow_right_3, size: 18),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate:
                            DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (picked != null)
                        setSheetState(() => expiryDate = picked);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Always keep in stock'),
                    subtitle: const Text('Mark as a staple item'),
                    value: isStaple,
                    onChanged: (v) => setSheetState(() => isStaple = v),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () {
                        if (nameCtrl.text.isEmpty) return;
                        final item = PantryItem(
                          id: const Uuid().v4(),
                          name: nameCtrl.text,
                          category: selectedCat,
                          quantity: double.tryParse(qtyCtrl.text) ?? 1,
                          unit: unitCtrl.text.isEmpty ? 'pcs' : unitCtrl.text,
                          purchaseDate: DateTime.now(),
                          expiryDate: expiryDate,
                          location: selectedLocation,
                          isStaple: isStaple,
                        );
                        context.read<PantryProvider>().addItem(item);
                        Navigator.pop(ctx);
                      },
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Add to Pantry',
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
