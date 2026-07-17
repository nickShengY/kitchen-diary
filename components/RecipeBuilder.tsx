
import React, { useEffect, useMemo, useState } from 'react';
import {
  Plus,
  Trash2,
  ChevronRight,
  Clock,
  Thermometer,
  Droplets,
  ArrowLeft,
  Share2,
  AlertCircle,
  Flame,
  Search,
  Sparkles,
  Layers,
  Image as ImageIcon,
  Scissors,
  Soup,
  Leaf,
} from 'lucide-react';
import { Ingredient, RecipeStep, Recipe } from '../types';
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
import { KitchenAssetRef, isKitchenAssetRef, kitchenAssetPack } from '../services/kitchenAssetPack';

interface RecipeBuilderProps {
    initialRecipe?: Recipe;
    onExit?: () => void;
}

const PackAsset: React.FC<{
  src?: string | KitchenAssetRef;
  fallback: React.ReactNode;
  className?: string;
  imageClassName?: string;
}> = ({ src, fallback, className = '', imageClassName = '' }) => {
  const [resolvedSrc, setResolvedSrc] = useState(
    typeof src === 'string' ? src : src?.url,
  );
  const srcKey = isKitchenAssetRef(src) ? src.path : src;

  useEffect(() => {
    let active = true;

    if (!src) {
      setResolvedSrc(undefined);
      return () => {
        active = false;
      };
    }

    if (typeof src === 'string') {
      setResolvedSrc(src);
      return () => {
        active = false;
      };
    }

    if (src.url) {
      setResolvedSrc(src.url);
      return () => {
        active = false;
      };
    }

    setResolvedSrc(undefined);
    src.load()
      .then((url) => {
        if (active) setResolvedSrc(url);
      })
      .catch(() => {
        if (active) setResolvedSrc(undefined);
      });

    return () => {
      active = false;
    };
  }, [src, srcKey]);

  if (!resolvedSrc) {
    return <span className={className}>{fallback}</span>;
  }

  return (
    <img
      src={resolvedSrc}
      alt=""
      aria-hidden="true"
      className={`object-contain ${imageClassName || className}`}
      loading="lazy"
      decoding="async"
    />
  );
};

const LazyAssetImage: React.FC<{
  src?: string | KitchenAssetRef;
  alt: string;
  className: string;
  loading?: 'eager' | 'lazy';
}> = ({ src, alt, className, loading = 'lazy' }) => {
  const [resolvedSrc, setResolvedSrc] = useState(
    typeof src === 'string' ? src : src?.url,
  );
  const srcKey = isKitchenAssetRef(src) ? src.path : src;

  useEffect(() => {
    let active = true;

    if (!src) {
      setResolvedSrc(undefined);
      return () => {
        active = false;
      };
    }

    if (typeof src === 'string') {
      setResolvedSrc(src);
      return () => {
        active = false;
      };
    }

    if (src.url) {
      setResolvedSrc(src.url);
      return () => {
        active = false;
      };
    }

    setResolvedSrc(undefined);
    src.load()
      .then((url) => {
        if (active) setResolvedSrc(url);
      })
      .catch(() => {
        if (active) setResolvedSrc(undefined);
      });

    return () => {
      active = false;
    };
  }, [src, srcKey]);

  if (!resolvedSrc) return null;

  return (
    <img
      src={resolvedSrc}
      alt={alt}
      className={className}
      loading={loading}
      decoding="async"
    />
  );
};

export const RecipeBuilder: React.FC<RecipeBuilderProps> = ({ initialRecipe, onExit }) => {
  const [recipeName, setRecipeName] = useState(initialRecipe?.title || 'My Delicious Recipe');
  const [steps, setSteps] = useState<RecipeStep[]>(initialRecipe?.steps || []);
  const [view, setView] = useState<'list' | 'editor'>('list');
  const [ingredientSearch, setIngredientSearch] = useState('');
  const [ingredientCategory, setIngredientCategory] = useState<Ingredient['category'] | 'all'>('all');
  
  // Editor State
  const [activeStep, setActiveStep] = useState<Partial<RecipeStep>>({ ingredients: [] });
  const [stage, setStage] = useState<'station' | 'tool' | 'ingredients' | 'action' | 'details'>('station');
  const [warning, setWarning] = useState<string | null>(null);

  // --- SMART FILTERS ---

  const getToolsByStation = (station: string) => TOOLS.filter(t => 
    station === 'prep' ? t.type === 'prep' : 
    station === 'cook' ? (t.type === 'cook' || t.type === 'appliance') :
    station === 'finish' ? t.type === 'finish' : true
  );

  // Logic: Check if selected ingredients are compatible with the action
  const isActionValidForIngredients = (actionId: string, ingredients: {id: string}[]) => {
      const action = ACTIONS.find(a => a.id === actionId);
      if (!action?.validProperties) return true; // No restrictions
      
      // If any ingredient lacks the required property, it's invalid (mostly)
      // Or if at least ONE ingredient has the property? Usually all must be compatible.
      // Let's go with: All ingredients must have at least one matching property with the action requirements?
      // Actually simpler: Can I "Peel" a "Steak"? No. Steak doesn't have 'peelable'.
      
      return ingredients.every(i => {
          const ingData = INGREDIENTS.find(d => d.id === i.id);
          if (!ingData) return true;
          // Check intersection of action.validProperties and ingData.physicalProperties
          return action.validProperties?.some(prop => ingData.physicalProperties.includes(prop));
      });
  };

  const getActionsByTool = (toolId?: string) => {
      return ACTIONS.filter(a => {
          const toolMatch =
            a.requiresToolId === toolId ||
            (!a.requiresToolId && (!toolId || activeStep.station === 'finish'));
          // Pre-filter actions that would be impossible with currently selected ingredients?
          // If ingredients are selected first (which they are in my flow now), we can filter actions.
          if (activeStep.ingredients && activeStep.ingredients.length > 0) {
             const validForIngredients = isActionValidForIngredients(a.id, activeStep.ingredients);
             return toolMatch && validForIngredients;
          }
          return toolMatch;
      });
  };

  const selectedAction = ACTIONS.find(a => a.id === activeStep.actionId);
  const selectedTool = TOOLS.find(t => t.id === activeStep.toolId);
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
  const assetCoverage = useMemo(
    () => kitchenAssetPack.coverageForIngredientIds(INGREDIENTS.map((ingredient) => ingredient.id)),
    [],
  );
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
  const stepSummary = [
    selectedIngredients.length > 0 ? `${selectedIngredients.length} ingredient${selectedIngredients.length === 1 ? '' : 's'}` : null,
    selectedTool?.name,
    selectedAction?.name,
  ].filter(Boolean).join(' • ');

  // --- HANDLERS ---

  const handleStartStep = () => {
    setActiveStep({ id: Date.now().toString(), ingredients: [] });
    setStage('station');
    setView('editor');
    setWarning(null);
  };

  const handleFinishStep = () => {
    if (activeStep.actionId) {
      const completedStep = {
        ...activeStep,
        toolId: activeStep.toolId || (activeStep.station === 'finish' ? 'plate' : activeStep.toolId),
        ingredients: activeStep.ingredients || [],
      } as RecipeStep;
      setSteps([...steps, completedStep]);
      setView('list');
    }
  };

  const addIngredientToStep = (ing: Ingredient) => {
    const currentIngs = activeStep.ingredients || [];
    if (!currentIngs.find(i => i.id === ing.id)) {
      setActiveStep({
        ...activeStep,
        ingredients: [...currentIngs, { id: ing.id, amount: '1', unit: ing.defaultUnit }]
      });
    }
    setWarning(null);
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
            <p className="text-toon-primary text-sm font-medium mt-1">{steps.length} steps • {steps.length * 5} mins</p>
          </div>
       </header>

       <section className="px-6 pt-5 animate-rise">
          <div className="rounded-[1.5rem] toon-card p-4">
            <div className="flex items-center gap-3">
              <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-orange-50 text-toon-primary">
                <ImageIcon size={22} />
              </div>
              <div className="min-w-0 flex-1">
                <p className="text-xs font-bold uppercase tracking-wide text-toon-primary">Visual pantry stocked</p>
                <p className="text-sm font-semibold text-toon-dark">
                  {assetCoverage.covered}/{assetCoverage.total} selectable ingredients have exact art loaded. Motion previews ready for loaded assets; missing art stays visibly generic until its matching asset is added.
                </p>
              </div>
            </div>
          </div>
       </section>

       <div className="px-6 py-6 space-y-8">
          {steps.length === 0 && (
            <div className="text-center py-12 animate-pop-in">
              <div className="relative mx-auto mb-4 h-16 w-16">
                <Sparkles className="h-16 w-16 text-toon-primary animate-float" strokeWidth={1.5} />
              </div>
              <p className="font-display text-lg font-semibold text-toon-dark">Your kitchen is empty!</p>
              <p className="text-sm text-gray-400 mt-1">Tap the big plus button to start cooking.</p>
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
                  
                  <div className={`w-12 h-12 shrink-0 rounded-full flex items-center justify-center text-2xl border-4 z-10 shadow-sm ${
                    step.station === 'cook'
                      ? 'bg-red-50 border-red-100 text-red-500'
                      : step.station === 'finish'
                        ? 'bg-yellow-50 border-yellow-100 text-yellow-600'
                        : 'bg-green-50 border-green-100 text-green-600'
                  }`}>
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
                        <button
                          aria-label={`Delete step ${idx + 1}`}
                          onClick={() => setSteps(steps.filter(s => s.id !== step.id))}
                          className="press-springy flex h-11 w-11 -mt-2 -mr-2 items-center justify-center rounded-full text-gray-300 hover:text-red-400 hover:bg-red-50 transition-colors"
                        >
                          <Trash2 size={16} />
                        </button>
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
                                  fallback={ingData?.emoji ?? 'Generic'}
                                  imageClassName="h-5 w-5"
                                />
                                <b>{si.amount} {si.unit}</b> {ingredientName}
                                {presentation.isGeneric && (
                                  <span className="rounded bg-amber-100 px-1 py-0.5 text-[10px] font-bold text-amber-800">
                                    Generic representation
                                  </span>
                                )}
                             </span>
                           )
                        })}
                     </div>

                     {motionAsset && (
                       <div className="mb-3 overflow-hidden rounded-2xl border border-orange-100 bg-orange-50/60">
                         <div className="flex items-center gap-2 px-3 pt-3 text-xs font-bold text-orange-700">
                           <Sparkles size={14} />
                           Motion preview
                         </div>
                         <LazyAssetImage
                           src={motionAsset}
                           alt={`${action?.name ?? 'Step'} animation preview`}
                           className="h-28 w-full object-contain p-2"
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
           <button aria-label="Share recipe" className="press-springy flex h-12 w-12 items-center justify-center rounded-full border border-orange-100 bg-white shadow-lg text-toon-dark hover:bg-orange-50 transition-colors">
             <Share2 size={24} />
           </button>
         </div>
       )}

       <button
          aria-label="Add step"
          onClick={handleStartStep}
          className="press-springy fixed bottom-24 right-6 w-16 h-16 bg-toon-primary text-white rounded-full shadow-xl flex items-center justify-center hover:scale-110 hover:bg-toon-primary-deep transition-all z-20 ring-4 ring-orange-100 animate-glow-pulse"
        >
          <Plus size={32} strokeWidth={3} />
        </button>
    </div>
  );

  // EDITOR WIZARD
  const STAGE_ORDER = ['station', 'tool', 'ingredients', 'action', 'details'] as const;

  const handleEditorBack = () => {
    switch (stage) {
      case 'tool':
        setStage('station');
        break;
      case 'ingredients':
        setStage('tool');
        break;
      case 'action':
        setStage(activeStep.station === 'finish' ? 'station' : 'ingredients');
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
              aria-label={stage === 'station' ? 'Close step editor' : 'Go back a step'}
              onClick={handleEditorBack}
              className="press-springy -ml-2 flex h-11 w-11 items-center justify-center rounded-full hover:bg-gray-100 transition-colors"
            >
              <ArrowLeft className="text-toon-dark" />
            </button>
            <div className="text-center">
              <h2 className="font-display font-semibold text-lg text-toon-dark leading-tight">
                {stage === 'station' && 'Select Station'}
                {stage === 'tool' && 'Choose Tool'}
                {stage === 'ingredients' && 'Add Ingredients'}
                {stage === 'action' && 'Process'}
                {stage === 'details' && 'Cooking Details'}
              </h2>
              <p className="text-[11px] font-bold text-gray-400">Step {stageIndex + 1} of {STAGE_ORDER.length}</p>
            </div>
            <div className="w-10"></div>
        </div>

        {/* Progress Bar */}
        <div className="h-1.5 bg-orange-100/70 w-full" role="progressbar" aria-valuemin={1} aria-valuemax={5} aria-valuenow={stageIndex + 1} aria-label="Step editor progress">
           <div
             className="h-full rounded-r-full bg-gradient-to-r from-toon-secondary to-toon-primary transition-all duration-500 ease-out"
             style={{ width: `${((stageIndex + 1) / STAGE_ORDER.length) * 100}%`}}
           />
        </div>

        <div key={stage} className="flex-1 overflow-y-auto p-6 animate-rise">
           
           {/* STAGE 1: STATION */}
           {stage === 'station' && (
             <div className="grid grid-cols-1 gap-4 stagger-children">
                {[
                  { id: 'prep', name: 'Prep Station', desc: 'Chop, Mix, Peel', icon: '🥬', color: 'bg-green-100' },
                  { id: 'cook', name: 'Hot Station', desc: 'Stove, Oven, Grill', icon: '🔥', color: 'bg-red-100' },
                  { id: 'finish', name: 'Plating', desc: 'Serve & Garnish', icon: '🍽️', color: 'bg-yellow-100' }
                ].map(s => (
                  <button 
                    key={s.id}
                    onClick={() => {
                      setActiveStep({
                        ...activeStep,
                        station: s.id as any,
                        toolId: s.id === 'finish' ? 'plate' : activeStep.toolId,
                      });
                      setStage(s.id === 'finish' ? 'action' : 'tool');
                    }}
                    className="press-springy group flex items-center p-6 bg-white rounded-3xl shadow-toon-soft border-2 border-transparent hover:border-toon-secondary hover:shadow-md transition-all text-left"
                  >
                     <div className={`w-16 h-16 ${s.color} rounded-2xl flex items-center justify-center text-3xl mr-6 transition-transform duration-300 group-hover:scale-110 group-hover:-rotate-6`}>{s.icon}</div>
                     <div>
                        <h3 className="text-xl font-bold text-toon-dark">{s.name}</h3>
                        <p className="text-gray-500">{s.desc}</p>
                     </div>
                     <ChevronRight className="ml-auto text-gray-300" />
                  </button>
                ))}
             </div>
           )}

           {/* STAGE 2: TOOL */}
           {stage === 'tool' && (
              <div className="grid grid-cols-2 gap-4 stagger-children">
                 {getToolsByStation(activeStep.station!).map(t => (
                   <button
                    key={t.id}
                    onClick={() => { setActiveStep({...activeStep, toolId: t.id}); setStage('ingredients'); }}
                    className="press-springy flex flex-col items-center p-6 bg-white rounded-3xl shadow-toon-soft border-2 border-transparent hover:border-toon-primary hover:shadow-md transition-all"
                   >
                      <PackAsset
                        src={kitchenAssetPack.tool(t.id)}
                        fallback={<t.icon size={48} strokeWidth={1.5} className="text-toon-dark" />}
                        imageClassName="mb-4 h-14 w-14"
                      />
                      <span className="font-bold text-toon-dark">{t.name}</span>
                   </button>
                 ))}
              </div>
           )}

           {/* STAGE 3: INGREDIENTS */}
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
                             fallback={data?.emoji ?? 'Generic'}
                             imageClassName="h-5 w-5 rounded-full bg-white/20"
                           />
                           <span>{ingredientName}</span>
                           {presentation.isGeneric && <span className="text-[10px] font-bold text-orange-100">Generic representation</span>}
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
                  <div className="mb-3 flex items-center justify-between gap-3">
                    <div>
                      <p className="text-xs font-bold uppercase tracking-wide text-toon-primary">Ingredient library</p>
                      <p className="text-sm font-semibold text-toon-dark">
                        {filteredIngredients.length} shown from {INGREDIENTS.length} recipe-ready ingredients
                      </p>
                    </div>
                    <div className="flex items-center gap-1 rounded-full bg-green-50 px-3 py-1 text-xs font-bold text-green-700">
                      <Layers size={13} />
                      {assetCoverage.covered} art-backed
                    </div>
                  </div>

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

           {/* STAGE 4: ACTION */}
           {stage === 'action' && (
              <>
                <div className="mb-4 rounded-3xl border border-orange-100 bg-white p-4 shadow-sm">
                  <p className="text-xs font-bold uppercase tracking-wide text-toon-primary">This step</p>
                  <p className="text-base font-bold text-toon-dark">{stepSummary || 'Choose what happens next'}</p>
                  {selectedIngredients.length > 0 && (
                    <div className="mt-3 flex gap-2 overflow-x-auto hide-scrollbar">
                      {selectedIngredients.map((item) => {
                        const data = INGREDIENTS.find((ingredient) => ingredient.id === item.id);
                        const presentation = kitchenAssetPack.ingredientPresentation(item.id);
                        const ingredientName = data?.name ?? item.id.replace(/_/g, ' ');
                        return (
                          <span key={item.id} className="flex items-center gap-2 rounded-full bg-orange-50 px-3 py-1 text-xs font-bold text-toon-dark">
                            <PackAsset
                              src={presentation.asset}
                              fallback={data?.emoji ?? 'Generic'}
                              imageClassName="h-5 w-5"
                            />
                            {ingredientName}
                            {presentation.isGeneric && <span className="text-[10px] text-amber-800">Generic representation</span>}
                          </span>
                        );
                      })}
                    </div>
                  )}
                </div>
                <div className="grid grid-cols-2 gap-4 stagger-children">
                    {getActionsByTool(activeStep.toolId).length === 0 ? (
                        <div className="col-span-2 text-center py-10 text-gray-400">
                             <AlertCircle className="mx-auto mb-2"/>
                             <p>No valid actions for these ingredients with this tool.</p>
                             <button onClick={() => setStage('tool')} className="text-toon-primary underline mt-2">Change Tool</button>
                        </div>
                    ) : (
                        getActionsByTool(activeStep.toolId).map(a => (
                            <button
                            key={a.id}
                            onClick={() => { setActiveStep({...activeStep, actionId: a.id}); setStage('details'); }}
                            className="press-springy bg-white p-6 rounded-3xl shadow-toon-soft border-2 border-transparent hover:border-toon-accent hover:shadow-md transition-all flex flex-col items-center"
                            >
                            <PackAsset
                              src={kitchenAssetPack.action(a.id)}
                              fallback={a.icon}
                              className="text-4xl mb-3"
                              imageClassName="mb-3 h-20 w-24 rounded-2xl object-contain"
                            />
                            <span className="font-bold text-toon-dark">{a.name}</span>
                            {selectedIngredientNames[0] && (
                              <span className="mt-1 text-xs font-semibold text-gray-400">
                                {selectedIngredientNames[0]}
                              </span>
                            )}
                            </button>
                        ))
                    )}
                </div>
              </>
           )}

           {/* STAGE 5: DETAILS */}
           {stage === 'details' && (
              <div className="space-y-8 pb-4">
                <div className="overflow-hidden rounded-[1.75rem] border border-orange-100 bg-white shadow-sm">
                  <div className="flex items-center justify-between gap-3 px-4 pt-4">
                    <div>
                      <p className="text-xs font-bold uppercase tracking-wide text-toon-primary">Step animation</p>
                      <h3 className="text-lg font-bold text-toon-dark">
                        {selectedAction?.name ?? 'Choose an action'} preview
                      </h3>
                      {stepSummary && (
                        <p className="mt-1 text-xs font-bold text-gray-400">{stepSummary}</p>
                      )}
                    </div>
                    <div className="rounded-full bg-orange-50 px-3 py-1 text-xs font-bold text-orange-700">
                      GIF-ready
                    </div>
                  </div>
                  {motionPreview ? (
                    <LazyAssetImage
                      src={motionPreview}
                      alt={`${selectedAction?.name ?? 'Cooking'} motion preview`}
                      className="h-48 w-full object-contain p-4"
                      loading="eager"
                    />
                  ) : (
                    <div className="flex h-44 flex-col items-center justify-center gap-2 text-gray-400">
                      <Sparkles size={32} />
                      <p className="text-sm font-semibold">Select ingredients and an action to preview motion.</p>
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
              Done with Ingredients
            </button>
          </div>
        )}
        {stage === 'details' && (
          <div className="border-t border-orange-100 bg-[#FFF5F0]/95 px-6 pb-6 pt-3 backdrop-blur-md">
            <button
              onClick={handleFinishStep}
              className="press-springy w-full bg-toon-primary text-white py-4 rounded-2xl font-display font-semibold text-xl shadow-toon-glow hover:bg-toon-primary-deep transition-colors"
            >
              Add Step to Recipe
            </button>
          </div>
        )}
      </div>
    )
  }

  return view === 'list' ? renderTimeline() : renderEditor();
};
