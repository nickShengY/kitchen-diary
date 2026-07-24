
import React, { useEffect, useMemo, useState } from 'react';
import {
  Plus,
  Trash2,
  Clock,
  Flame,
  Thermometer,
  Droplets,
  ArrowLeft,
  Share2,
  Search,
  Sparkles,
  Scissors,
  Soup,
  Leaf,
  Play,
  Pencil,
  Check,
} from 'lucide-react';
import { Ingredient, RecipeStep, Recipe } from '../types';
import { PackAsset, MotionScene } from './AssetImage';
import { RecipePlayer } from './RecipePlayer';
import { ShareSheet } from './ShareSheet';
import {
  INGREDIENTS,
  TOOLS,
  ACTIONS,
  TEMPERATURES,
  TIMES,
  WATER_LEVELS,
  CUT_SHAPES,
  COOK_METHODS,
  DETAIL_CHIPS,
} from '../data/kitchenData';
import { kitchenAssetPack } from '../services/kitchenAssetPack';
import { clearRecipeDraft, loadRecipeDraft, saveRecipeDraft } from '../services/recipeDraftStore';

interface RecipeBuilderProps {
    initialRecipe?: Recipe;
    onExit?: () => void;
    /** Called after a successful community share so the app can jump to the feed. */
    onShared?: () => void;
}

export const RecipeBuilder: React.FC<RecipeBuilderProps> = ({ initialRecipe, onExit, onShared }) => {
  // Imported recipes take priority; otherwise pick up the saved draft so a
  // half-built recipe survives navigating to another tab (or a reload).
  const [recipeName, setRecipeName] = useState(
    () => initialRecipe?.title || loadRecipeDraft()?.title || 'My Delicious Recipe',
  );
  const [steps, setSteps] = useState<RecipeStep[]>(
    () => initialRecipe?.steps ?? loadRecipeDraft()?.steps ?? [],
  );
  const [view, setView] = useState<'list' | 'editor'>('list');
  const [ingredientSearch, setIngredientSearch] = useState('');
  const [ingredientCategory, setIngredientCategory] = useState<Ingredient['category'] | 'all'>('all');
  const [showPlayer, setShowPlayer] = useState(false);
  const [showShare, setShowShare] = useState(false);

  // Editor State
  // Keep the working recipe saved as a draft; an empty timeline clears it so
  // deliberately deleting every step doesn't resurrect on the next visit. The
  // first render is skipped so importing a step-less feed recipe can't wipe a
  // draft the user hasn't touched yet.
  const draftHydratedRef = React.useRef(false);
  useEffect(() => {
    if (!draftHydratedRef.current) {
      draftHydratedRef.current = true;
      if (steps.length === 0) return;
    }
    if (steps.length > 0) {
      saveRecipeDraft({ title: recipeName, steps });
    } else {
      clearRecipeDraft();
    }
  }, [recipeName, steps]);

  const [activeStep, setActiveStep] = useState<Partial<RecipeStep>>({ ingredients: [] });
  const [editingStepId, setEditingStepId] = useState<string | null>(null);
  const [stage, setStage] = useState<'ingredients' | 'action' | 'details'>('ingredients');
  const [actionFilter, setActionFilter] = useState<'all' | 'prep' | 'cook' | 'finish'>('all');

  // --- SMART FILTERS ---

  // Every action knows the tool it needs, and every tool belongs to a station,
  // so choosing an action settles the whole "how" in one tap.
  const stationForAction = (action: (typeof ACTIONS)[number]): RecipeStep['station'] => {
    const tool = TOOLS.find((t) => t.id === action.requiresToolId);
    if (!tool) return 'finish';
    if (tool.type === 'prep') return 'prep';
    if (tool.type === 'finish') return 'finish';
    return 'cook';
  };

  // An action fits when every chosen ingredient shares at least one physical
  // property with it — you can chop a carrot, but never a broth.
  const isActionValidForIngredients = (actionId: string, ingredients: {id: string}[]) => {
      const action = ACTIONS.find(a => a.id === actionId);
      if (!action?.validProperties) return true;

      return ingredients.every(i => {
          const ingData = INGREDIENTS.find(d => d.id === i.id);
          if (!ingData) return true;
          return action.validProperties?.some(prop => ingData.physicalProperties.includes(prop));
      });
  };

  const compatibleActions = useMemo(() => {
    const ingredients = activeStep.ingredients ?? [];
    return ACTIONS.filter((action) => isActionValidForIngredients(action.id, ingredients));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeStep.ingredients]);

  const visibleActions =
    actionFilter === 'all'
      ? compatibleActions
      : compatibleActions.filter((action) => stationForAction(action) === actionFilter);

  // Which single ingredient blocks the most actions? Suggesting it makes a
  // "nothing fits" moment recoverable in one tap.
  const blockingIngredientId = useMemo(() => {
    const ingredients = activeStep.ingredients ?? [];
    if (compatibleActions.length > 0 || ingredients.length < 2) return null;
    let best: { id: string; unlocked: number } | null = null;
    for (const candidate of ingredients) {
      const rest = ingredients.filter((item) => item.id !== candidate.id);
      const unlocked = ACTIONS.filter((action) => isActionValidForIngredients(action.id, rest)).length;
      if (!best || unlocked > best.unlocked) best = { id: candidate.id, unlocked };
    }
    return best && best.unlocked > 0 ? best.id : null;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeStep.ingredients, compatibleActions.length]);

  const selectedAction = ACTIONS.find(a => a.id === activeStep.actionId);
  const selectedPrimaryIngredient = activeStep.ingredients?.[0]?.id;
  const selectedIngredients = activeStep.ingredients || [];
  const selectedIngredientNames = selectedIngredients
    .map((item) => INGREDIENTS.find((ingredient) => ingredient.id === item.id)?.name)
    .filter(Boolean);
  const motionPreview =
    selectedPrimaryIngredient && selectedAction
      ? kitchenAssetPack.transitionMotion(selectedPrimaryIngredient, selectedAction.id) ??
        kitchenAssetPack.actionMotion(selectedAction.id)
      : selectedAction
        ? kitchenAssetPack.actionMotion(selectedAction.id)
        : undefined;
  const ingredientCategories = useMemo(
    () => ['all', ...Array.from(new Set(INGREDIENTS.map((ingredient) => ingredient.category)))] as const,
    [],
  );
  const filteredIngredients = useMemo(() => {
    const normalizedQuery = ingredientSearch.trim().toLowerCase();

    return INGREDIENTS.filter((ingredient) => {
      const matchesCategory =
        ingredientCategory === 'all' || ingredient.category === ingredientCategory;
      const matchesSearch =
        !normalizedQuery ||
        ingredient.name.toLowerCase().includes(normalizedQuery) ||
        ingredient.id.replace(/_/g, ' ').includes(normalizedQuery);

      return matchesCategory && matchesSearch;
    });
  }, [ingredientCategory, ingredientSearch]);

  const updateSettings = (patch: Partial<NonNullable<RecipeStep['settings']>>) => {
    setActiveStep({
      ...activeStep,
      settings: {
        ...activeStep.settings,
        ...patch,
      },
    });
  };

  const isCutAction = ['chop', 'dice', 'slice', 'mince', 'peel', 'grate', 'crush'].includes(
    activeStep.actionId || '',
  );

  const detailOptionIdsByAction: Record<string, string[]> = {
    chop: ['chopped'],
    dice: ['diced'],
    slice: ['sliced'],
    mince: ['minced'],
    peel: ['peeled'],
    grate: ['grated'],
    crush: ['crushed'],
  };
  const detailCutShapes = activeStep.actionId
    ? CUT_SHAPES.filter((shape) => detailOptionIdsByAction[activeStep.actionId!]?.includes(shape.id))
    : CUT_SHAPES;

  // --- HANDLERS ---

  const handleStartStep = () => {
    setActiveStep({ id: Date.now().toString(), ingredients: [] });
    setEditingStepId(null);
    setStage('ingredients');
    setActionFilter('all');
    setView('editor');
  };

  const handleEditStep = (step: RecipeStep) => {
    setActiveStep({ ...step, ingredients: [...step.ingredients] });
    setEditingStepId(step.id);
    setStage('ingredients');
    setActionFilter('all');
    setView('editor');
  };

  const CUT_ACTION_IDS = ['chop', 'dice', 'slice', 'mince', 'peel', 'grate', 'crush'];

  // Only keep settings the newly chosen action can still use, so editing a
  // step from "chop" to "boil" doesn't leave a Cut Shape tag behind.
  const settingsForAction = (action: (typeof ACTIONS)[number]): RecipeStep['settings'] => {
    const station = stationForAction(action);
    const previous = activeStep.settings ?? {};
    return {
      duration: previous.duration,
      cutShape: CUT_ACTION_IDS.includes(action.id) ? previous.cutShape : undefined,
      temperature: action.requiresHeat ? previous.temperature : undefined,
      cookMethod: station === 'cook' ? previous.cookMethod : undefined,
      waterLevel: station === 'cook' ? previous.waterLevel : undefined,
      oil: station === 'cook' ? previous.oil : undefined,
      liquid: station === 'cook' ? previous.liquid : undefined,
      garnish: station === 'finish' ? previous.garnish : undefined,
      texture: station === 'finish' ? previous.texture : undefined,
    };
  };

  const handlePickAction = (action: (typeof ACTIONS)[number]) => {
    setActiveStep({
      ...activeStep,
      actionId: action.id,
      toolId: action.requiresToolId ?? 'plate',
      station: stationForAction(action),
      settings: settingsForAction(action),
    });
    setStage('details');
  };

  const handleFinishStep = () => {
    if (activeStep.actionId) {
      const completedStep = {
        ...activeStep,
        toolId: activeStep.toolId || (activeStep.station === 'finish' ? 'plate' : activeStep.toolId),
        ingredients: activeStep.ingredients || [],
      } as RecipeStep;
      setSteps((current) =>
        editingStepId
          ? current.map((s) => (s.id === editingStepId ? completedStep : s))
          : [...current, completedStep],
      );
      setEditingStepId(null);
      setView('list');
    }
  };

  // Prefer real durations from step settings; fall back to ~5 mins per step.
  const estimatedMinutes = steps.reduce((total, step) => {
    const duration = step.settings?.duration ?? '';
    const parsed = parseInt(duration, 10);
    if (!Number.isFinite(parsed) || parsed <= 0) return total + 5;
    if (duration.includes('hr')) return total + parsed * 60;
    return total + parsed;
  }, 0);

  const addIngredientToStep = (ing: Ingredient) => {
    const currentIngs = activeStep.ingredients || [];
    if (!currentIngs.find(i => i.id === ing.id)) {
      setActiveStep({
        ...activeStep,
        ingredients: [...currentIngs, { id: ing.id, amount: '1', unit: ing.defaultUnit }]
      });
    }
  };

  const removeIngredientFromStep = (id: string) => {
    setActiveStep({
      ...activeStep,
      ingredients: activeStep.ingredients?.filter(i => i.id !== id)
    });
  };

  const renderTimeline = () => (
    <div className="pb-32 min-h-screen">
       <header className="sticky top-0 bg-[#FFF5F0]/90 backdrop-blur-md z-10 px-6 py-4 shadow-[0_10px_30px_-18px_rgba(74,64,58,0.25)] flex items-center gap-2">
          {onExit && (
              <button aria-label="Back to Explore" onClick={onExit} className="press-springy -ml-2 flex h-11 w-11 items-center justify-center rounded-full hover:bg-white hover:shadow-toon-soft transition-all">
                  <ArrowLeft className="text-toon-dark"/>
              </button>
          )}
          <div className="flex-1">
            <input
                value={recipeName}
                onChange={(e) => setRecipeName(e.target.value)}
                aria-label="Recipe name"
                className="min-h-11 w-full bg-transparent font-display text-2xl font-semibold text-toon-dark outline-none placeholder-gray-300 rounded-lg transition-colors focus:bg-white/70 focus:px-2"
                placeholder="Name your recipe..."
            />
            <p className="text-toon-primary text-sm font-medium mt-1">{steps.length} steps • ~{estimatedMinutes} mins</p>
          </div>
          {steps.length > 0 ? (
            <button
              type="button"
              aria-label="Watch animated recipe"
              onClick={() => setShowPlayer(true)}
              className="press-springy btn-candy flex min-h-11 items-center gap-1.5 rounded-full px-4 py-2 text-sm font-bold text-white"
            >
              <Play size={16} className="fill-current" /> Watch
            </button>
          ) : null}
       </header>

       <div className="px-6 py-6 space-y-8">
          {steps.length === 0 && (
            <div className="relative text-center py-12 animate-pop-in">
              <span aria-hidden="true" className="toon-sunburst absolute left-1/2 top-6 h-40 w-40 ml-[-5rem] rounded-full" />
              <div className="relative mx-auto mb-4 h-16 w-16">
                <Sparkles className="h-16 w-16 text-toon-primary animate-float drop-shadow-[0_8px_12px_rgba(242,112,79,0.3)]" strokeWidth={1.5} />
                <span aria-hidden="true" className="toon-twinkle absolute -right-4 top-0 text-toon-secondary">✦</span>
                <span aria-hidden="true" className="toon-twinkle absolute -left-4 bottom-1 text-toon-accent" style={{ animationDelay: '0.8s' }}>✧</span>
              </div>
              <p className="relative font-display text-lg font-semibold text-toon-dark">Your kitchen is empty!</p>
              <p className="relative text-sm text-gray-400 mt-1">Tap the big plus button to start cooking.</p>
            </div>
          )}

          {steps.map((step, idx) => {
             const action = ACTIONS.find(a => a.id === step.actionId);
             const tool = TOOLS.find(t => t.id === step.toolId);
             const motionAsset =
               step.ingredients[0] && action
                 ? kitchenAssetPack.transitionMotion(step.ingredients[0].id, action.id) ??
                   kitchenAssetPack.actionMotion(action.id)
                 : action
                   ? kitchenAssetPack.actionMotion(action.id)
                   : undefined;
             return (
               <div key={step.id} className="relative flex gap-4 animate-rise" style={{animationDelay: `${Math.min(idx, 8) * 90}ms`}}>
                  {idx !== steps.length - 1 && (
                    <div className="absolute left-[22px] top-12 bottom-[-32px] w-1 bg-gradient-to-b from-toon-secondary to-toon-primary/20 rounded-full"></div>
                  )}
                  
                  <div className={`relative w-12 h-12 shrink-0 rounded-full flex items-center justify-center text-2xl border-4 z-10 shadow-sm transition-transform duration-300 hover:scale-110 hover:-rotate-6 ${
                    step.station === 'cook'
                      ? 'bg-red-50 border-red-100 text-red-500'
                      : step.station === 'finish'
                        ? 'bg-yellow-50 border-yellow-100 text-yellow-600'
                        : 'bg-green-50 border-green-100 text-green-600'
                  }`}>
                    {step.station === 'cook' && (
                      <span aria-hidden="true" className="pointer-events-none absolute -top-3 left-1/2 -translate-x-1/2">
                        <span className="steam-wisp" style={{ left: '-7px' }} />
                        <span className="steam-wisp" style={{ left: '0px', animationDelay: '0.7s' }} />
                        <span className="steam-wisp" style={{ left: '7px', animationDelay: '1.3s' }} />
                      </span>
                    )}
                    <span className="text-2xl" aria-hidden="true">{action?.icon}</span>
                  </div>

                  <div className="flex-1 toon-card p-4 rounded-2xl transition-shadow hover:shadow-xl">
                     <div className="flex justify-between items-start mb-2">
                        <h3 className="font-bold text-toon-dark text-lg capitalize">
                          {action?.verb}
                          {tool?.name && (
                            <span className="text-gray-400 font-normal text-sm ml-2">using {tool.name}</span>
                          )}
                        </h3>
                        <div className="flex -mt-2 -mr-2">
                          <button
                            aria-label={`Edit step ${idx + 1}`}
                            onClick={() => handleEditStep(step)}
                            className="press-springy flex h-11 w-11 items-center justify-center rounded-full text-gray-300 hover:text-toon-accent-deep hover:bg-cyan-50 transition-colors"
                          >
                            <Pencil size={16} />
                          </button>
                          <button
                            aria-label={`Delete step ${idx + 1}`}
                            onClick={() => setSteps(steps.filter(s => s.id !== step.id))}
                            className="press-springy flex h-11 w-11 items-center justify-center rounded-full text-gray-300 hover:text-red-400 hover:bg-red-50 transition-colors"
                          >
                            <Trash2 size={16} />
                          </button>
                        </div>
                     </div>

                     {/* Ingredients Mini List */}
                     <div className="flex flex-wrap gap-2 mb-3">
                        {step.ingredients.map((si, i) => {
                           const ingData = INGREDIENTS.find(k => k.id === si.id);
                           const presentation = kitchenAssetPack.ingredientPresentation(si.id);
                           const ingredientName = ingData?.name ?? si.id.replace(/_/g, ' ');
                           return (
                             <span key={i} className="bg-orange-50 text-toon-dark text-xs px-2 py-1 rounded-lg border border-orange-100 flex items-center gap-1">
                                <PackAsset
                                  src={presentation.asset}
                                  fallback={ingData?.emoji ?? '🥣'}
                                  imageClassName="h-5 w-5"
                                />
                                <b>{si.amount} {si.unit}</b> {ingredientName}
                             </span>
                           )
                        })}
                     </div>

                     {motionAsset && (
                       <div className="mb-3 flex justify-center overflow-hidden rounded-2xl border border-orange-100 bg-orange-50/60 p-2">
                         <MotionScene
                           src={motionAsset}
                           alt={`${action?.name ?? 'Step'} animation`}
                           className="h-28 w-[134px]"
                         />
                       </div>
                     )}

                     {/* Settings Tags */}
                     <div className="flex gap-2 text-xs font-bold">
                        {step.settings?.temperature && (
                          <span className="bg-red-100 text-red-600 px-2 py-1 rounded-md flex items-center gap-1"><Flame size={12}/> {step.settings.temperature}</span>
                        )}
                        {step.settings?.duration && (
                          <span className="bg-blue-100 text-blue-600 px-2 py-1 rounded-md flex items-center gap-1"><Clock size={12}/> {step.settings.duration}</span>
                        )}
                        {step.settings?.cutShape && (
                          <span className="bg-amber-100 text-amber-700 px-2 py-1 rounded-md flex items-center gap-1">
                            <PackAsset
                              src={kitchenAssetPack.cutShape(step.settings.cutShape.toLowerCase().replace(/\s+/g, '_'))}
                              fallback="Cut"
                              imageClassName="h-4 w-4"
                            />
                            {step.settings.cutShape}
                          </span>
                        )}
                        {step.settings?.cookMethod && (
                          <span className="bg-orange-100 text-orange-700 px-2 py-1 rounded-md flex items-center gap-1">
                            <PackAsset
                              src={kitchenAssetPack.cookMethod(step.settings.cookMethod.toLowerCase().replace(/\s+/g, '_'))}
                              fallback="Cook"
                              imageClassName="h-4 w-4"
                            />
                            {step.settings.cookMethod}
                          </span>
                        )}
                        {step.settings?.oil && (
                          <span className="bg-yellow-100 text-yellow-700 px-2 py-1 rounded-md flex items-center gap-1">
                            <PackAsset src={kitchenAssetPack.detail('oil')} fallback="Oil" imageClassName="h-4 w-4" />
                            {step.settings.oil}
                          </span>
                        )}
                        {step.settings?.waterLevel && (
                          <span className="bg-cyan-100 text-cyan-600 px-2 py-1 rounded-md flex items-center gap-1"><Droplets size={12}/> {step.settings.waterLevel}</span>
                        )}
                        {step.settings?.liquid && (
                          <span className="bg-teal-100 text-teal-700 px-2 py-1 rounded-md flex items-center gap-1">
                            <PackAsset src={kitchenAssetPack.detail('water')} fallback="Liquid" imageClassName="h-4 w-4" />
                            {step.settings.liquid}
                          </span>
                        )}
                        {step.settings?.garnish && (
                          <span className="bg-green-100 text-green-700 px-2 py-1 rounded-md flex items-center gap-1">{step.settings.garnish}</span>
                        )}
                        {step.settings?.texture && (
                          <span className="bg-stone-100 text-stone-700 px-2 py-1 rounded-md flex items-center gap-1">✨ {step.settings.texture}</span>
                        )}
                     </div>
                  </div>
               </div>
             )
          })}
       </div>

       {steps.length > 0 && (
         <div className="fixed bottom-24 left-6 z-20">
           <button
             aria-label="Share recipe"
             onClick={() => setShowShare(true)}
             className="press-springy flex h-12 w-12 items-center justify-center rounded-full border border-orange-100 bg-white shadow-lg text-toon-dark hover:bg-orange-50 hover:text-toon-primary transition-colors"
           >
             <Share2 size={24} />
           </button>
         </div>
       )}

       <div className="fixed bottom-24 right-6 z-20">
          <span aria-hidden="true" className="animate-glow-pulse pointer-events-none absolute inset-0 rounded-full" />
          <button
            aria-label="Add step"
            onClick={handleStartStep}
            className="press-springy btn-candy group relative w-16 h-16 text-white rounded-full flex items-center justify-center hover:scale-110 transition-all ring-4 ring-orange-100"
          >
            <Plus size={32} strokeWidth={3} className="transition-transform duration-300 group-hover:rotate-90" />
          </button>
        </div>

       {showPlayer && (
         <RecipePlayer
           recipeName={recipeName}
           steps={steps}
           onClose={() => setShowPlayer(false)}
           onShare={() => {
             setShowPlayer(false);
             setShowShare(true);
           }}
         />
       )}

       {showShare && (
         <ShareSheet
           recipeName={recipeName}
           steps={steps}
           onClose={() => setShowShare(false)}
           onShared={() => {
             setShowShare(false);
             clearRecipeDraft();
             onShared?.();
           }}
         />
       )}
    </div>
  );

  // EDITOR WIZARD
  const STAGE_ORDER = ['ingredients', 'action', 'details'] as const;

  const handleEditorBack = () => {
    switch (stage) {
      case 'action':
        setStage('ingredients');
        break;
      case 'details':
        setStage('action');
        break;
      default:
        setView('list');
    }
  };

  const renderEditor = () => {
    const stageIndex = STAGE_ORDER.indexOf(stage);
    return (
      <div className="fixed inset-0 toon-atmosphere z-[60] flex flex-col animate-rise">
        {/* Editor Header */}
        <div className="bg-white/90 backdrop-blur px-6 py-4 shadow-sm flex items-center justify-between">
            <button
              aria-label={stage === 'ingredients' ? 'Close step editor' : 'Go back a step'}
              onClick={handleEditorBack}
              className="press-springy -ml-2 flex h-11 w-11 items-center justify-center rounded-full hover:bg-gray-100 transition-colors"
            >
              <ArrowLeft className="text-toon-dark" />
            </button>
            <div className="text-center">
              <h2 className="font-display font-semibold text-lg text-toon-dark leading-tight">
                {stage === 'ingredients' && "What's cooking?"}
                {stage === 'action' && 'How do you cook it?'}
                {stage === 'details' && 'Make it yours'}
              </h2>
              <p className="text-[11px] font-bold text-gray-400">Step {stageIndex + 1} of {STAGE_ORDER.length}</p>
            </div>
            <div className="w-10"></div>
        </div>

        {/* Progress Bar */}
        <div className="h-1.5 bg-orange-100/70 w-full" role="progressbar" aria-valuemin={1} aria-valuemax={3} aria-valuenow={stageIndex + 1} aria-label="Step editor progress">
           <div
             className="h-full rounded-r-full bg-gradient-to-r from-toon-secondary to-toon-primary transition-all duration-500 ease-out"
             style={{ width: `${((stageIndex + 1) / STAGE_ORDER.length) * 100}%`}}
           />
        </div>

        <div key={stage} className="flex-1 overflow-y-auto p-6 animate-rise">
           
           {/* STAGE 1: INGREDIENTS */}
           {stage === 'ingredients' && (
             <div className="space-y-6 pb-4">
                <div className="sticky top-0 z-20 -mx-6 border-b border-orange-100 bg-[#FFF5F0]/95 px-6 py-3 backdrop-blur-md">
                  <div className="mb-2 flex items-center justify-between gap-3">
                    <div>
                      <p className="text-xs font-bold uppercase tracking-wide text-toon-primary">Selected</p>
                      <p className="text-sm font-semibold text-toon-dark">
                        {selectedIngredients.length > 0
                          ? selectedIngredientNames.join(', ')
                          : 'Choose ingredients for this step'}
                      </p>
                    </div>
                    <span className="rounded-full bg-white px-3 py-1 text-xs font-bold text-gray-500 shadow-sm">
                      {selectedIngredients.length} picked
                    </span>
                  </div>
                  <div className="flex gap-2 overflow-x-auto pb-1 hide-scrollbar">
                   {selectedIngredients.map(i => {
                      const data = INGREDIENTS.find(d => d.id === i.id);
                      const presentation = kitchenAssetPack.ingredientPresentation(i.id);
                      const ingredientName = data?.name ?? i.id.replace(/_/g, ' ');
                      return (
                        <div key={i.id} className="bg-toon-primary text-white px-4 py-2 rounded-full flex items-center gap-2 text-sm shadow-md animate-pop-in">
                           <PackAsset
                             src={presentation.asset}
                             fallback={data?.emoji ?? '🥣'}
                             imageClassName="h-5 w-5 rounded-full bg-white/20"
                           />
                           <span>{ingredientName}</span>
                           <button
                             aria-label={`Remove ${ingredientName}`}
                             onClick={(e) => {e.stopPropagation(); removeIngredientFromStep(i.id)}}
                             className="-my-2 -mr-3 flex h-11 w-11 items-center justify-center rounded-full hover:bg-white/20"
                           >
                             <Trash2 size={14}/>
                           </button>
                       </div>
                      )
                   })}
                   {selectedIngredients.length === 0 && <span className="text-gray-400 italic px-2">Select items below...</span>}
                  </div>
                </div>

                <div className="rounded-3xl border border-orange-100 bg-white p-4 shadow-sm">
                  <label className="relative block">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={16} />
                    <input
                      value={ingredientSearch}
                      onChange={(event) => setIngredientSearch(event.target.value)}
                      placeholder="Search ingredients..."
                      className="w-full rounded-2xl border border-orange-100 bg-orange-50/60 py-3 pl-10 pr-4 text-sm font-medium text-toon-dark outline-none transition focus:border-toon-primary focus:bg-white"
                    />
                  </label>

                  <div className="mt-3 flex gap-2 overflow-x-auto pb-1 hide-scrollbar">
                    {ingredientCategories.map((category) => (
                      <button
                        key={category}
                        type="button"
                        onClick={() => setIngredientCategory(category)}
                        className={`min-h-11 whitespace-nowrap rounded-full px-4 py-2 text-xs font-bold capitalize transition-colors ${
                          ingredientCategory === category
                            ? 'bg-toon-dark text-white'
                            : 'bg-orange-50 text-gray-500 hover:bg-orange-100'
                        }`}
                      >
                        {category}
                      </button>
                    ))}
                  </div>
                </div>
                
                <div className="grid grid-cols-3 gap-3">
                   {filteredIngredients.map(ing => {
                     const picked = selectedIngredients.some(i => i.id === ing.id);
                     return (
                     <button
                       key={ing.id}
                       aria-pressed={picked}
                       onClick={() => (picked ? removeIngredientFromStep(ing.id) : addIngredientToStep(ing))}
                       className={`press-springy p-3 rounded-xl shadow-sm border flex flex-col items-center transition-all ${
                         picked
                           ? 'bg-orange-50 border-toon-primary ring-2 ring-toon-primary/30'
                           : 'bg-white border-gray-100 hover:bg-orange-50 hover:border-orange-200'
                       }`}
                     >
                        <PackAsset
                          src={kitchenAssetPack.ingredient(ing.id)}
                          fallback={ing.emoji}
                          className="text-3xl mb-1"
                          imageClassName="mb-2 h-14 w-14"
                        />
                        <span className="text-xs font-bold text-gray-600 text-center leading-tight">{ing.name}</span>
                     </button>
                     );
                   })}
                   {filteredIngredients.length === 0 && (
                     <div className="col-span-3 rounded-2xl border border-dashed border-orange-200 bg-white p-6 text-center text-sm font-medium text-gray-500">
                       No ingredients match that search.
                     </div>
                   )}
                </div>

             </div>
           )}

           {/* STAGE 2: ACTION — one tap picks the technique AND its tool */}
           {stage === 'action' && (
              <div className="space-y-5">
                {/* Your ingredients, riding along as context */}
                <div className="flex gap-2 overflow-x-auto hide-scrollbar">
                  {selectedIngredients.map((item) => {
                    const data = INGREDIENTS.find((ingredient) => ingredient.id === item.id);
                    return (
                      <span key={item.id} className="flex shrink-0 items-center gap-2 rounded-full bg-white px-3 py-1.5 text-xs font-bold text-toon-dark shadow-sm border border-orange-100">
                        <PackAsset
                          src={kitchenAssetPack.ingredientPresentation(item.id).asset}
                          fallback={data?.emoji ?? '🥣'}
                          imageClassName="h-5 w-5"
                        />
                        {data?.name ?? item.id.replace(/_/g, ' ')}
                      </span>
                    );
                  })}
                </div>

                {/* Station filter pills */}
                <div className="flex gap-2 overflow-x-auto hide-scrollbar" role="tablist" aria-label="Cooking style filter">
                  {([
                    { id: 'all', label: 'Everything', emoji: '✨' },
                    { id: 'prep', label: 'Prep', emoji: '🥬' },
                    { id: 'cook', label: 'Heat', emoji: '🔥' },
                    { id: 'finish', label: 'Plate', emoji: '🍽️' },
                  ] as const).map((pill) => (
                    <button
                      key={pill.id}
                      role="tab"
                      aria-selected={actionFilter === pill.id}
                      onClick={() => setActionFilter(pill.id)}
                      className={`press-springy min-h-11 shrink-0 rounded-full px-4 py-2 text-xs font-bold transition-all ${
                        actionFilter === pill.id
                          ? 'bg-toon-dark text-white shadow-md scale-105'
                          : 'bg-white text-gray-500 border border-orange-100 hover:border-toon-secondary'
                      }`}
                    >
                      <span aria-hidden="true" className="mr-1">{pill.emoji}</span>
                      {pill.label}
                    </button>
                  ))}
                </div>

                {compatibleActions.length === 0 ? (
                  <div className="rounded-3xl border border-dashed border-orange-200 bg-white p-6 text-center animate-pop-in">
                    <span aria-hidden="true" className="mb-2 block text-3xl">🤔</span>
                    <p className="font-bold text-toon-dark">These ingredients don't fit in one step.</p>
                    <p className="mt-1 text-sm text-gray-500">Split them across two steps, or set one aside:</p>
                    <div className="mt-4 flex flex-wrap justify-center gap-2">
                      {selectedIngredients.map((item) => {
                        const data = INGREDIENTS.find((ingredient) => ingredient.id === item.id);
                        const suggested = item.id === blockingIngredientId;
                        return (
                          <button
                            key={item.id}
                            onClick={() => {
                              removeIngredientFromStep(item.id);
                            }}
                            className={`press-springy flex min-h-11 items-center gap-1.5 rounded-full px-4 py-2 text-xs font-bold transition-all ${
                              suggested
                                ? 'bg-toon-primary text-white shadow-md animate-glow-pulse'
                                : 'border border-orange-100 bg-orange-50 text-toon-dark hover:border-toon-secondary'
                            }`}
                          >
                            <Trash2 size={12} aria-hidden="true" />
                            {data?.name ?? item.id.replace(/_/g, ' ')}
                            {suggested ? <span aria-hidden="true">✦</span> : null}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                ) : visibleActions.length === 0 ? (
                  <div className="rounded-3xl border border-dashed border-orange-200 bg-white p-6 text-center animate-pop-in">
                    <span aria-hidden="true" className="mb-2 block text-3xl">🍃</span>
                    <p className="font-bold text-toon-dark">Nothing here for these ingredients.</p>
                    <p className="mt-1 text-sm text-gray-500">Try another style above.</p>
                  </div>
                ) : (
                  <>
                    {/* Cooking-card carousel: swipe sideways, tap to choose */}
                    <div className="-mx-6 flex snap-x snap-mandatory gap-4 overflow-x-auto px-8 pb-4 pt-2 hide-scrollbar">
                      {visibleActions.map((a) => {
                        const tool = TOOLS.find((t) => t.id === a.requiresToolId);
                        const station = stationForAction(a);
                        const stationStyle =
                          station === 'cook'
                            ? 'from-orange-50 to-red-50 border-red-100'
                            : station === 'finish'
                              ? 'from-yellow-50 to-amber-50 border-amber-100'
                              : 'from-green-50 to-emerald-50 border-green-100';
                        return (
                          <button
                            key={a.id}
                            onClick={() => handlePickAction(a)}
                            className={`press-springy group relative flex w-[62%] max-w-[240px] shrink-0 snap-center flex-col items-center rounded-[1.75rem] border bg-gradient-to-b ${stationStyle} p-5 pt-6 shadow-toon-soft transition-all hover:-translate-y-1 hover:shadow-toon-lift`}
                          >
                            <span aria-hidden="true" className="toon-twinkle absolute right-4 top-3 text-xs text-toon-secondary">✦</span>
                            <PackAsset
                              src={kitchenAssetPack.action(a.id)}
                              fallback={<span className="text-5xl">{a.icon}</span>}
                              className="mb-3"
                              imageClassName="mb-3 h-24 w-28 rounded-2xl object-contain transition-transform duration-300 group-hover:scale-110 group-hover:-rotate-3"
                            />
                            <span className="font-display text-lg font-semibold text-toon-dark">{a.name}</span>
                            {tool ? (
                              <span className="mt-2 flex items-center gap-1.5 rounded-full bg-white/80 px-3 py-1 text-[11px] font-bold text-gray-600 shadow-sm">
                                <PackAsset
                                  src={kitchenAssetPack.tool(tool.id)}
                                  fallback={<tool.icon size={13} aria-hidden="true" />}
                                  imageClassName="h-4 w-4"
                                />
                                with {tool.name}
                              </span>
                            ) : (
                              <span className="mt-2 rounded-full bg-white/80 px-3 py-1 text-[11px] font-bold text-gray-600 shadow-sm">
                                straight to the plate
                              </span>
                            )}
                          </button>
                        );
                      })}
                    </div>
                    <p className="text-center text-xs font-bold text-gray-400">
                      <span aria-hidden="true">👈</span> Swipe to browse, tap to pick
                    </p>
                  </>
                )}
              </div>
           )}

           {/* STAGE 3: DETAILS */}
           {stage === 'details' && (
              <div className="space-y-8 pb-4">
                <div className="overflow-hidden rounded-[1.75rem] border border-orange-100 bg-white shadow-sm">
                  <div className="px-4 pt-4">
                    <h3 className="font-display text-lg font-semibold text-toon-dark">
                      {selectedAction?.name ?? 'This step'}
                      {selectedIngredientNames[0] ? (
                        <span className="ml-2 text-sm font-normal text-gray-400">{selectedIngredientNames.join(' · ')}</span>
                      ) : null}
                    </h3>
                  </div>
                  {motionPreview ? (
                    <div className="flex justify-center p-4">
                      <MotionScene
                        src={motionPreview}
                        alt={`${selectedAction?.name ?? 'Cooking'} animation`}
                        className="h-48 w-[229px]"
                      />
                    </div>
                  ) : (
                    <div className="flex h-44 flex-col items-center justify-center gap-2 text-gray-400">
                      <Sparkles size={32} className="animate-float" />
                      <p className="text-sm font-semibold">This step's animation is on its way.</p>
                    </div>
                  )}
                </div>

                {isCutAction && (
                  <div>
                    <label className="flex items-center gap-2 font-bold text-toon-dark mb-3"><Scissors className="text-amber-500" /> Cut Shape</label>
                    <div className="grid grid-cols-2 gap-2">
                      {detailCutShapes.map(shape => (
                        <button
                          key={shape.id}
                          onClick={() => updateSettings({ cutShape: shape.label })}
                          className={`px-4 py-3 rounded-2xl text-sm font-bold border transition-colors text-left ${
                            activeStep.settings?.cutShape === shape.label
                              ? 'bg-amber-500 text-white border-amber-500'
                              : 'bg-white text-gray-600 border-gray-200'
                          }`}
                        >
                          <div className="flex items-center gap-2">
                            <PackAsset
                              src={kitchenAssetPack.cutShape(shape.id)}
                              fallback={shape.emoji}
                              imageClassName="h-7 w-7"
                            />
                            <span>{shape.label}</span>
                          </div>
                          <div className="mt-1 text-[11px] opacity-80 font-medium">{shape.description}</div>
                        </button>
                      ))}
                    </div>
                  </div>
                )}

                {selectedAction?.requiresHeat && (
                  <div>
                    <label className="flex items-center gap-2 font-bold text-toon-dark mb-3">
                      <Thermometer className="text-red-500" /> Heat Level
                    </label>
                    <div className="flex flex-wrap gap-2">
                      {TEMPERATURES.map(t => (
                        <button
                          key={t}
                          onClick={() => updateSettings({ temperature: t })}
                          className={`min-h-11 px-4 py-2 rounded-full text-sm font-bold border transition-colors ${
                            activeStep.settings?.temperature === t
                              ? 'bg-red-500 text-white border-red-500'
                              : 'bg-white text-gray-500 border-gray-200'
                          }`}
                        >
                          {t}
                        </button>
                      ))}
                    </div>
                  </div>
                )}

                {activeStep.station === 'cook' && (
                  <div>
                    <label className="flex items-center gap-2 font-bold text-toon-dark mb-3"><Soup className="text-orange-500" /> Cooking Method</label>
                    <div className="flex flex-wrap gap-2">
                      {COOK_METHODS.map(method => (
                        <button
                          key={method.id}
                          onClick={() => updateSettings({ cookMethod: method.label })}
                          className={`min-h-11 px-4 py-2 rounded-full text-sm font-bold border transition-colors ${
                            activeStep.settings?.cookMethod === method.label
                              ? 'bg-orange-500 text-white border-orange-500'
                              : 'bg-white text-gray-500 border-gray-200'
                          }`}
                        >
                          <span className="flex items-center gap-2">
                            <PackAsset
                              src={kitchenAssetPack.cookMethod(method.id)}
                              fallback={method.emoji}
                              imageClassName="h-7 w-7"
                            />
                            <span>{method.label}</span>
                          </span>
                        </button>
                      ))}
                    </div>
                  </div>
                )}

                <div>
                  <label className="flex items-center gap-2 font-bold text-toon-dark mb-3"><Clock className="text-blue-500"/> Duration</label>
                  <div className="flex flex-wrap gap-2">
                    {TIMES.map(t => (
                      <button
                        key={t}
                        onClick={() => updateSettings({ duration: t })}
                        className={`min-h-11 px-4 py-2 rounded-full text-sm font-bold border transition-colors ${
                          activeStep.settings?.duration === t
                            ? 'bg-blue-500 text-white border-blue-500'
                            : 'bg-white text-gray-500 border-gray-200'
                        }`}
                      >
                        {t}
                      </button>
                    ))}
                  </div>
                </div>

                {activeStep.station === 'cook' && (
                  <div>
                    <label className="flex items-center gap-2 font-bold text-toon-dark mb-3"><Droplets className="text-cyan-500"/> Liquid Added</label>
                    <div className="flex flex-wrap gap-2">
                      {DETAIL_CHIPS.filter(chip =>
                        ['olive_oil', 'vegetable_oil', 'butter', 'sesame_oil', 'water', 'broth', 'stock', 'soy_sauce', 'vinegar', 'coconut_milk'].includes(chip.id),
                      ).map(chip => (
                        <button
                          key={chip.id}
                          onClick={() => updateSettings({
                            oil: ['olive_oil', 'vegetable_oil', 'butter', 'sesame_oil'].includes(chip.id) ? chip.label : activeStep.settings?.oil,
                            liquid: ['water', 'broth', 'stock', 'soy_sauce', 'vinegar', 'coconut_milk'].includes(chip.id) ? chip.label : activeStep.settings?.liquid,
                          })}
                          className={`min-h-11 px-4 py-2 rounded-full text-sm font-bold border transition-colors ${
                            activeStep.settings?.oil === chip.label || activeStep.settings?.liquid === chip.label
                              ? 'bg-cyan-500 text-white border-cyan-500'
                              : 'bg-white text-gray-500 border-gray-200'
                          }`}
                        >
                          <span className="flex items-center gap-2">
                            <PackAsset
                              src={kitchenAssetPack.detail(chip.id)}
                              fallback={chip.emoji}
                              imageClassName="h-7 w-7"
                            />
                            <span>{chip.label}</span>
                          </span>
                        </button>
                      ))}
                    </div>
                  </div>
                )}

                {activeStep.station === 'cook' && (
                  <div>
                    <label className="flex items-center gap-2 font-bold text-toon-dark mb-3"><Droplets className="text-blue-500"/> Water Added</label>
                    <div className="flex flex-wrap gap-2">
                      {WATER_LEVELS.map(level => (
                        <button
                          key={level}
                          onClick={() => updateSettings({ waterLevel: level })}
                          className={`min-h-11 px-4 py-2 rounded-full text-sm font-bold border transition-colors ${
                            activeStep.settings?.waterLevel === level
                              ? 'bg-blue-500 text-white border-blue-500'
                              : 'bg-white text-gray-500 border-gray-200'
                          }`}
                        >
                          {level}
                        </button>
                      ))}
                    </div>
                  </div>
                )}

                {activeStep.station === 'finish' && (
                  <div>
                    <label className="flex items-center gap-2 font-bold text-toon-dark mb-3"><Leaf className="text-green-500" /> Finish Detail</label>
                    <div className="flex flex-wrap gap-2">
                      {DETAIL_CHIPS.filter(chip => ['garnished', 'sprinkled', 'drizzled', 'crispy', 'tender', 'saucy'].includes(chip.id)).map(chip => (
                        <button
                          key={chip.id}
                          onClick={() =>
                            updateSettings({
                              garnish: chip.label,
                              texture: ['crispy', 'tender', 'saucy'].includes(chip.id) ? chip.label : activeStep.settings?.texture,
                            })
                          }
                          className={`min-h-11 px-4 py-2 rounded-full text-sm font-bold border transition-colors ${
                            activeStep.settings?.garnish === chip.label || activeStep.settings?.texture === chip.label
                              ? 'bg-green-500 text-white border-green-500'
                              : 'bg-white text-gray-500 border-gray-200'
                          }`}
                        >
                          <span className="flex items-center gap-2">
                            <PackAsset
                              src={kitchenAssetPack.detail(chip.id)}
                              fallback={chip.emoji}
                              imageClassName="h-7 w-7"
                            />
                            <span>{chip.label}</span>
                          </span>
                        </button>
                      ))}
                    </div>
                  </div>
                )}

              </div>
           )}

        </div>

        {/* Footer CTAs live outside the scroll area so no option can hide behind them */}
        {stage === 'ingredients' && (
          <div className="border-t border-orange-100 bg-[#FFF5F0]/95 px-6 pb-6 pt-3 backdrop-blur-md">
            <button
              onClick={() => setStage('action')}
              disabled={selectedIngredients.length === 0}
              className="press-springy w-full bg-toon-dark text-white py-4 rounded-2xl font-bold shadow-lg transition-all hover:shadow-xl disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {selectedIngredients.length === 0
                ? 'Pick your ingredients'
                : `Cook with ${selectedIngredients.length === 1 ? 'this' : `these ${selectedIngredients.length}`} →`}
            </button>
          </div>
        )}
        {stage === 'details' && (
          <div className="border-t border-orange-100 bg-[#FFF5F0]/95 px-6 pb-6 pt-3 backdrop-blur-md">
            <button
              onClick={handleFinishStep}
              className="press-springy btn-candy w-full text-white py-4 rounded-2xl font-display font-semibold text-xl"
            >
              {editingStepId ? (
                <span className="flex items-center justify-center gap-2"><Check size={20} /> Save Step</span>
              ) : (
                'Add Step to Recipe'
              )}
            </button>
          </div>
        )}
      </div>
    )
  }

  return view === 'list' ? renderTimeline() : renderEditor();
};
