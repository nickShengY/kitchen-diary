enum PantryCategory {
  produce,
  dairy,
  meat,
  seafood,
  grains,
  spices,
  condiments,
  canned,
  frozen,
  beverages,
  snacks,
  baking,
  other,
}

extension PantryCategoryExt on PantryCategory {
  String get label {
    switch (this) {
      case PantryCategory.produce: return 'Produce';
      case PantryCategory.dairy: return 'Dairy';
      case PantryCategory.meat: return 'Meat';
      case PantryCategory.seafood: return 'Seafood';
      case PantryCategory.grains: return 'Grains & Pasta';
      case PantryCategory.spices: return 'Spices & Herbs';
      case PantryCategory.condiments: return 'Condiments';
      case PantryCategory.canned: return 'Canned Goods';
      case PantryCategory.frozen: return 'Frozen';
      case PantryCategory.beverages: return 'Beverages';
      case PantryCategory.snacks: return 'Snacks';
      case PantryCategory.baking: return 'Baking';
      case PantryCategory.other: return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case PantryCategory.produce: return '🥬';
      case PantryCategory.dairy: return '🧀';
      case PantryCategory.meat: return '🥩';
      case PantryCategory.seafood: return '🐟';
      case PantryCategory.grains: return '🌾';
      case PantryCategory.spices: return '🌶️';
      case PantryCategory.condiments: return '🫙';
      case PantryCategory.canned: return '🥫';
      case PantryCategory.frozen: return '🧊';
      case PantryCategory.beverages: return '🥤';
      case PantryCategory.snacks: return '🍿';
      case PantryCategory.baking: return '🧁';
      case PantryCategory.other: return '📦';
    }
  }
}

enum FreshnessStatus { fresh, good, expiringSoon, expired }

class PantryItem {
  final String id;
  final String name;
  final String? emoji;
  final PantryCategory category;
  final double quantity;
  final String unit;
  final DateTime? purchaseDate;
  final DateTime? expiryDate;
  final String? location; // fridge, freezer, pantry shelf, etc.
  final String? brand;
  final String? notes;
  final String? barcode;
  final bool isStaple; // always keep in stock

  const PantryItem({
    required this.id,
    required this.name,
    this.emoji,
    required this.category,
    required this.quantity,
    required this.unit,
    this.purchaseDate,
    this.expiryDate,
    this.location,
    this.brand,
    this.notes,
    this.barcode,
    this.isStaple = false,
  });

  FreshnessStatus get freshnessStatus {
    if (expiryDate == null) return FreshnessStatus.good;
    final now = DateTime.now();
    final daysLeft = expiryDate!.difference(now).inDays;
    if (daysLeft < 0) return FreshnessStatus.expired;
    if (daysLeft <= 3) return FreshnessStatus.expiringSoon;
    if (daysLeft <= 7) return FreshnessStatus.good;
    return FreshnessStatus.fresh;
  }

  int get daysUntilExpiry {
    if (expiryDate == null) return 999;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  PantryItem copyWith({
    String? id,
    String? name,
    String? emoji,
    PantryCategory? category,
    double? quantity,
    String? unit,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    String? location,
    String? brand,
    String? notes,
    String? barcode,
    bool? isStaple,
  }) {
    return PantryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      location: location ?? this.location,
      brand: brand ?? this.brand,
      notes: notes ?? this.notes,
      barcode: barcode ?? this.barcode,
      isStaple: isStaple ?? this.isStaple,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'category': category.name,
    'quantity': quantity,
    'unit': unit,
    'purchaseDate': purchaseDate?.toIso8601String(),
    'expiryDate': expiryDate?.toIso8601String(),
    'location': location,
    'brand': brand,
    'notes': notes,
    'barcode': barcode,
    'isStaple': isStaple,
  };

  factory PantryItem.fromJson(Map<String, dynamic> json) {
    return PantryItem(
      id: json['id'],
      name: json['name'],
      emoji: json['emoji'],
      category: PantryCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => PantryCategory.other,
      ),
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] ?? '',
      purchaseDate: json['purchaseDate'] != null ? DateTime.parse(json['purchaseDate']) : null,
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
      location: json['location'],
      brand: json['brand'],
      notes: json['notes'],
      barcode: json['barcode'],
      isStaple: json['isStaple'] ?? false,
    );
  }
}
