enum MealSlot {
  breakfast,
  morningSnack,
  lunch,
  afternoonSnack,
  dinner,
  eveningSnack
}

extension MealSlotExt on MealSlot {
  String get label {
    switch (this) {
      case MealSlot.breakfast:
        return 'Breakfast';
      case MealSlot.morningSnack:
        return 'Morning Snack';
      case MealSlot.lunch:
        return 'Lunch';
      case MealSlot.afternoonSnack:
        return 'Afternoon Snack';
      case MealSlot.dinner:
        return 'Dinner';
      case MealSlot.eveningSnack:
        return 'Evening Snack';
    }
  }

  String get emoji {
    switch (this) {
      case MealSlot.breakfast:
        return '🌅';
      case MealSlot.morningSnack:
        return '🍎';
      case MealSlot.lunch:
        return '☀️';
      case MealSlot.afternoonSnack:
        return '🍪';
      case MealSlot.dinner:
        return '🌙';
      case MealSlot.eveningSnack:
        return '🫖';
    }
  }
}

class PlannedMeal {
  final String id;
  final String? recipeId;
  final String title;
  final String? imageUrl;
  final MealSlot slot;
  final int servings;
  final int estimatedCalories;
  final int prepTimeMinutes;
  final String? notes;
  final bool isCooked;

  const PlannedMeal({
    required this.id,
    this.recipeId,
    required this.title,
    this.imageUrl,
    required this.slot,
    this.servings = 2,
    this.estimatedCalories = 0,
    this.prepTimeMinutes = 0,
    this.notes,
    this.isCooked = false,
  });

  PlannedMeal copyWith({
    String? id,
    String? recipeId,
    String? title,
    String? imageUrl,
    MealSlot? slot,
    int? servings,
    int? estimatedCalories,
    int? prepTimeMinutes,
    String? notes,
    bool? isCooked,
  }) {
    return PlannedMeal(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      slot: slot ?? this.slot,
      servings: servings ?? this.servings,
      estimatedCalories: estimatedCalories ?? this.estimatedCalories,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      notes: notes ?? this.notes,
      isCooked: isCooked ?? this.isCooked,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipeId': recipeId,
        'title': title,
        'imageUrl': imageUrl,
        'slot': slot.name,
        'servings': servings,
        'estimatedCalories': estimatedCalories,
        'prepTimeMinutes': prepTimeMinutes,
        'notes': notes,
        'isCooked': isCooked,
      };

  factory PlannedMeal.fromJson(Map<String, dynamic> json) {
    return PlannedMeal(
      id: json['id'],
      recipeId: json['recipeId'],
      title: json['title'],
      imageUrl: json['imageUrl'],
      slot: MealSlot.values.firstWhere(
        (e) => e.name == json['slot'],
        orElse: () => MealSlot.lunch,
      ),
      servings: json['servings'] ?? 2,
      estimatedCalories: json['estimatedCalories'] ?? 0,
      prepTimeMinutes: json['prepTimeMinutes'] ?? 0,
      notes: json['notes'],
      isCooked: json['isCooked'] ?? false,
    );
  }
}

class DayPlan {
  final DateTime date;
  final List<PlannedMeal> meals;

  const DayPlan({required this.date, this.meals = const []});

  int get totalCalories => meals.fold(0, (sum, m) => sum + m.estimatedCalories);
  int get totalPrepTime => meals.fold(0, (sum, m) => sum + m.prepTimeMinutes);
  int get cookedCount => meals.where((m) => m.isCooked).length;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'meals': meals.map((m) => m.toJson()).toList(),
      };

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    return DayPlan(
      date: DateTime.parse(json['date']),
      meals:
          (json['meals'] as List).map((m) => PlannedMeal.fromJson(m)).toList(),
    );
  }
}

class WeekPlan {
  final String id;
  final DateTime weekStart;
  final List<DayPlan> days;
  final String? theme;

  const WeekPlan({
    required this.id,
    required this.weekStart,
    this.days = const [],
    this.theme,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'weekStart': weekStart.toIso8601String(),
        'days': days.map((d) => d.toJson()).toList(),
        'theme': theme,
      };

  factory WeekPlan.fromJson(Map<String, dynamic> json) {
    return WeekPlan(
      id: json['id'],
      weekStart: DateTime.parse(json['weekStart']),
      days: (json['days'] as List).map((d) => DayPlan.fromJson(d)).toList(),
      theme: json['theme'],
    );
  }
}

enum GroceryItemStatus { needed, inCart, purchased }

class GroceryItem {
  final String id;
  final String name;
  final String? emoji;
  final String amount;
  final String unit;
  final String? category;
  final String? aisle;
  final GroceryItemStatus status;
  final List<String> fromRecipes;
  final bool isCustom;

  const GroceryItem({
    required this.id,
    required this.name,
    this.emoji,
    required this.amount,
    required this.unit,
    this.category,
    this.aisle,
    this.status = GroceryItemStatus.needed,
    this.fromRecipes = const [],
    this.isCustom = false,
  });

  GroceryItem copyWith({
    String? id,
    String? name,
    String? emoji,
    String? amount,
    String? unit,
    String? category,
    String? aisle,
    GroceryItemStatus? status,
    List<String>? fromRecipes,
    bool? isCustom,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      aisle: aisle ?? this.aisle,
      status: status ?? this.status,
      fromRecipes: fromRecipes ?? this.fromRecipes,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'amount': amount,
        'unit': unit,
        'category': category,
        'aisle': aisle,
        'status': status.name,
        'fromRecipes': fromRecipes,
        'isCustom': isCustom,
      };

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      id: json['id'],
      name: json['name'],
      emoji: json['emoji'],
      amount: json['amount'] ?? '',
      unit: json['unit'] ?? '',
      category: json['category'],
      aisle: json['aisle'],
      status: GroceryItemStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GroceryItemStatus.needed,
      ),
      fromRecipes: List<String>.from(json['fromRecipes'] ?? []),
      isCustom: json['isCustom'] ?? false,
    );
  }
}

class GroceryList {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<GroceryItem> items;

  const GroceryList({
    required this.id,
    required this.name,
    required this.createdAt,
    this.items = const [],
  });

  int get neededCount =>
      items.where((i) => i.status == GroceryItemStatus.needed).length;
  int get inCartCount =>
      items.where((i) => i.status == GroceryItemStatus.inCart).length;
  int get purchasedCount =>
      items.where((i) => i.status == GroceryItemStatus.purchased).length;
  double get progress => items.isEmpty ? 0 : purchasedCount / items.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory GroceryList.fromJson(Map<String, dynamic> json) {
    return GroceryList(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      items:
          (json['items'] as List).map((i) => GroceryItem.fromJson(i)).toList(),
    );
  }
}
