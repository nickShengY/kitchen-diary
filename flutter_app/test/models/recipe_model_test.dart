import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_diary/models/recipe_model.dart';
import 'package:kitchen_diary/models/procedure_model.dart';

void main() {
  group('IngredientCategory', () {
    test('has correct number of values', () {
      expect(IngredientCategory.values.length, 10);
    });
  });

  group('PhysicalProperty', () {
    test('has correct number of values', () {
      expect(PhysicalProperty.values.length, 9);
    });
  });

  group('Ingredient', () {
    test('creation', () {
      const ing = Ingredient(
        id: 'tomato',
        name: 'Tomato',
        emoji: '🍅',
        category: IngredientCategory.vegetable,
        defaultUnit: 'pcs',
        physicalProperties: [
          PhysicalProperty.choppable,
          PhysicalProperty.vegetable
        ],
      );
      expect(ing.id, 'tomato');
      expect(ing.name, 'Tomato');
      expect(ing.category, IngredientCategory.vegetable);
      expect(ing.physicalProperties.length, 2);
    });

    test('toJson/fromJson roundtrip', () {
      const original = Ingredient(
        id: 'chicken',
        name: 'Chicken',
        emoji: '🍗',
        category: IngredientCategory.meat,
        defaultUnit: 'g',
        physicalProperties: [PhysicalProperty.meat, PhysicalProperty.cookable],
      );
      final restored = Ingredient.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.category, original.category);
      expect(restored.defaultUnit, original.defaultUnit);
      expect(restored.physicalProperties.length, 2);
    });

    test('fromJson with invalid category falls back', () {
      final json = {
        'id': 'x',
        'name': 'X',
        'emoji': '❓',
        'category': 'nonexistent',
        'defaultUnit': 'pcs',
        'physicalProperties': ['solid'],
      };
      final ing = Ingredient.fromJson(json);
      expect(ing.category, IngredientCategory.vegetable);
    });

    test('fromJson with invalid physical property falls back', () {
      final json = {
        'id': 'x',
        'name': 'X',
        'emoji': '❓',
        'category': 'meat',
        'defaultUnit': 'g',
        'physicalProperties': ['nonexistent_prop'],
      };
      final ing = Ingredient.fromJson(json);
      expect(ing.physicalProperties.first, PhysicalProperty.solid);
    });
  });

  group('RecipeIngredient', () {
    test('creation', () {
      const ri = RecipeIngredient(
        ingredientId: 'tomato',
        name: 'Tomato',
        emoji: '🍅',
        amount: '2',
        unit: 'pcs',
      );
      expect(ri.ingredientId, 'tomato');
      expect(ri.notes, isNull);
    });

    test('creation with notes', () {
      const ri = RecipeIngredient(
        ingredientId: 'onion',
        name: 'Onion',
        emoji: '🧅',
        amount: '1',
        unit: 'pcs',
        notes: 'Finely diced',
      );
      expect(ri.notes, 'Finely diced');
    });

    test('toJson/fromJson roundtrip', () {
      const original = RecipeIngredient(
        ingredientId: 'garlic',
        name: 'Garlic',
        emoji: '🧄',
        amount: '3',
        unit: 'cloves',
        notes: 'Minced',
      );
      final restored = RecipeIngredient.fromJson(original.toJson());
      expect(restored.ingredientId, original.ingredientId);
      expect(restored.name, original.name);
      expect(restored.amount, original.amount);
      expect(restored.unit, original.unit);
      expect(restored.notes, original.notes);
    });
  });

  group('CookingStep', () {
    const sampleStep = CookingStep(
      id: 'step-1',
      stepNumber: 1,
      station: StationCategory.prep,
      ingredients: [
        RecipeIngredient(
          ingredientId: 'tomato',
          name: 'Tomato',
          emoji: '🍅',
          amount: '2',
          unit: 'pcs',
        ),
      ],
      toolId: 'knife',
      toolName: 'Chef Knife',
      toolIcon: '🔪',
      actionId: 'chop',
      actionName: 'Chop',
      actionEmoji: '🔪',
    );

    test('creation with required fields', () {
      expect(sampleStep.id, 'step-1');
      expect(sampleStep.stepNumber, 1);
      expect(sampleStep.station, StationCategory.prep);
      expect(sampleStep.ingredients.length, 1);
      expect(sampleStep.temperature, isNull);
      expect(sampleStep.duration, isNull);
      expect(sampleStep.waterLevel, isNull);
      expect(sampleStep.notes, isNull);
      expect(sampleStep.imageUrl, isNull);
    });

    test('copyWith preserves unchanged values', () {
      final updated =
          sampleStep.copyWith(temperature: 'High', duration: '10 mins');
      expect(updated.id, 'step-1');
      expect(updated.stepNumber, 1);
      expect(updated.station, StationCategory.prep);
      expect(updated.temperature, 'High');
      expect(updated.duration, '10 mins');
      expect(updated.ingredients.length, 1);
    });

    test('copyWith changes station', () {
      final updated = sampleStep.copyWith(station: StationCategory.cook);
      expect(updated.station, StationCategory.cook);
    });

    test('toJson/fromJson roundtrip', () {
      const original = CookingStep(
        id: 'step-rt',
        stepNumber: 3,
        station: StationCategory.cook,
        ingredients: [
          RecipeIngredient(
            ingredientId: 'pasta',
            name: 'Pasta',
            emoji: '🍝',
            amount: '200',
            unit: 'g',
          ),
        ],
        toolId: 'pot',
        toolName: 'Pot',
        toolIcon: '🍲',
        actionId: 'boil',
        actionName: 'Boil',
        actionEmoji: '♨️',
        temperature: 'High',
        duration: '12 mins',
        notes: 'Al dente',
      );
      final restored = CookingStep.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.stepNumber, original.stepNumber);
      expect(restored.station, original.station);
      expect(restored.ingredients.length, 1);
      expect(restored.toolId, original.toolId);
      expect(restored.temperature, original.temperature);
      expect(restored.duration, original.duration);
      expect(restored.notes, original.notes);
    });

    test('fromJson with invalid station falls back to prep', () {
      final json = {
        'id': 's1',
        'stepNumber': 1,
        'station': 'invalid',
        'ingredients': [],
        'toolId': 't',
        'toolName': 'T',
        'toolIcon': '🔧',
        'actionId': 'a',
        'actionName': 'A',
        'actionEmoji': '🔪',
      };
      final step = CookingStep.fromJson(json);
      expect(step.station, StationCategory.prep);
    });
  });

  group('RecipeDifficulty', () {
    test('values', () {
      expect(RecipeDifficulty.values.length, 4);
      expect(RecipeDifficulty.easy.name, 'easy');
      expect(RecipeDifficulty.medium.name, 'medium');
      expect(RecipeDifficulty.hard.name, 'hard');
      expect(RecipeDifficulty.expert.name, 'expert');
    });
  });

  group('MealType', () {
    test('values', () {
      expect(MealType.values.length, 6);
      expect(MealType.breakfast.name, 'breakfast');
      expect(MealType.lunch.name, 'lunch');
      expect(MealType.dinner.name, 'dinner');
      expect(MealType.snack.name, 'snack');
      expect(MealType.dessert.name, 'dessert');
      expect(MealType.drink.name, 'drink');
    });
  });

  group('RecipeModel', () {
    RecipeModel makeRecipe({
      List<CookingStep> steps = const [],
      RecipeProcedure? procedure,
      int prepTimeMinutes = 10,
      int cookTimeMinutes = 20,
    }) {
      return RecipeModel(
        id: 'r-1',
        title: 'Test Recipe',
        authorId: 'a-1',
        authorName: 'Chef',
        authorAvatar: '👨‍🍳',
        steps: steps,
        procedure: procedure,
        prepTimeMinutes: prepTimeMinutes,
        cookTimeMinutes: cookTimeMinutes,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );
    }

    test('creation with defaults', () {
      final recipe = makeRecipe();
      expect(recipe.description, isNull);
      expect(recipe.tags, isEmpty);
      expect(recipe.imageUrl, isNull);
      expect(recipe.likes, 0);
      expect(recipe.views, 0);
      expect(recipe.commentsCount, 0);
      expect(recipe.servings, 2);
      expect(recipe.difficulty, RecipeDifficulty.medium);
      expect(recipe.mealType, isNull);
      expect(recipe.cuisine, isEmpty);
      expect(recipe.isPublic, true);
      expect(recipe.isFeatured, false);
      expect(recipe.videoUrl, isNull);
      expect(recipe.nutritionInfo, isNull);
      expect(recipe.dietaryTags, isEmpty);
    });

    test('totalTimeMinutes calculates correctly', () {
      final recipe = makeRecipe(prepTimeMinutes: 15, cookTimeMinutes: 25);
      expect(recipe.totalTimeMinutes, 40);
    });

    test('totalTimeMinutes with zero cook time', () {
      final recipe = makeRecipe(prepTimeMinutes: 5, cookTimeMinutes: 0);
      expect(recipe.totalTimeMinutes, 5);
    });

    test('allIngredients returns empty for no steps', () {
      final recipe = makeRecipe();
      expect(recipe.allIngredients, isEmpty);
    });

    test('allIngredients aggregates from steps', () {
      final recipe = makeRecipe(steps: [
        const CookingStep(
          id: 's1',
          stepNumber: 1,
          station: StationCategory.prep,
          ingredients: [
            RecipeIngredient(
                ingredientId: 'tomato',
                name: 'Tomato',
                emoji: '🍅',
                amount: '2',
                unit: 'pcs'),
            RecipeIngredient(
                ingredientId: 'onion',
                name: 'Onion',
                emoji: '🧅',
                amount: '1',
                unit: 'pcs'),
          ],
          toolId: 'knife',
          toolName: 'Knife',
          toolIcon: '🔪',
          actionId: 'chop',
          actionName: 'Chop',
          actionEmoji: '🔪',
        ),
        const CookingStep(
          id: 's2',
          stepNumber: 2,
          station: StationCategory.cook,
          ingredients: [
            RecipeIngredient(
                ingredientId: 'oil',
                name: 'Oil',
                emoji: '🫒',
                amount: '2',
                unit: 'tbsp'),
          ],
          toolId: 'pan',
          toolName: 'Pan',
          toolIcon: '🍳',
          actionId: 'fry',
          actionName: 'Fry',
          actionEmoji: '🍳',
        ),
      ]);
      expect(recipe.allIngredients.length, 3);
    });

    test('displaySteps returns steps when no procedure', () {
      const step = CookingStep(
        id: 's1',
        stepNumber: 1,
        station: StationCategory.prep,
        ingredients: [],
        toolId: 't',
        toolName: 'T',
        toolIcon: '🔧',
        actionId: 'a',
        actionName: 'A',
        actionEmoji: '🔪',
      );
      final recipe = makeRecipe(steps: [step]);
      expect(recipe.displaySteps.length, 1);
      expect(recipe.displaySteps.first.id, 's1');
    });

    test('displaySteps returns steps when procedure is empty', () {
      final recipe = makeRecipe(
        steps: [
          const CookingStep(
            id: 's1',
            stepNumber: 1,
            station: StationCategory.prep,
            ingredients: [],
            toolId: 't',
            toolName: 'T',
            toolIcon: '🔧',
            actionId: 'a',
            actionName: 'A',
            actionEmoji: '🔪',
          ),
        ],
        procedure: RecipeProcedure.empty(),
      );
      expect(recipe.displaySteps.length, 1);
      expect(recipe.displaySteps.first.id, 's1');
    });

    test('displaySteps derives from procedure when available', () {
      final recipe = makeRecipe(
        steps: [], // original steps empty
        procedure: const RecipeProcedure(
          version: '1.0.0',
          lots: [
            MaterialLot(
              id: 'l1',
              ingredientId: 'tomato',
              name: 'Tomato',
              emoji: '🍅',
              amount: '2',
              unit: 'pcs',
              state: 'raw', assetKey: 'tomato_raw',
            ),
          ],
          operations: [
            ProcedureOperation(
              id: 'op1',
              station: ProcedureStation.prep,
              actionId: 'chop',
              actionName: 'Chop',
              actionEmoji: '🔪',
              toolId: 'knife',
              toolName: 'Knife',
              toolIcon: '🔪',
              inputLotIds: ['l1'],
              outputLotIds: ['l2'],
            ),
          ],
        ),
      );
      final display = recipe.displaySteps;
      expect(display.length, 1);
      expect(display.first.actionId, 'chop');
      expect(display.first.stepNumber, 1);
      expect(display.first.ingredients.length, 1);
      expect(display.first.ingredients.first.name, 'Tomato');
    });

    test('displaySteps handles missing lot IDs gracefully', () {
      final recipe = makeRecipe(
        steps: [],
        procedure: const RecipeProcedure(
          version: '1.0.0',
          lots: [],
          operations: [
            ProcedureOperation(
              id: 'op1',
              station: ProcedureStation.cook,
              actionId: 'mix',
              actionName: 'Mix',
              actionEmoji: '🥄',
              inputLotIds: ['nonexistent'],
              outputLotIds: ['out1'],
            ),
          ],
        ),
      );
      final display = recipe.displaySteps;
      expect(display.length, 1);
      expect(display.first.ingredients, isEmpty);
    });

    test('copyWith preserves unchanged values', () {
      final original = makeRecipe();
      final updated = original.copyWith(title: 'Updated Recipe', likes: 42);
      expect(updated.id, 'r-1');
      expect(updated.title, 'Updated Recipe');
      expect(updated.likes, 42);
      expect(updated.authorName, 'Chef');
    });

    test('copyWith changes difficulty and mealType', () {
      final original = makeRecipe();
      final updated = original.copyWith(
        difficulty: RecipeDifficulty.expert,
        mealType: MealType.dessert,
      );
      expect(updated.difficulty, RecipeDifficulty.expert);
      expect(updated.mealType, MealType.dessert);
    });

    test('toFirestore produces correct map', () {
      final recipe = RecipeModel(
        id: 'r-fs',
        title: 'Firestore Recipe',
        description: 'Test description',
        authorId: 'a-1',
        authorName: 'Chef',
        authorAvatar: '👨‍🍳',
        steps: [],
        tags: ['test'],
        likes: 10,
        views: 50,
        servings: 4,
        prepTimeMinutes: 15,
        cookTimeMinutes: 30,
        difficulty: RecipeDifficulty.hard,
        mealType: MealType.dinner,
        cuisine: ['Italian'],
        isPublic: true,
        isFeatured: true,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 6, 1),
        dietaryTags: ['vegetarian'],
      );
      final map = recipe.toFirestore();
      expect(map['title'], 'Firestore Recipe');
      expect(map['description'], 'Test description');
      expect(map['tags'], ['test']);
      expect(map['likes'], 10);
      expect(map['difficulty'], 'hard');
      expect(map['mealType'], 'dinner');
      expect(map['cuisine'], ['Italian']);
      expect(map['isFeatured'], true);
      expect(map['dietaryTags'], ['vegetarian']);
      expect(map['procedure'], isNull);
    });

    test('toFirestore includes procedure when present', () {
      final recipe = RecipeModel(
        id: 'r-proc',
        title: 'Procedure Recipe',
        authorId: 'a-1',
        authorName: 'Chef',
        authorAvatar: '👨‍🍳',
        steps: [],
        procedure: RecipeProcedure.empty(),
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );
      final map = recipe.toFirestore();
      expect(map['procedure'], isNotNull);
      expect(map['procedure']['version'], '1.0.0');
    });
  });
}
