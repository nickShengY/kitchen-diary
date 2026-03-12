class KitchenImagePaths {
  static const String _base = 'assets/kitchen_images';

  static String ingredient(String ingredientId) =>
      '$_base/ingredients/$ingredientId.png';

  static String ingredientState(String ingredientId, String stateSuffix) =>
      '$_base/ingredient_states/$ingredientId$stateSuffix.png';

  static String action(String animationKey) =>
      '$_base/actions/$animationKey.png';

  static String tool(String animationKey) => '$_base/tools/$animationKey.png';

  static String block(String blockId) => '$_base/blocks/$blockId.png';

  static String cuisine(String cuisineId) => '$_base/cuisines/$cuisineId.png';

  static String transition(String filename) =>
      '$_base/transitions/$filename.png';

  static String spriteAction(String filename) =>
      '$_base/sprites/actions/$filename.png';

  static String spriteIngredient(String filename) =>
      '$_base/sprites/ingredients/$filename.png';
}
