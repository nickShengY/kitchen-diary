class NutritionInfo {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;
  final double? saturatedFat;
  final double? cholesterol;
  final double? vitaminA;
  final double? vitaminC;
  final double? calcium;
  final double? iron;

  const NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
    this.saturatedFat,
    this.cholesterol,
    this.vitaminA,
    this.vitaminC,
    this.calcium,
    this.iron,
  });

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
    'sugar': sugar,
    'sodium': sodium,
    'saturatedFat': saturatedFat,
    'cholesterol': cholesterol,
    'vitaminA': vitaminA,
    'vitaminC': vitaminC,
    'calcium': calcium,
    'iron': iron,
  };

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
      sugar: (json['sugar'] as num?)?.toDouble() ?? 0,
      sodium: (json['sodium'] as num?)?.toDouble() ?? 0,
      saturatedFat: (json['saturatedFat'] as num?)?.toDouble(),
      cholesterol: (json['cholesterol'] as num?)?.toDouble(),
      vitaminA: (json['vitaminA'] as num?)?.toDouble(),
      vitaminC: (json['vitaminC'] as num?)?.toDouble(),
      calcium: (json['calcium'] as num?)?.toDouble(),
      iron: (json['iron'] as num?)?.toDouble(),
    );
  }

  NutritionInfo operator +(NutritionInfo other) {
    return NutritionInfo(
      calories: calories + other.calories,
      protein: protein + other.protein,
      carbs: carbs + other.carbs,
      fat: fat + other.fat,
      fiber: fiber + other.fiber,
      sugar: sugar + other.sugar,
      sodium: sodium + other.sodium,
    );
  }
}

class NutritionGoal {
  final double targetCalories;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;
  final double targetFiber;
  final double targetSodium;

  const NutritionGoal({
    this.targetCalories = 2000,
    this.targetProtein = 50,
    this.targetCarbs = 250,
    this.targetFat = 65,
    this.targetFiber = 25,
    this.targetSodium = 2300,
  });

  Map<String, dynamic> toJson() => {
    'targetCalories': targetCalories,
    'targetProtein': targetProtein,
    'targetCarbs': targetCarbs,
    'targetFat': targetFat,
    'targetFiber': targetFiber,
    'targetSodium': targetSodium,
  };

  factory NutritionGoal.fromJson(Map<String, dynamic> json) {
    return NutritionGoal(
      targetCalories: (json['targetCalories'] as num?)?.toDouble() ?? 2000,
      targetProtein: (json['targetProtein'] as num?)?.toDouble() ?? 50,
      targetCarbs: (json['targetCarbs'] as num?)?.toDouble() ?? 250,
      targetFat: (json['targetFat'] as num?)?.toDouble() ?? 65,
      targetFiber: (json['targetFiber'] as num?)?.toDouble() ?? 25,
      targetSodium: (json['targetSodium'] as num?)?.toDouble() ?? 2300,
    );
  }
}

class DailyNutritionLog {
  final DateTime date;
  final NutritionInfo totals;
  final int mealsLogged;
  final double waterIntakeMl;

  const DailyNutritionLog({
    required this.date,
    required this.totals,
    this.mealsLogged = 0,
    this.waterIntakeMl = 0,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'totals': totals.toJson(),
    'mealsLogged': mealsLogged,
    'waterIntakeMl': waterIntakeMl,
  };

  factory DailyNutritionLog.fromJson(Map<String, dynamic> json) {
    return DailyNutritionLog(
      date: DateTime.parse(json['date']),
      totals: NutritionInfo.fromJson(json['totals']),
      mealsLogged: json['mealsLogged'] ?? 0,
      waterIntakeMl: (json['waterIntakeMl'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CookingStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCookDate;
  final int totalMealsCooked;
  final int totalRecipesCreated;
  final Map<String, int> cuisineBreakdown;

  const CookingStreak({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCookDate,
    this.totalMealsCooked = 0,
    this.totalRecipesCreated = 0,
    this.cuisineBreakdown = const {},
  });

  Map<String, dynamic> toJson() => {
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'lastCookDate': lastCookDate?.toIso8601String(),
    'totalMealsCooked': totalMealsCooked,
    'totalRecipesCreated': totalRecipesCreated,
    'cuisineBreakdown': cuisineBreakdown,
  };

  factory CookingStreak.fromJson(Map<String, dynamic> json) {
    return CookingStreak(
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      lastCookDate: json['lastCookDate'] != null ? DateTime.parse(json['lastCookDate']) : null,
      totalMealsCooked: json['totalMealsCooked'] ?? 0,
      totalRecipesCreated: json['totalRecipesCreated'] ?? 0,
      cuisineBreakdown: Map<String, int>.from(json['cuisineBreakdown'] ?? {}),
    );
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final String category; // cooking, social, streak, exploration
  final int requiredValue;
  final int currentValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    required this.requiredValue,
    this.currentValue = 0,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  double get progress => requiredValue > 0 ? (currentValue / requiredValue).clamp(0.0, 1.0) : 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'emoji': emoji,
    'category': category,
    'requiredValue': requiredValue,
    'currentValue': currentValue,
    'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
  };

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      emoji: json['emoji'],
      category: json['category'],
      requiredValue: json['requiredValue'],
      currentValue: json['currentValue'] ?? 0,
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null ? DateTime.parse(json['unlockedAt']) : null,
    );
  }
}

class RecipeCollection {
  final String id;
  final String name;
  final String? description;
  final String emoji;
  final String? coverImageUrl;
  final List<String> recipeIds;
  final bool isPublic;
  final String authorId;
  final DateTime createdAt;
  final int followersCount;

  const RecipeCollection({
    required this.id,
    required this.name,
    this.description,
    this.emoji = '📚',
    this.coverImageUrl,
    this.recipeIds = const [],
    this.isPublic = false,
    required this.authorId,
    required this.createdAt,
    this.followersCount = 0,
  });

  RecipeCollection copyWith({
    String? id,
    String? name,
    String? description,
    String? emoji,
    String? coverImageUrl,
    List<String>? recipeIds,
    bool? isPublic,
    String? authorId,
    DateTime? createdAt,
    int? followersCount,
  }) {
    return RecipeCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      recipeIds: recipeIds ?? this.recipeIds,
      isPublic: isPublic ?? this.isPublic,
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
      followersCount: followersCount ?? this.followersCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'emoji': emoji,
    'coverImageUrl': coverImageUrl,
    'recipeIds': recipeIds,
    'isPublic': isPublic,
    'authorId': authorId,
    'createdAt': createdAt.toIso8601String(),
    'followersCount': followersCount,
  };

  factory RecipeCollection.fromJson(Map<String, dynamic> json) {
    return RecipeCollection(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      emoji: json['emoji'] ?? '📚',
      coverImageUrl: json['coverImageUrl'],
      recipeIds: List<String>.from(json['recipeIds'] ?? []),
      isPublic: json['isPublic'] ?? false,
      authorId: json['authorId'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      followersCount: json['followersCount'] ?? 0,
    );
  }
}
