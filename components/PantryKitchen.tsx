import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  Check,
  ChevronDown,
  Clock,
  Dices,
  Heart,
  Lock,
  PlayCircle,
  RefreshCw,
  Search,
  ShoppingBasket,
  Sparkles,
  Unlock,
  Utensils,
  X,
} from 'lucide-react';
import { Category, Ingredient, Recipe } from '../types';
import { INGREDIENTS, TOOLS } from '../data/kitchenData';
import {
  COOKWARE_IDS,
  CORPUS_INGREDIENT_IDS,
  PantryRecipe,
  PANTRY_RECIPES,
  pantryRecipeToRecipe,
} from '../data/pantryRecipes';
import {
  MATCH_MODES,
  MatchMode,
  RecipeMatch,
  buildMenu,
  matchRecipes,
  shoppingListFor,
  suggestStarterPantry,
} from '../services/pantryMatch';
import { EMPTY_PANTRY, PantryState, loadPantry, toggleId, updatePantry, withCooked } from '../services/pantryStore';
import { kitchenAssetPack } from '../services/kitchenAssetPack';
import { PackAsset } from './AssetImage';

interface PantryKitchenProps {
  onCookThis: (recipe: Recipe) => void;
}

const INGREDIENT_BY_ID = new Map(INGREDIENTS.map((item) => [item.id, item]));
const TOOL_BY_ID = new Map(TOOLS.map((item) => [item.id, item]));

const nameOf = (id: string): string => INGREDIENT_BY_ID.get(id)?.name ?? id.replace(/_/g, ' ');
const emojiOf = (id: string): string => INGREDIENT_BY_ID.get(id)?.emoji ?? '🥄';

/** Picker groups, in the order a cook thinks about a fridge. */
const GROUPS: Array<{ id: string; label: string; emoji: string; categories: Category[] }> = [
  { id: 'veg', label: 'Veg', emoji: '🥬', categories: ['vegetable'] },
  { id: 'protein', label: 'Protein', emoji: '🍗', categories: ['meat'] },
  { id: 'sea', label: 'Seafood', emoji: '🦐', categories: ['seafood'] },
  { id: 'dairy', label: 'Dairy & Egg', emoji: '🥚', categories: ['dairy'] },
  { id: 'carb', label: 'Carbs', emoji: '🍚', categories: ['grain'] },
  { id: 'beans', label: 'Beans', emoji: '🫘', categories: ['legume'] },
  { id: 'fruit', label: 'Fruit', emoji: '🍎', categories: ['fruit'] },
  { id: 'flavour', label: 'Flavour', emoji: '🌿', categories: ['herb', 'spice', 'condiment'] },
  { id: 'liquid', label: 'Sauces', emoji: '🫙', categories: ['liquid'] },
];

const COURSE_LABEL: Record<PantryRecipe['course'], string> = {
  main: 'Main',
  side: 'Side',
  soup: 'Soup',
  breakfast: 'Breakfast',
  dessert: 'Dessert',
  snack: 'Snack',
};

const heroAssetFor = (recipe: PantryRecipe) =>
  kitchenAssetPack.dishHero(recipe.id) ??
  kitchenAssetPack.ingredient(recipe.core[0] ?? '') ??
  kitchenAssetPack.ingredient(recipe.core[1] ?? '');

const difficultyLabel = (level: PantryRecipe['difficulty']): string =>
  level === 1 ? 'Easy' : level === 2 ? 'Some skill' : 'Project';

/** Coverage ring — reads faster than a number alone. */
const MatchRing: React.FC<{ coverage: number; ready: boolean }> = ({ coverage, ready }) => {
  const percent = Math.round(coverage * 100);
  return (
    <div
      className="relative flex h-12 w-12 shrink-0 items-center justify-center rounded-full"
      style={{
        background: `conic-gradient(${ready ? '#6EC6CA' : '#FF8E72'} ${percent * 3.6}deg, #FFE7DC 0deg)`,
      }}
    >
      <span className="flex h-9 w-9 items-center justify-center rounded-full bg-white text-[11px] font-bold text-toon-dark">
        {percent}%
      </span>
    </div>
  );
};

const IngredientChip: React.FC<{ id: string; tone: 'have' | 'missing' }> = ({ id, tone }) => (
  <span
    className={`inline-flex items-center gap-1 rounded-full px-2 py-1 text-[10px] font-bold ${
      tone === 'have'
        ? 'bg-emerald-50 text-emerald-700 border border-emerald-100'
        : 'bg-orange-50 text-toon-primary-deep border border-orange-100'
    }`}
  >
    <span aria-hidden="true">{emojiOf(id)}</span>
    {nameOf(id)}
  </span>
);

export const PantryKitchen: React.FC<PantryKitchenProps> = ({ onCookThis }) => {
  const [pantry, setPantryState] = useState(EMPTY_PANTRY);
  const [search, setSearch] = useState('');
  const [group, setGroup] = useState(GROUPS[0].id);
  const [showEverything, setShowEverything] = useState(false);
  const [menu, setMenu] = useState<RecipeMatch[]>([]);
  const [lockedIds, setLockedIds] = useState<string[]>([]);
  const [menuSeed, setMenuSeed] = useState(0);
  const [showShopping, setShowShopping] = useState(false);
  const [detail, setDetail] = useState<RecipeMatch | null>(null);
  const [toast, setToast] = useState<string | null>(null);
  const resultsRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setPantryState(loadPantry());
  }, []);

  /**
   * Writes through to storage before touching React state. "Cook this" navigates
   * away in the same commit, so a save that waited for an effect would be lost
   * when this screen unmounts.
   */
  const setPantry = useCallback((mutate: (state: PantryState) => PantryState) => {
    setPantryState(updatePantry(mutate));
  }, []);

  useEffect(() => {
    if (!toast) return;
    const timer = window.setTimeout(() => setToast(null), 3200);
    return () => window.clearTimeout(timer);
  }, [toast]);

  const matches = useMemo(
    () =>
      matchRecipes({
        pantry: pantry.ingredients,
        cookware: pantry.cookware,
        mode: pantry.mode,
        favorites: pantry.favorites,
        recentlyCooked: pantry.history,
      }),
    [pantry.cookware, pantry.favorites, pantry.history, pantry.ingredients, pantry.mode],
  );

  // Which ingredients would actually unlock something new? Surfacing the top
  // few turns "nothing matched" into a single useful tap.
  const nearMisses = useMemo(() => {
    if (pantry.ingredients.length === 0) return [];
    const owned = new Set(pantry.ingredients);
    const counts = new Map<string, number>();
    PANTRY_RECIPES.forEach((recipe) => {
      const missing = recipe.core.filter((id) => !owned.has(id));
      if (missing.length !== 1) return;
      counts.set(missing[0], (counts.get(missing[0]) ?? 0) + 1);
    });
    return Array.from(counts.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 6)
      .map(([id, count]) => ({ id, count }));
  }, [pantry.ingredients]);

  const pickerIngredients = useMemo(() => {
    const query = search.trim().toLowerCase();
    const activeGroup = GROUPS.find((item) => item.id === group);
    const pool: Ingredient[] = showEverything
      ? INGREDIENTS
      : (CORPUS_INGREDIENT_IDS.map((id) => INGREDIENT_BY_ID.get(id)).filter(Boolean) as Ingredient[]);

    return pool.filter((item) => {
      if (query) return item.name.toLowerCase().includes(query);
      return activeGroup ? activeGroup.categories.includes(item.category) : true;
    });
  }, [group, search, showEverything]);

  const toggleIngredient = useCallback((id: string) => {
    setPantry((current) => ({ ...current, ingredients: toggleId(current.ingredients, id) }));
  }, [setPantry]);

  const toggleCookware = useCallback((id: string) => {
    setPantry((current) => ({ ...current, cookware: toggleId(current.cookware, id) }));
  }, [setPantry]);

  const toggleFavorite = useCallback((id: string) => {
    setPantry((current) => ({ ...current, favorites: toggleId(current.favorites, id) }));
  }, [setPantry]);

  const rollMenu = useCallback(() => {
    const seed = menuSeed + 1;
    setMenuSeed(seed);
    const next = buildMenu({
      pantry: pantry.ingredients,
      cookware: pantry.cookware,
      mode: pantry.mode,
      favorites: pantry.favorites,
      recentlyCooked: pantry.history,
      dishCount: pantry.dishCount,
      locked: lockedIds,
      seed,
    });
    setMenu(next);
    setShowShopping(false);
    if (next.length === 0) setToast('No dishes fit yet — add a few more ingredients.');
  }, [lockedIds, menuSeed, pantry]);

  const cookRecipe = useCallback(
    (recipe: PantryRecipe) => {
      setPantry((current) => ({ ...current, history: withCooked(current.history, recipe.id) }));
      setDetail(null);
      onCookThis(pantryRecipeToRecipe(recipe));
    },
    [onCookThis, setPantry],
  );

  const shoppingList = useMemo(() => shoppingListFor(menu), [menu]);
  const modeInfo = MATCH_MODES.find((item) => item.id === pantry.mode) ?? MATCH_MODES[0];

  const scrollToResults = () => {
    resultsRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  };

  return (
    <div className="min-h-screen pb-32">
      <header className="sticky top-0 z-20 bg-[#FFF5F0]/90 px-4 pb-3 pt-6 backdrop-blur-md shadow-[0_10px_30px_-18px_rgba(74,64,58,0.25)]">
        <div className="flex items-start justify-between gap-3">
          <div className="animate-rise">
            <p className="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-[0.2em] text-toon-primary">
              <span aria-hidden="true" className="toon-twinkle inline-block">✦</span>
              What can I cook?
            </p>
            <h1 className="font-display text-3xl font-semibold leading-tight">
              <span className="text-candy">Kitchen</span>{' '}
              <span aria-hidden="true" className="inline-block animate-bob text-2xl">🧺</span>
            </h1>
          </div>
          <button
            type="button"
            onClick={scrollToResults}
            aria-label={`Jump to ${matches.length} matching ${matches.length === 1 ? 'dish' : 'dishes'}`}
            className="press-springy mt-1 flex min-h-11 items-center gap-1.5 rounded-full border border-orange-100 bg-white px-4 text-sm font-bold text-toon-dark shadow-toon-soft transition-colors hover:border-toon-secondary"
          >
            <Utensils size={16} className="text-toon-primary" aria-hidden="true" />
            <span aria-hidden="true">{matches.length}</span>
            <span aria-hidden="true" className="text-gray-400">dishes</span>
          </button>
        </div>
      </header>

      <div aria-live="polite" className="pointer-events-none fixed inset-x-0 top-4 z-[80] flex justify-center px-4">
        {toast && (
          <p className="animate-pop-in rounded-full border border-orange-100 bg-white/95 px-5 py-2.5 text-sm font-bold text-toon-dark shadow-toon-soft backdrop-blur">
            {toast}
          </p>
        )}
      </div>

      <div className="space-y-6 px-4 pt-4">
        {/* ------------------------------------------------ tonight's menu */}
        <section
          aria-labelledby="menu-heading"
          className="animate-pop-in relative overflow-hidden rounded-3xl bg-gradient-to-br from-toon-secondary via-toon-primary to-toon-primary-deep p-5 text-white shadow-[inset_0_2px_0_rgba(255,255,255,0.35),0_16px_34px_-12px_rgba(242,112,79,0.6)]"
        >
          <span aria-hidden="true" className="toon-sprinkles absolute inset-0 opacity-60" />
          <span aria-hidden="true" className="absolute -right-6 -top-6 h-24 w-24 rounded-full bg-white/10" />

          <div className="relative flex items-start justify-between gap-3">
            <div>
              <h2 id="menu-heading" className="font-display text-xl font-semibold drop-shadow-sm">
                Tonight&apos;s Menu
              </h2>
              <p className="mt-0.5 text-xs font-medium opacity-90">
                Let the kitchen decide what lands on the table.
              </p>
            </div>
            <div className="flex items-center gap-1 rounded-full bg-white/20 p-1 backdrop-blur-sm">
              <button
                type="button"
                aria-label="One fewer dish"
                onClick={() =>
                  setPantry((current) => ({ ...current, dishCount: Math.max(1, current.dishCount - 1) }))
                }
                className="press-springy h-8 w-8 rounded-full text-lg font-bold leading-none text-white hover:bg-white/20"
              >
                −
              </button>
              <span aria-live="polite" className="w-6 text-center font-display text-lg font-semibold">
                {pantry.dishCount}
              </span>
              <button
                type="button"
                aria-label="One more dish"
                onClick={() =>
                  setPantry((current) => ({ ...current, dishCount: Math.min(5, current.dishCount + 1) }))
                }
                className="press-springy h-8 w-8 rounded-full text-lg font-bold leading-none text-white hover:bg-white/20"
              >
                +
              </button>
            </div>
          </div>

          <button
            type="button"
            onClick={rollMenu}
            className="press-springy relative mt-4 flex min-h-11 w-full items-center justify-center gap-2 rounded-2xl bg-white px-5 py-3 font-bold text-toon-primary shadow-[0_4px_0_rgba(180,70,40,0.25)] transition-all hover:-translate-y-0.5"
          >
            <Dices size={18} aria-hidden="true" />
            {menu.length > 0 ? 'Roll a new menu' : 'Roll tonight\'s menu'}
          </button>

          {menu.length > 0 && (
            <ul className="relative mt-4 space-y-2 stagger-children">
              {menu.map((match) => {
                const locked = lockedIds.includes(match.recipe.id);
                return (
                  <li
                    key={match.recipe.id}
                    className="animate-rise flex items-center gap-2 rounded-2xl bg-white/15 p-2 backdrop-blur-sm"
                  >
                    <button
                      type="button"
                      onClick={() => setDetail(match)}
                      className="flex flex-1 items-center gap-2.5 rounded-xl px-1 py-1 text-left"
                    >
                      <span aria-hidden="true" className="text-xl">{match.recipe.emoji}</span>
                      <span className="min-w-0">
                        <span className="block truncate text-sm font-bold">{match.recipe.title}</span>
                        <span className="block text-[10px] font-semibold uppercase tracking-wider opacity-80">
                          {COURSE_LABEL[match.recipe.course]} · {match.recipe.minutes} min
                        </span>
                      </span>
                    </button>
                    <button
                      type="button"
                      aria-label={locked ? `Unpin ${match.recipe.title}` : `Keep ${match.recipe.title} on the next roll`}
                      aria-pressed={locked}
                      onClick={() => setLockedIds((current) => toggleId(current, match.recipe.id))}
                      className="press-springy flex h-11 w-11 items-center justify-center rounded-full text-white/80 transition-colors hover:bg-white/20 hover:text-white"
                    >
                      {locked ? <Lock size={16} /> : <Unlock size={16} />}
                    </button>
                  </li>
                );
              })}
            </ul>
          )}

          {menu.length > 0 && (
            <div className="relative mt-3">
              <button
                type="button"
                aria-expanded={showShopping}
                onClick={() => setShowShopping((current) => !current)}
                className="flex min-h-11 w-full items-center justify-between rounded-2xl bg-white/15 px-4 text-sm font-bold backdrop-blur-sm"
              >
                <span className="flex items-center gap-2">
                  <ShoppingBasket size={16} aria-hidden="true" />
                  Shopping list ({shoppingList.length})
                </span>
                <ChevronDown
                  size={16}
                  aria-hidden="true"
                  className={`transition-transform ${showShopping ? 'rotate-180' : ''}`}
                />
              </button>
              {showShopping && (
                <div className="animate-rise mt-2 rounded-2xl bg-white/95 p-3">
                  {shoppingList.length === 0 ? (
                    <p className="text-center text-sm font-bold text-emerald-600">
                      Nothing to buy — you already have it all 🎉
                    </p>
                  ) : (
                    <ul className="flex flex-wrap gap-1.5">
                      {shoppingList.map((id) => (
                        <li key={id}>
                          <IngredientChip id={id} tone="missing" />
                        </li>
                      ))}
                    </ul>
                  )}
                </div>
              )}
            </div>
          )}
        </section>

        {/* -------------------------------------------------- pantry picker */}
        <section aria-labelledby="pantry-heading" className="toon-card rounded-3xl p-4">
          <div className="mb-3 flex items-center justify-between gap-2">
            <h2 id="pantry-heading" className="font-display text-lg font-semibold text-toon-dark">
              In your kitchen
              <span className="ml-2 rounded-full bg-orange-50 px-2 py-0.5 text-xs font-bold text-toon-primary">
                {pantry.ingredients.length}
              </span>
            </h2>
            <div className="flex gap-1">
              <button
                type="button"
                onClick={() => setPantry((current) => ({ ...current, ingredients: suggestStarterPantry() }))}
                className="press-springy flex min-h-11 items-center gap-1 rounded-full bg-orange-50 px-3 text-xs font-bold text-toon-primary-deep transition-colors hover:bg-orange-100"
              >
                <Sparkles size={13} aria-hidden="true" /> Fill it in
              </button>
              {pantry.ingredients.length > 0 && (
                <button
                  type="button"
                  onClick={() => setPantry((current) => ({ ...current, ingredients: [] }))}
                  className="press-springy flex min-h-11 items-center rounded-full px-3 text-xs font-bold text-gray-400 transition-colors hover:text-toon-dark"
                >
                  Clear
                </button>
              )}
            </div>
          </div>

          {pantry.ingredients.length > 0 && (
            <ul className="mb-3 flex flex-wrap gap-1.5">
              {pantry.ingredients.map((id) => (
                <li key={id}>
                  <button
                    type="button"
                    onClick={() => toggleIngredient(id)}
                    aria-label={`Remove ${nameOf(id)} from your kitchen`}
                    className="press-springy flex items-center gap-1 rounded-full border border-toon-secondary/60 bg-toon-cream px-2.5 py-1.5 text-[11px] font-bold text-toon-dark"
                  >
                    <span aria-hidden="true">{emojiOf(id)}</span>
                    {nameOf(id)}
                    <X size={11} aria-hidden="true" className="text-gray-400" />
                  </button>
                </li>
              ))}
            </ul>
          )}

          <div className="relative mb-3">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" size={16} aria-hidden="true" />
            <input
              type="search"
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              placeholder="Search ingredients..."
              aria-label="Search ingredients"
              className="w-full rounded-2xl border border-orange-100/70 bg-white py-2.5 pl-10 pr-3 text-sm font-medium shadow-toon-soft outline-none transition-shadow focus:shadow-toon-glow focus:ring-2 focus:ring-toon-secondary/60"
            />
          </div>

          {!search && (
            <div className="mb-3 flex gap-1.5 overflow-x-auto hide-scrollbar pb-1" role="tablist" aria-label="Ingredient groups">
              {GROUPS.map((item) => (
                <button
                  key={item.id}
                  role="tab"
                  aria-selected={group === item.id}
                  onClick={() => setGroup(item.id)}
                  className={`press-springy min-h-11 whitespace-nowrap rounded-full px-3.5 text-xs font-bold transition-all ${
                    group === item.id
                      ? 'bg-toon-dark text-white shadow-md'
                      : 'border border-orange-100 bg-white text-gray-500 hover:border-toon-secondary hover:text-toon-dark'
                  }`}
                >
                  <span aria-hidden="true" className="mr-1">{item.emoji}</span>
                  {item.label}
                </button>
              ))}
            </div>
          )}

          <ul className="grid grid-cols-3 gap-2">
            {pickerIngredients.map((item) => {
              const selected = pantry.ingredients.includes(item.id);
              return (
                <li key={item.id}>
                  <button
                    type="button"
                    aria-pressed={selected}
                    onClick={() => toggleIngredient(item.id)}
                    className={`press-springy relative flex h-[92px] w-full flex-col items-center justify-center gap-1 rounded-2xl border p-1.5 text-center transition-all ${
                      selected
                        ? 'border-toon-primary bg-gradient-to-b from-orange-50 to-white shadow-toon-glow'
                        : 'border-orange-100 bg-white hover:border-toon-secondary hover:shadow-toon-soft'
                    }`}
                  >
                    {selected && (
                      <span
                        aria-hidden="true"
                        className="absolute right-1.5 top-1.5 flex h-4 w-4 items-center justify-center rounded-full bg-toon-primary text-white"
                      >
                        <Check size={10} strokeWidth={4} />
                      </span>
                    )}
                    <PackAsset
                      src={kitchenAssetPack.ingredient(item.id)}
                      fallback={<span aria-hidden="true" className="text-2xl">{item.emoji}</span>}
                      className="flex h-10 items-center justify-center text-2xl"
                      imageClassName="h-10 w-10 object-contain"
                    />
                    <span className="line-clamp-2 text-[10px] font-bold leading-tight text-toon-dark">
                      {item.name}
                    </span>
                  </button>
                </li>
              );
            })}
          </ul>

          {pickerIngredients.length === 0 && (
            <p className="py-6 text-center text-sm font-semibold text-gray-400">
              Nothing called &ldquo;{search}&rdquo; in the catalogue.
            </p>
          )}

          <button
            type="button"
            onClick={() => setShowEverything((current) => !current)}
            className="mt-3 w-full rounded-xl py-2 text-xs font-bold text-gray-400 transition-colors hover:bg-orange-50 hover:text-toon-dark"
          >
            {showEverything ? 'Show only ingredients with recipes' : `Show all ${INGREDIENTS.length} ingredients`}
          </button>
        </section>

        {/* ------------------------------------------------------- cookware */}
        <section aria-labelledby="cookware-heading" className="toon-card rounded-3xl p-4">
          <div className="mb-3 flex items-center justify-between">
            <h2 id="cookware-heading" className="font-display text-lg font-semibold text-toon-dark">
              What can you cook with?
            </h2>
            {pantry.cookware.length > 0 && (
              <button
                type="button"
                onClick={() => setPantry((current) => ({ ...current, cookware: [] }))}
                className="press-springy min-h-11 rounded-full px-3 text-xs font-bold text-gray-400 hover:text-toon-dark"
              >
                Any
              </button>
            )}
          </div>
          <p className="mb-3 text-xs font-medium text-gray-400">
            Knives, boards, and bowls are assumed. Pick appliances to narrow things down.
          </p>
          <ul className="grid grid-cols-3 gap-2">
            {COOKWARE_IDS.map((id) => {
              const tool = TOOL_BY_ID.get(id);
              const selected = pantry.cookware.includes(id);
              return (
                <li key={id}>
                  <button
                    type="button"
                    aria-pressed={selected}
                    onClick={() => toggleCookware(id)}
                    className={`press-springy flex h-[88px] w-full flex-col items-center justify-center gap-1 rounded-2xl border p-1.5 text-center transition-all ${
                      selected
                        ? 'border-toon-accent bg-gradient-to-b from-cyan-50 to-white shadow-[0_0_0_3px_rgba(110,198,202,0.18)]'
                        : 'border-orange-100 bg-white hover:border-toon-accent/60'
                    }`}
                  >
                    <PackAsset
                      src={kitchenAssetPack.tool(id)}
                      fallback={<span aria-hidden="true" className="text-2xl">🍳</span>}
                      className="flex h-9 items-center justify-center text-2xl"
                      imageClassName="h-9 w-9 object-contain"
                    />
                    <span className="line-clamp-2 text-[10px] font-bold leading-tight text-toon-dark">
                      {tool?.name ?? id.replace(/_/g, ' ')}
                    </span>
                  </button>
                </li>
              );
            })}
          </ul>
        </section>

        {/* ---------------------------------------------------------- modes */}
        <section aria-labelledby="mode-heading" className="toon-card rounded-3xl p-4">
          <h2 id="mode-heading" className="mb-3 font-display text-lg font-semibold text-toon-dark">
            How strict should we be?
          </h2>
          <div className="flex gap-1 rounded-2xl bg-orange-50 p-1" role="tablist" aria-label="Match strictness">
            {MATCH_MODES.map((item) => (
              <button
                key={item.id}
                role="tab"
                aria-selected={pantry.mode === item.id}
                onClick={() => setPantry((current) => ({ ...current, mode: item.id as MatchMode }))}
                className={`min-h-11 flex-1 rounded-xl px-2 text-xs font-bold transition-all ${
                  pantry.mode === item.id
                    ? 'bg-white text-toon-dark shadow-toon-soft'
                    : 'text-gray-400 hover:text-toon-dark'
                }`}
              >
                <span aria-hidden="true" className="mr-1">{item.emoji}</span>
                {item.label}
              </button>
            ))}
          </div>
          <p className="mt-2.5 text-xs font-medium text-gray-500">{modeInfo.hint}</p>
        </section>

        {/* -------------------------------------------------------- results */}
        <section ref={resultsRef} aria-labelledby="results-heading" className="scroll-mt-28">
          <div className="mb-3 flex items-baseline justify-between">
            <h2 id="results-heading" className="font-display text-xl font-semibold text-toon-dark">
              {pantry.ingredients.length === 0 ? 'Ideas to get you started' : 'You can cook'}
            </h2>
            <span className="text-xs font-bold uppercase tracking-wider text-gray-400">
              {matches.length} {matches.length === 1 ? 'dish' : 'dishes'}
            </span>
          </div>

          {matches.length === 0 && (
            <div className="toon-card animate-pop-in rounded-3xl p-6 text-center">
              <span aria-hidden="true" className="mb-2 block text-4xl">🥲</span>
              <p className="font-bold text-toon-dark">Nothing matches yet</p>
              <p className="mt-1 text-sm text-gray-500">
                {pantry.mode === 'survival'
                  ? 'Survival mode is picky. Try Exact or Flexible.'
                  : 'Add a few more ingredients, or loosen the cookware filter.'}
              </p>
              {nearMisses.length > 0 && (
                <>
                  <p className="mt-4 text-xs font-bold uppercase tracking-wider text-toon-primary">
                    Add one of these and dishes appear
                  </p>
                  <ul className="mt-2 flex flex-wrap justify-center gap-1.5">
                    {nearMisses.map(({ id, count }) => (
                      <li key={id}>
                        <button
                          type="button"
                          onClick={() => toggleIngredient(id)}
                          className="press-springy flex items-center gap-1 rounded-full border border-orange-100 bg-white px-2.5 py-1.5 text-[11px] font-bold text-toon-dark hover:border-toon-secondary"
                        >
                          <span aria-hidden="true">{emojiOf(id)}</span>
                          {nameOf(id)}
                          <span className="text-toon-primary">+{count}</span>
                        </button>
                      </li>
                    ))}
                  </ul>
                </>
              )}
            </div>
          )}

          <ul className="space-y-3 stagger-children">
            {matches.map((match) => {
              const favorite = pantry.favorites.includes(match.recipe.id);
              return (
                <li key={match.recipe.id}>
                  <article className="animate-rise toon-card overflow-hidden rounded-3xl transition-all hover:-translate-y-0.5 hover:shadow-toon-lift">
                    <button
                      type="button"
                      onClick={() => setDetail(match)}
                      className="flex w-full items-center gap-3 p-3 text-left"
                    >
                      <span className="relative flex h-16 w-16 shrink-0 items-center justify-center overflow-hidden rounded-2xl bg-gradient-to-br from-orange-50 to-toon-cream">
                        <PackAsset
                          src={heroAssetFor(match.recipe)}
                          fallback={<span aria-hidden="true" className="text-3xl">{match.recipe.emoji}</span>}
                          className="flex h-full w-full items-center justify-center text-3xl"
                          imageClassName="h-14 w-14 object-contain"
                        />
                      </span>

                      <span className="min-w-0 flex-1">
                        <span className="flex items-center gap-1.5">
                          <span className="truncate font-bold text-toon-dark">{match.recipe.title}</span>
                          {match.readyNow && match.ranking === 'pantry' && (
                            <span className="shrink-0 rounded-full bg-emerald-50 px-1.5 py-0.5 text-[9px] font-bold uppercase tracking-wide text-emerald-600">
                              Ready
                            </span>
                          )}
                        </span>
                        <span className="mt-0.5 flex items-center gap-2 text-[10px] font-bold uppercase tracking-wider text-gray-400">
                          <span className="flex items-center gap-0.5">
                            <Clock size={10} aria-hidden="true" /> {match.recipe.minutes}m
                          </span>
                          <span>{COURSE_LABEL[match.recipe.course]}</span>
                          <span>{difficultyLabel(match.recipe.difficulty)}</span>
                        </span>
                        <span
                          className={`mt-1.5 block text-[11px] ${
                            match.ranking === 'discovery'
                              ? 'line-clamp-2 font-medium leading-relaxed text-gray-400'
                              : 'font-semibold text-toon-primary-deep'
                          }`}
                        >
                          {match.reason}
                        </span>
                      </span>

                      {match.ranking === 'pantry' && (
                        <MatchRing coverage={match.coverage} ready={match.readyNow} />
                      )}
                    </button>

                    <div className="flex flex-wrap items-center gap-1.5 border-t border-orange-50 px-3 py-2">
                      {match.ranking === 'discovery' &&
                        match.recipe.core.slice(0, 3).map((id) => (
                          <IngredientChip key={id} id={id} tone="missing" />
                        ))}
                      {match.ranking === 'pantry' &&
                        match.missingCore.slice(0, 3).map((id) => (
                          <IngredientChip key={id} id={id} tone="missing" />
                        ))}
                      {match.ranking === 'pantry' &&
                        match.missingCore.length === 0 &&
                        match.haveCore.slice(0, 3).map((id) => <IngredientChip key={id} id={id} tone="have" />)}
                      <span className="ml-auto flex items-center gap-1">
                        <button
                          type="button"
                          aria-label={`${favorite ? 'Unsave' : 'Save'} ${match.recipe.title}`}
                          aria-pressed={favorite}
                          onClick={() => toggleFavorite(match.recipe.id)}
                          className={`press-springy flex h-11 w-11 items-center justify-center rounded-full transition-colors ${
                            favorite ? 'text-pink-500' : 'text-gray-300 hover:text-pink-400'
                          }`}
                        >
                          <Heart size={16} className={favorite ? 'fill-current' : ''} />
                        </button>
                        <button
                          type="button"
                          onClick={() => cookRecipe(match.recipe)}
                          className="press-springy btn-candy flex min-h-11 items-center gap-1.5 rounded-full px-4 text-xs font-bold text-white"
                        >
                          <PlayCircle size={14} aria-hidden="true" /> Cook
                        </button>
                      </span>
                    </div>
                  </article>
                </li>
              );
            })}
          </ul>
        </section>
      </div>

      {detail && (
        <div
          className="fixed inset-0 z-[70] flex items-end bg-black/35 px-3 pb-3 backdrop-blur-sm animate-fade"
          onClick={(event) => {
            if (event.target === event.currentTarget) setDetail(null);
          }}
        >
          <section
            role="dialog"
            aria-modal="true"
            aria-labelledby="pantry-detail-title"
            className="animate-sheet-up mx-auto max-h-[82vh] w-full max-w-md overflow-y-auto rounded-[2rem] bg-white p-5 shadow-2xl hide-scrollbar"
          >
            <div aria-hidden="true" className="mx-auto mb-3 h-1.5 w-12 rounded-full bg-orange-100" />

            <div className="flex items-start gap-3">
              <span className="flex h-16 w-16 shrink-0 items-center justify-center overflow-hidden rounded-2xl bg-gradient-to-br from-orange-50 to-toon-cream">
                <PackAsset
                  src={heroAssetFor(detail.recipe)}
                  fallback={<span aria-hidden="true" className="text-3xl">{detail.recipe.emoji}</span>}
                  className="flex h-full w-full items-center justify-center text-3xl"
                  imageClassName="h-14 w-14 object-contain"
                />
              </span>
              <div className="min-w-0 flex-1">
                <h2 id="pantry-detail-title" className="font-display text-xl font-semibold text-toon-dark">
                  {detail.recipe.title}
                </h2>
                <p className="mt-0.5 text-[11px] font-bold uppercase tracking-wider text-gray-400">
                  {detail.recipe.cuisine} · {detail.recipe.minutes} min · serves {detail.recipe.servings} ·{' '}
                  {difficultyLabel(detail.recipe.difficulty)}
                </p>
              </div>
              <button
                type="button"
                aria-label="Close recipe"
                onClick={() => setDetail(null)}
                className="press-springy rounded-full bg-gray-50 p-2 text-gray-400 hover:text-toon-dark"
              >
                <X size={18} />
              </button>
            </div>

            <p className="mt-3 text-sm italic text-gray-500">{detail.recipe.blurb}</p>

            <h3 className="mt-5 text-xs font-bold uppercase tracking-wider text-toon-primary">
              You have
            </h3>
            <ul className="mt-2 flex flex-wrap gap-1.5">
              {[...detail.haveCore, ...detail.haveExtras].map((id) => (
                <li key={id}>
                  <IngredientChip id={id} tone="have" />
                </li>
              ))}
              {detail.haveCore.length + detail.haveExtras.length === 0 && (
                <li className="text-sm text-gray-400">Nothing yet.</li>
              )}
            </ul>

            {(detail.missingCore.length > 0 || detail.missingExtras.length > 0) && (
              <>
                <h3 className="mt-4 text-xs font-bold uppercase tracking-wider text-toon-primary">
                  Still needed
                </h3>
                <ul className="mt-2 flex flex-wrap gap-1.5">
                  {[...detail.missingCore, ...detail.missingExtras].map((id) => (
                    <li key={id}>
                      <button
                        type="button"
                        aria-label={`I actually have ${nameOf(id)}`}
                        onClick={() => toggleIngredient(id)}
                        className="press-springy"
                      >
                        <IngredientChip id={id} tone="missing" />
                      </button>
                    </li>
                  ))}
                </ul>
                <p className="mt-1.5 text-[11px] text-gray-400">Tap one to add it to your kitchen.</p>
              </>
            )}

            <h3 className="mt-5 text-xs font-bold uppercase tracking-wider text-toon-primary">
              How it goes
            </h3>
            <ol className="mt-2 space-y-2">
              {detail.recipe.steps.map((step, index) => (
                <li key={`${detail.recipe.id}-${index}`} className="flex gap-3 rounded-2xl bg-toon-cream p-3">
                  <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-toon-primary text-[11px] font-bold text-white">
                    {index + 1}
                  </span>
                  <span className="text-sm leading-relaxed text-gray-600">{step.n}</span>
                </li>
              ))}
            </ol>

            <div className="sticky bottom-0 mt-5 flex gap-2 bg-white pt-3">
              <button
                type="button"
                onClick={() => toggleFavorite(detail.recipe.id)}
                aria-pressed={pantry.favorites.includes(detail.recipe.id)}
                className={`press-springy flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl border transition-colors ${
                  pantry.favorites.includes(detail.recipe.id)
                    ? 'border-pink-200 bg-pink-50 text-pink-500'
                    : 'border-orange-100 text-gray-300 hover:text-pink-400'
                }`}
              >
                <Heart size={20} className={pantry.favorites.includes(detail.recipe.id) ? 'fill-current' : ''} />
                <span className="sr-only">Save recipe</span>
              </button>
              <button
                type="button"
                onClick={() => cookRecipe(detail.recipe)}
                className="press-springy btn-candy flex h-12 flex-1 items-center justify-center gap-2 rounded-2xl font-bold text-white"
              >
                <PlayCircle size={18} aria-hidden="true" /> Open in the builder
              </button>
            </div>
          </section>
        </div>
      )}

      {/* Refresh sits low so it never fights the primary actions above. */}
      {matches.length > 0 && (
        <div className="px-4 pt-6">
          <button
            type="button"
            onClick={() => setPantry(() => EMPTY_PANTRY)}
            className="flex w-full items-center justify-center gap-2 rounded-xl py-2 text-xs font-bold text-gray-400 transition-colors hover:bg-white/60 hover:text-toon-dark"
          >
            <RefreshCw size={13} aria-hidden="true" /> Reset my kitchen
          </button>
        </div>
      )}
    </div>
  );
};
