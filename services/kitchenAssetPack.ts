const lightweightAssets = import.meta.glob(
  '../generated/kitchen_asset_pack_flux2_v1/webp/ingredient_states/*__raw.webp',
  {
    eager: true,
    query: '?url',
    import: 'default',
  },
) as Record<string, string>;

// Action previews are generated locally from the shared character master. They
// load on demand so the complete 45-action library does not inflate first paint.
const actionPreviewAssets = import.meta.glob(
  '../generated/kitchen_asset_pack_v2/animations/actions/action_*.webp',
  {
    query: '?url',
    import: 'default',
  },
) as Record<string, () => Promise<string>>;

const imagegenIngredientAssets = import.meta.glob(
  ['../generated/kitchen_asset_pack_v2/ingredient_states/*.png', '!../generated/kitchen_asset_pack_v2/ingredient_states/*_imagegen_source.png'],
  {
    query: '?url',
    import: 'default',
  },
) as Record<string, () => Promise<string>>;

// Master ingredient sprites are the canonical selection artwork.  Keep these
// separate from state sequences so the picker can always use the generated
// master even where an animated state has not been authored yet.
const imagegenIngredientMasterAssets = import.meta.glob(
  ['../generated/kitchen_asset_pack_v2/ingredient_masters/*.png', '!../generated/kitchen_asset_pack_v2/ingredient_masters/*_imagegen_source.png'],
  {
    query: '?url',
    import: 'default',
  },
) as Record<string, () => Promise<string>>;

const imagegenToolAssets = import.meta.glob(
  ['../generated/kitchen_asset_pack_v2/tools/*.png', '!../generated/kitchen_asset_pack_v2/tools/*_imagegen_source.png'],
  {
    query: '?url',
    import: 'default',
  },
) as Record<string, () => Promise<string>>;

const imagegenDishHeroAssets = import.meta.glob(
  ['../generated/kitchen_asset_pack_v2/dish_heroes/*.png', '!../generated/kitchen_asset_pack_v2/dish_heroes/*_imagegen_source.png'],
  {
    query: '?url',
    import: 'default',
  },
) as Record<string, () => Promise<string>>;

const imagegenMixtureAssets = import.meta.glob(
  ['../generated/kitchen_asset_pack_v2/mixtures/*.png', '!../generated/kitchen_asset_pack_v2/mixtures/*_imagegen_source.png'],
  {
    query: '?url',
    import: 'default',
  },
) as Record<string, () => Promise<string>>;

const imagegenIngredientMotionAssets = import.meta.glob(
  '../generated/kitchen_asset_pack_v2/animations/ingredients/*.webp',
  {
    query: '?url',
    import: 'default',
  },
) as Record<string, () => Promise<string>>;

const imagegenEffectAssets = import.meta.glob(
  ['../generated/kitchen_asset_pack_v2/effects/*.png', '!../generated/kitchen_asset_pack_v2/effects/*_imagegen_source.png'],
  {
    query: '?url',
    import: 'default',
  },
) as Record<string, () => Promise<string>>;

const imagegenFallbackAssets = import.meta.glob(
  ['../generated/kitchen_asset_pack_v2/fallbacks/*.png', '!../generated/kitchen_asset_pack_v2/fallbacks/*_imagegen_source.png'],
  {
    query: '?url',
    import: 'default',
  },
) as Record<string, () => Promise<string>>;

const heavyAssets = (
  import.meta.env.MODE === 'test'
    ? import.meta.glob(
        [
          '../generated/kitchen_asset_pack_v1/png/**/*.png',
          '../generated/kitchen_asset_pack_v1/gif/**/*.gif',
        ],
        {
        eager: true,
        query: '?url',
        import: 'default',
        },
      )
    : import.meta.glob(
        [
          '../generated/kitchen_asset_pack_v1/png/**/*.png',
          '../generated/kitchen_asset_pack_v1/gif/**/*.gif',
        ],
        {
        query: '?url',
        import: 'default',
        },
      )
) as Record<string, string | (() => Promise<string>)>;

export interface KitchenAssetRef {
  path: string;
  url?: string;
  load: () => Promise<string>;
}

export interface IngredientPresentation {
  asset?: KitchenAssetRef;
  isGeneric: boolean;
  label: string;
}

const PACK_ROOTS = [
  '../generated/kitchen_asset_pack_v1/',
  '../generated/kitchen_asset_pack_flux2_v1/',
  '../generated/kitchen_asset_pack_v2/',
];

const resolvedUrlCache = new Map<string, string>();

const createAssetRef = (path: string, loader: string | (() => Promise<string>)): KitchenAssetRef => ({
  path,
  url: typeof loader === 'string' ? loader : undefined,
  load: async () => {
    if (typeof loader === 'string') return loader;

    const cached = resolvedUrlCache.get(path);
    if (cached) return cached;

    const url = await loader();
    resolvedUrlCache.set(path, url);
    return url;
  },
});

const byPackPath = new Map(
  [...Object.entries(lightweightAssets), ...Object.entries(imagegenIngredientAssets), ...Object.entries(imagegenIngredientMasterAssets), ...Object.entries(imagegenToolAssets), ...Object.entries(imagegenDishHeroAssets), ...Object.entries(imagegenMixtureAssets), ...Object.entries(imagegenIngredientMotionAssets), ...Object.entries(imagegenEffectAssets), ...Object.entries(imagegenFallbackAssets), ...Object.entries(actionPreviewAssets), ...Object.entries(heavyAssets)].map(([key, loader]) => {
    const normalizedKey = key.replace(/\\/g, '/');
    const packPath =
      PACK_ROOTS.reduce((path, root) => path.replace(root, ''), normalizedKey);
    return [packPath, createAssetRef(packPath, loader)];
  }),
);

const firstAssetRef = (paths: string[]): KitchenAssetRef | undefined => {
  for (const path of paths) {
    const ref = byPackPath.get(path);
    if (ref) return ref;
  }
  return undefined;
};

const ingredientAliases: Record<string, string> = {
  black_beans: 'black_bean',
  chickpeas: 'chickpea',
  green_beans: 'green_bean',
  lentils: 'lentil',
  noodles: 'noodle',
  soy_sauce: 'soysauce',
};

const toolAliases: Record<string, string> = {
  paring_knife: 'knife',
  measuring_cup: 'bowl',
  colander: 'bowl',
  mortar_pestle: 'bowl',
  saute_pan: 'pan',
  saucepan: 'pot',
  dutch_oven: 'pot',
  air_fryer: 'airfryer',
  food_processor: 'blender',
};

const actionAliases: Record<string, string> = {
  stir_fry: 'stirfry',
  deep_fry: 'fry',
  crush: 'mince',
  saute: 'saute',
};

const actionStateAliases: Record<string, string> = {
  bake: 'baked',
  blend: 'blended',
  boil: 'boiled',
  chop: 'chopped',
  crush: 'minced',
  deep_fry: 'fried',
  dice: 'diced',
  drizzle: 'mixed',
  fry: 'fried',
  garnish: 'garnished',
  grate: 'grated',
  grill: 'grilled',
  marinate: 'marinated',
  mince: 'minced',
  mix: 'mixed',
  peel: 'peeled',
  plate: 'plated',
  roast: 'roasted',
  saute: 'sauteed',
  sear: 'seared',
  simmer: 'simmered',
  slice: 'sliced',
  sprinkle: 'garnished',
  steam: 'steamed',
  stir_fry: 'fried',
  whisk: 'whisked',
};

const cookMethodAliases: Record<string, string> = {
  deep_fried: 'fried',
  stir_fried: 'fried',
  sauteed: 'fried',
  seared: 'fried',
  steamed: 'boiled',
  baked: 'simmered',
  roasted: 'simmered',
  grilled: 'fried',
  marinated: 'simmered',
  mixed: 'simmered',
  drizzled: 'simmered',
  sprinkled: 'simmered',
  plated: 'simmered',
};

const detailAliases: Record<string, string> = {
  olive_oil: 'oil',
  vegetable_oil: 'oil',
  butter: 'oil',
  sesame_oil: 'oil',
  broth: 'water',
  stock: 'water',
  soy_sauce: 'water',
  vinegar: 'water',
  coconut_milk: 'water',
  low_heat: 'temperature',
  medium_heat: 'temperature',
  high_heat: 'temperature',
  crispy: 'temperature',
  tender: 'temperature',
  saucy: 'water',
  garnished: 'oil',
};

const assetRef = (path: string): KitchenAssetRef | undefined => byPackPath.get(path);
const normalizeIngredient = (id: string): string => ingredientAliases[id] ?? id;
const normalizeAction = (id: string): string => actionAliases[id] ?? id;

export const isKitchenAssetRef = (value: unknown): value is KitchenAssetRef =>
  Boolean(
    value &&
      typeof value === 'object' &&
      'load' in value &&
      typeof (value as KitchenAssetRef).load === 'function',
  );

export const resolveKitchenAsset = async (
  asset?: KitchenAssetRef,
): Promise<string | undefined> => asset?.load();

export const kitchenAssetPack = {
  ingredient(id: string): KitchenAssetRef | undefined {
    const assetId = normalizeIngredient(id);
    return firstAssetRef([
      `ingredient_masters/${id}_raw.png`,
      `ingredient_masters/${assetId}_raw.png`,
      `ingredient_states/${id}__raw.png`,
      `ingredient_states/${assetId}__raw.png`,
      `webp/ingredient_states/${id}__raw.webp`,
      `webp/ingredient_states/${assetId}__raw.webp`,
      `png/modular/ingredients/${assetId}.png`,
      `png/ingredient_states/${assetId}.png`,
    ]);
  },

  ingredientPresentation(id: string): IngredientPresentation {
    const asset = this.ingredient(id);
    if (asset) {
      return { asset, isGeneric: false, label: 'Exact ingredient art' };
    }

    // Never map an unknown/custom value to a named ingredient. The generic
    // mixed-result sprite is deliberately labelled by the UI as generic.
    return {
      asset: this.fallback('unknown_mixed_result'),
      isGeneric: true,
      label: 'Generic representation',
    };
  },

  tool(id: string): KitchenAssetRef | undefined {
    const assetId = toolAliases[id] ?? id;
    return firstAssetRef([
      `tools/${id}.png`,
      `tools/${assetId}.png`,
      `png/tools/tool_${assetId}.png`,
    ]);
  },

  action(id: string): KitchenAssetRef | undefined {
    const assetId = normalizeAction(id);
    return assetRef(`png/actions/action_${assetId}.png`);
  },

  dishHero(id: string): KitchenAssetRef | undefined {
    return assetRef(`dish_heroes/${id}.png`);
  },

  mixture(id: string): KitchenAssetRef | undefined {
    return assetRef(`mixtures/${id}.png`);
  },

  effect(id: string): KitchenAssetRef | undefined {
    return assetRef(`effects/${id}.png`);
  },

  fallback(id: string): KitchenAssetRef | undefined {
    return assetRef(`fallbacks/${id}.png`);
  },

  cutShape(id: string): KitchenAssetRef | undefined {
    return assetRef(`png/modular/cut_shapes/cut_${id}.png`);
  },

  cookMethod(id: string): KitchenAssetRef | undefined {
    const assetId = cookMethodAliases[id] ?? id;
    return assetRef(`png/modular/cook_methods/method_${assetId}.png`);
  },

  detail(id: string): KitchenAssetRef | undefined {
    const assetId = detailAliases[id] ?? id;
    return assetRef(`png/modular/detail_chips/detail_${assetId}.png`);
  },

  ingredientState(id: string, state?: string): KitchenAssetRef | undefined {
    const assetId = normalizeIngredient(id);
    if (!state) {
      return firstAssetRef([
        `ingredient_masters/${id}_raw.png`,
        `ingredient_masters/${assetId}_raw.png`,
        `ingredient_states/${id}__raw.png`,
        `ingredient_states/${assetId}__raw.png`,
        `webp/ingredient_states/${id}__raw.webp`,
        `webp/ingredient_states/${assetId}__raw.webp`,
        `png/ingredient_states/${assetId}.png`,
      ]);
    }

    const normalizedState = state.toLowerCase().replace(/\s+/g, '_');
    return firstAssetRef([
      `ingredient_masters/${id}_${normalizedState}.png`,
      `ingredient_masters/${assetId}_${normalizedState}.png`,
      `ingredient_masters/${id}_raw.png`,
      `ingredient_masters/${assetId}_raw.png`,
      `ingredient_states/${id}__${normalizedState}.png`,
      `ingredient_states/${assetId}__${normalizedState}.png`,
      // Newer generated state masters use a readable single-underscore name.
      // Keep the legacy double-underscore candidates above so both packs remain
      // valid while letting the picker resolve every authored state sprite.
      `ingredient_states/${id}_${normalizedState}.png`,
      `ingredient_states/${assetId}_${normalizedState}.png`,
      `ingredient_states/${id}__raw.png`,
      `ingredient_states/${assetId}__raw.png`,
      `png/ingredient_states/${assetId}_${normalizedState}.png`,
      `webp/ingredient_states/${id}__${normalizedState}.webp`,
      `webp/ingredient_states/${assetId}__${normalizedState}.webp`,
      `webp/ingredient_states/${id}__raw.webp`,
      `webp/ingredient_states/${assetId}__raw.webp`,
      `png/ingredient_states/${assetId}.png`,
      `png/modular/ingredients/${assetId}.png`,
    ]);
  },

  actionMotion(id: string): KitchenAssetRef | undefined {
    const assetId = normalizeAction(id);
    return firstAssetRef([
      `animations/actions/action_${assetId}.webp`,
      `gif/actions/action_${assetId}.gif`,
      `gif/sprites/actions/action_${assetId}.gif`,
    ]);
  },

  transitionMotion(ingredientId: string, actionId: string): KitchenAssetRef | undefined {
    const ingredientIdForAsset = normalizeIngredient(ingredientId);
    const actionIdForAsset = normalizeAction(actionId);
    const resultState = actionStateAliases[actionId] ?? actionIdForAsset;

    return firstAssetRef([
      `animations/ingredients/${ingredientIdForAsset}_raw_to_${resultState}.webp`,
      `gif/transitions/${ingredientIdForAsset}_raw_to_${resultState}.gif`,
      `gif/transitions/${ingredientIdForAsset}_chopped_to_${resultState}.gif`,
      `gif/sprites/ingredients/${ingredientIdForAsset}_transform_raw_${resultState}.gif`,
      `gif/actions/action_${actionIdForAsset}.gif`,
      `gif/sprites/actions/action_${actionIdForAsset}.gif`,
    ]);
  },

  blockMotion(id: string): KitchenAssetRef | undefined {
    return assetRef(`gif/blocks/${id}.gif`);
  },

  hasIngredient(id: string): boolean {
    return Boolean(this.ingredient(id));
  },

  coverageForIngredientIds(ids: string[]): { total: number; covered: number; missing: string[] } {
    const uniqueIds = Array.from(new Set(ids));
    const missing = uniqueIds.filter((id) => !this.hasIngredient(id));
    return {
      total: uniqueIds.length,
      covered: uniqueIds.length - missing.length,
      missing,
    };
  },
};
