import 'package:cloud_firestore/cloud_firestore.dart';

import 'procedure_model.dart';

// Ingredient categories
enum IngredientCategory {
  vegetable,
  meat,
  dairy,
  spice,
  grain,
  fruit,
  liquid,
  seafood,
  condiment,
  herb,
}

// Physical properties for smart cooking logic
enum PhysicalProperty {
  peelable,
  choppable,
  liquid,
  solid,
  mixable,
  cookable,
  grateable,
  meat,
  vegetable,
}

class Ingredient {
  final String id;
  final String name;
  final String emoji;
  final IngredientCategory category;
  final String defaultUnit;
  final List<PhysicalProperty> physicalProperties;

  const Ingredient({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.defaultUnit,
    required this.physicalProperties,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'category': category.name,
        'defaultUnit': defaultUnit,
        'physicalProperties': physicalProperties.map((p) => p.name).toList(),
      };

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'],
      name: json['name'],
      emoji: json['emoji'],
      category: IngredientCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => IngredientCategory.vegetable,
      ),
      defaultUnit: json['defaultUnit'],
      physicalProperties: (json['physicalProperties'] as List)
          .map((p) => PhysicalProperty.values.firstWhere(
                (e) => e.name == p,
                orElse: () => PhysicalProperty.solid,
              ))
          .toList(),
    );
  }
}

class RecipeIngredient {
  final String ingredientId;
  final String name;
  final String emoji;
  final String amount;
  final String unit;
  final String? notes;

  const RecipeIngredient({
    required this.ingredientId,
    required this.name,
    required this.emoji,
    required this.amount,
    required this.unit,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'ingredientId': ingredientId,
        'name': name,
        'emoji': emoji,
        'amount': amount,
        'unit': unit,
        'notes': notes,
      };

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      ingredientId: json['ingredientId'],
      name: json['name'],
      emoji: json['emoji'],
      amount: json['amount'],
      unit: json['unit'],
      notes: json['notes'],
    );
  }
}

enum StationCategory { prep, cook, finish }

class CookingStep {
  final String id;
  final int stepNumber;
  final StationCategory station;
  final List<RecipeIngredient> ingredients;
  final String toolId;
  final String toolName;
  final String toolIcon;
  final String actionId;
  final String actionName;
  final String actionEmoji;
  final String? temperature;
  final String? duration;
  final String? waterLevel;
  final String? notes;
  final String? imageUrl;

  const CookingStep({
    required this.id,
    required this.stepNumber,
    required this.station,
    required this.ingredients,
    required this.toolId,
    required this.toolName,
    required this.toolIcon,
    required this.actionId,
    required this.actionName,
    required this.actionEmoji,
    this.temperature,
    this.duration,
    this.waterLevel,
    this.notes,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'stepNumber': stepNumber,
        'station': station.name,
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
        'toolId': toolId,
        'toolName': toolName,
        'toolIcon': toolIcon,
        'actionId': actionId,
        'actionName': actionName,
        'actionEmoji': actionEmoji,
        'temperature': temperature,
        'duration': duration,
        'waterLevel': waterLevel,
        'notes': notes,
        'imageUrl': imageUrl,
      };

  factory CookingStep.fromJson(Map<String, dynamic> json) {
    return CookingStep(
      id: json['id'],
      stepNumber: json['stepNumber'],
      station: StationCategory.values.firstWhere(
        (e) => e.name == json['station'],
        orElse: () => StationCategory.prep,
      ),
      ingredients: (json['ingredients'] as List)
          .map((i) => RecipeIngredient.fromJson(i))
          .toList(),
      toolId: json['toolId'],
      toolName: json['toolName'],
      toolIcon: json['toolIcon'],
      actionId: json['actionId'],
      actionName: json['actionName'],
      actionEmoji: json['actionEmoji'],
      temperature: json['temperature'],
      duration: json['duration'],
      waterLevel: json['waterLevel'],
      notes: json['notes'],
      imageUrl: json['imageUrl'],
    );
  }

  CookingStep copyWith({
    String? id,
    int? stepNumber,
    StationCategory? station,
    List<RecipeIngredient>? ingredients,
    String? toolId,
    String? toolName,
    String? toolIcon,
    String? actionId,
    String? actionName,
    String? actionEmoji,
    String? temperature,
    String? duration,
    String? waterLevel,
    String? notes,
    String? imageUrl,
  }) {
    return CookingStep(
      id: id ?? this.id,
      stepNumber: stepNumber ?? this.stepNumber,
      station: station ?? this.station,
      ingredients: ingredients ?? this.ingredients,
      toolId: toolId ?? this.toolId,
      toolName: toolName ?? this.toolName,
      toolIcon: toolIcon ?? this.toolIcon,
      actionId: actionId ?? this.actionId,
      actionName: actionName ?? this.actionName,
      actionEmoji: actionEmoji ?? this.actionEmoji,
      temperature: temperature ?? this.temperature,
      duration: duration ?? this.duration,
      waterLevel: waterLevel ?? this.waterLevel,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

enum RecipeDifficulty { easy, medium, hard, expert }

enum MealType { breakfast, lunch, dinner, snack, dessert, drink }

class RecipeModel {
  final String id;
  final String title;
  final String? description;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String? authorPhotoUrl;
  final List<CookingStep> legacySteps;
  final RecipeProcedure? procedure;
  final List<String> tags;
  final String? imageUrl;
  final List<String> imageUrls;
  final int likes;
  final int views;
  final int commentsCount;
  final int servings;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final RecipeDifficulty difficulty;
  final MealType? mealType;
  final List<String> cuisine;
  final bool isPublic;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? videoUrl;
  final Map<String, dynamic>? nutritionInfo;
  final List<String> dietaryTags; // vegetarian, vegan, gluten-free, etc.

  RecipeModel({
    required this.id,
    required this.title,
    this.description,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    this.authorPhotoUrl,
    required List<CookingStep> steps,
    this.procedure,
    this.tags = const [],
    this.imageUrl,
    this.imageUrls = const [],
    this.likes = 0,
    this.views = 0,
    this.commentsCount = 0,
    this.servings = 2,
    this.prepTimeMinutes = 10,
    this.cookTimeMinutes = 20,
    this.difficulty = RecipeDifficulty.medium,
    this.mealType,
    this.cuisine = const [],
    this.isPublic = true,
    this.isFeatured = false,
    required this.createdAt,
    required this.updatedAt,
    this.videoUrl,
    this.nutritionInfo,
    this.dietaryTags = const [],
  }) : legacySteps = steps;

  int get totalTimeMinutes => prepTimeMinutes + cookTimeMinutes;

  List<CookingStep> get steps => displaySteps;

  List<CookingStep> get storedSteps => List.unmodifiable(legacySteps);

  List<CookingStep> get displaySteps {
    final p = procedure;
    if (p == null || p.operations.isEmpty) {
      return legacySteps;
    }

    final lotsById = <String, MaterialLot>{
      for (final l in p.lots) l.id: l,
    };

    return p.operations.asMap().entries.map((entry) {
      final index = entry.key;
      final op = entry.value;
      final ingredients = op.inputLotIds
          .map((lotId) => lotsById[lotId])
          .whereType<MaterialLot>()
          .map(
            (lot) => RecipeIngredient(
              ingredientId: lot.ingredientId,
              name: lot.name,
              emoji: lot.emoji,
              amount: lot.amount,
              unit: lot.unit,
            ),
          )
          .toList();

      return CookingStep(
        id: op.id,
        stepNumber: index + 1,
        station: StationCategory.values.firstWhere(
          (s) => s.name == op.station.name,
          orElse: () => StationCategory.prep,
        ),
        ingredients: ingredients,
        toolId: op.toolId ?? '',
        toolName: op.toolName ?? '',
        toolIcon: op.toolIcon ?? '',
        actionId: op.actionId,
        actionName: op.actionName,
        actionEmoji: op.actionEmoji,
        temperature: op.temperature,
        duration: op.duration,
        waterLevel: op.waterLevel,
        notes: op.notes,
      );
    }).toList();
  }

  List<RecipeIngredient> get allIngredients {
    final List<RecipeIngredient> all = [];
    for (var step in displaySteps) {
      all.addAll(step.ingredients);
    }
    return all;
  }

  factory RecipeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final rawProcedure = data['procedure'];
    RecipeProcedure? procedure;
    if (rawProcedure is Map) {
      procedure = RecipeProcedure.fromJson(
        Map<String, dynamic>.from(rawProcedure),
      );
    }

    return RecipeModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Chef',
      authorAvatar: data['authorAvatar'] ?? 'chef',
      authorPhotoUrl: data['authorPhotoUrl'],
      steps: (data['steps'] as List? ?? [])
          .map((s) => CookingStep.fromJson(s))
          .toList(),
      procedure: procedure,
      tags: List<String>.from(data['tags'] ?? []),
      imageUrl: data['imageUrl'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      likes: data['likes'] ?? 0,
      views: data['views'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      servings: data['servings'] ?? 2,
      prepTimeMinutes: data['prepTimeMinutes'] ?? 10,
      cookTimeMinutes: data['cookTimeMinutes'] ?? 20,
      difficulty: RecipeDifficulty.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => RecipeDifficulty.medium,
      ),
      mealType: data['mealType'] != null
          ? MealType.values.firstWhere(
              (e) => e.name == data['mealType'],
              orElse: () => MealType.dinner,
            )
          : null,
      cuisine: List<String>.from(data['cuisine'] ?? []),
      isPublic: data['isPublic'] ?? true,
      isFeatured: data['isFeatured'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      videoUrl: data['videoUrl'],
      nutritionInfo: data['nutritionInfo'],
      dietaryTags: List<String>.from(data['dietaryTags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    final data = <String, dynamic>{
      'title': title,
      'description': description,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'authorPhotoUrl': authorPhotoUrl,
      'tags': tags,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'likes': likes,
      'views': views,
      'commentsCount': commentsCount,
      'servings': servings,
      'prepTimeMinutes': prepTimeMinutes,
      'cookTimeMinutes': cookTimeMinutes,
      'difficulty': difficulty.name,
      'mealType': mealType?.name,
      'cuisine': cuisine,
      'isPublic': isPublic,
      'isFeatured': isFeatured,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'videoUrl': videoUrl,
      'nutritionInfo': nutritionInfo,
      'dietaryTags': dietaryTags,
    };

    final canonicalProcedure = procedure;
    if (canonicalProcedure != null) {
      data['procedure'] = canonicalProcedure.toJson();
    } else {
      data['steps'] = legacySteps.map((s) => s.toJson()).toList();
    }

    return data;
  }

  RecipeModel copyWith({
    String? id,
    String? title,
    String? description,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? authorPhotoUrl,
    List<CookingStep>? steps,
    RecipeProcedure? procedure,
    List<String>? tags,
    String? imageUrl,
    List<String>? imageUrls,
    int? likes,
    int? views,
    int? commentsCount,
    int? servings,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    RecipeDifficulty? difficulty,
    MealType? mealType,
    List<String>? cuisine,
    bool? isPublic,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? videoUrl,
    Map<String, dynamic>? nutritionInfo,
    List<String>? dietaryTags,
  }) {
    return RecipeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      steps: steps ?? legacySteps,
      procedure: procedure ?? this.procedure,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      likes: likes ?? this.likes,
      views: views ?? this.views,
      commentsCount: commentsCount ?? this.commentsCount,
      servings: servings ?? this.servings,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      difficulty: difficulty ?? this.difficulty,
      mealType: mealType ?? this.mealType,
      cuisine: cuisine ?? this.cuisine,
      isPublic: isPublic ?? this.isPublic,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      videoUrl: videoUrl ?? this.videoUrl,
      nutritionInfo: nutritionInfo ?? this.nutritionInfo,
      dietaryTags: dietaryTags ?? this.dietaryTags,
    );
  }
}

