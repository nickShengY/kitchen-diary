import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/pantry_model.dart';

class PantryProvider extends ChangeNotifier {
  static const String _boxName = 'pantry_data';
  static const String _itemsKey = 'pantry_items';

  List<PantryItem> _items = [];
  PantryCategory? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = true;
  String _sortBy = 'expiry';

  List<PantryItem> get items => _filteredItems;
  List<PantryItem> get allItems => _items;
  PantryCategory? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String get sortBy => _sortBy;

  List<PantryItem> get _filteredItems {
    var filtered = List<PantryItem>.from(_items);

    if (_selectedCategory != null) {
      filtered =
          filtered.where((item) => item.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (item) =>
                item.name.toLowerCase().contains(query) ||
                (item.brand?.toLowerCase().contains(query) ?? false),
          )
          .toList();
    }

    switch (_sortBy) {
      case 'expiry':
        filtered.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
        break;
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'category':
        filtered.sort((a, b) => a.category.index.compareTo(b.category.index));
        break;
      case 'recent':
        filtered.sort(
          (a, b) => (b.purchaseDate ?? DateTime(2000))
              .compareTo(a.purchaseDate ?? DateTime(2000)),
        );
        break;
    }

    return filtered;
  }

  List<PantryItem> get expiringItems => _items
      .where((item) => item.freshnessStatus == FreshnessStatus.expiringSoon)
      .toList();

  List<PantryItem> get expiredItems => _items
      .where((item) => item.freshnessStatus == FreshnessStatus.expired)
      .toList();

  List<PantryItem> get stapleItems =>
      _items.where((item) => item.isStaple).toList();

  Map<PantryCategory, int> get categoryCount {
    final counts = <PantryCategory, int>{};
    for (final item in _items) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    return counts;
  }

  int get totalItems => _items.length;
  int get expiringCount => expiringItems.length;
  int get expiredCount => expiredItems.length;

  PantryProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    try {
      final box = await Hive.openBox(_boxName);
      final itemsJson = box.get(_itemsKey);
      if (itemsJson != null) {
        final List<dynamic> decoded = jsonDecode(itemsJson);
        _items = decoded.map((entry) => PantryItem.fromJson(entry)).toList();
      } else {
        _items = [];
        await _save();
      }
    } catch (e) {
      debugPrint('Error loading pantry data: $e');
      _items = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(
        _itemsKey,
        jsonEncode(_items.map((item) => item.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Error saving pantry data: $e');
    }
  }

  void setCategory(PantryCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  Future<void> addItem(PantryItem item) async {
    _items.add(item);
    await _save();
    notifyListeners();
  }

  Future<void> updateItem(PantryItem item) async {
    final index = _items.indexWhere((existing) => existing.id == item.id);
    if (index != -1) {
      _items[index] = item;
      await _save();
      notifyListeners();
    }
  }

  Future<void> removeItem(String id) async {
    _items.removeWhere((item) => item.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> useItem(String id, double amount) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final item = _items[index];
    final newQuantity = item.quantity - amount;
    if (newQuantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index] = item.copyWith(quantity: newQuantity);
    }

    await _save();
    notifyListeners();
  }

  List<String> get availableIngredientNames =>
      _items.map((item) => item.name.toLowerCase()).toList();
}
