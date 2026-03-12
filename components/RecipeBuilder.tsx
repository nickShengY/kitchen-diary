
import React, { useState, useEffect } from 'react';
import { Plus, Trash2, ChevronRight, Clock, Thermometer, Droplets, Flame, ArrowLeft, Share2, AlertCircle } from 'lucide-react';
import { Ingredient, RecipeStep, Recipe } from '../types';
import { INGREDIENTS, TOOLS, ACTIONS, TEMPERATURES, TIMES, WATER_LEVELS } from '../data/kitchenData';

interface RecipeBuilderProps {
    initialRecipe?: Recipe;
    onExit?: () => void;
}

export const RecipeBuilder: React.FC<RecipeBuilderProps> = ({ initialRecipe, onExit }) => {
  const [recipeName, setRecipeName] = useState(initialRecipe?.title || 'My Delicious Recipe');
  const [steps, setSteps] = useState<RecipeStep[]>(initialRecipe?.steps || []);
  const [view, setView] = useState<'list' | 'editor'>('list');
  
  // Editor State
  const [activeStep, setActiveStep] = useState<Partial<RecipeStep>>({ ingredients: [] });
  const [stage, setStage] = useState<'station' | 'tool' | 'ingredients' | 'action' | 'details'>('station');
  const [warning, setWarning] = useState<string | null>(null);

  // --- SMART FILTERS ---

  const getToolsByStation = (station: string) => TOOLS.filter(t => 
    station === 'prep' ? t.type === 'prep' : 
    station === 'cook' ? (t.type === 'cook' || t.type === 'appliance') : true
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
          const toolMatch = a.requiresToolId === toolId || (!a.requiresToolId && !toolId);
          // Pre-filter actions that would be impossible with currently selected ingredients?
          // If ingredients are selected first (which they are in my flow now), we can filter actions.
          if (activeStep.ingredients && activeStep.ingredients.length > 0) {
             const validForIngredients = isActionValidForIngredients(a.id, activeStep.ingredients);
             return toolMatch && validForIngredients;
          }
          return toolMatch;
      });
  };

  // --- HANDLERS ---

  const handleStartStep = () => {
    setActiveStep({ id: Date.now().toString(), ingredients: [] });
    setStage('station');
    setView('editor');
    setWarning(null);
  };

  const handleFinishStep = () => {
    if (activeStep.actionId) {
      setSteps([...steps, activeStep as RecipeStep]);
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
    <div className="pb-32 bg-[#FFF5F0] min-h-screen">
       <header className="sticky top-0 bg-[#FFF5F0]/95 backdrop-blur-md z-10 px-6 py-4 shadow-sm flex items-center gap-2">
          {onExit && (
              <button onClick={onExit} className="p-2 -ml-2 hover:bg-white rounded-full transition-colors">
                  <ArrowLeft className="text-toon-dark"/>
              </button>
          )}
          <div className="flex-1">
            <input 
                value={recipeName}
                onChange={(e) => setRecipeName(e.target.value)}
                className="text-2xl font-bold text-toon-dark bg-transparent w-full outline-none placeholder-gray-300"
                placeholder="Name your recipe..."
            />
            <p className="text-toon-primary text-sm font-medium mt-1">{steps.length} steps • {steps.length * 5} mins</p>
          </div>
       </header>

       <div className="px-6 py-6 space-y-8">
          {steps.length === 0 && (
            <div className="text-center py-12 opacity-60">
              <div className="text-8xl mb-4 grayscale">🧑‍🍳</div>
              <p className="font-bold text-lg">Your kitchen is empty!</p>
              <p className="text-sm">Tap the big plus button to start cooking.</p>
            </div>
          )}

          {steps.map((step, idx) => {
             const action = ACTIONS.find(a => a.id === step.actionId);
             const tool = TOOLS.find(t => t.id === step.toolId);
             return (
               <div key={step.id} className="relative flex gap-4 animate-in slide-in-from-bottom-5 duration-500" style={{animationDelay: `${idx * 100}ms`}}>
                  {idx !== steps.length - 1 && (
                    <div className="absolute left-[22px] top-12 bottom-[-32px] w-1 bg-gradient-to-b from-toon-secondary to-toon-primary/20 rounded-full"></div>
                  )}
                  
                  <div className={`w-12 h-12 shrink-0 rounded-full flex items-center justify-center text-2xl border-4 z-10 shadow-sm ${step.station === 'cook' ? 'bg-red-50 border-red-100 text-red-500' : 'bg-green-50 border-green-100 text-green-600'}`}>
                    {action?.icon}
                  </div>

                  <div className="flex-1 bg-white p-4 rounded-2xl shadow-[0_4px_20px_rgb(0,0,0,0.05)] border border-orange-50/50">
                     <div className="flex justify-between items-start mb-2">
                        <h3 className="font-bold text-toon-dark text-lg capitalize">
                          {action?.verb} 
                          <span className="text-gray-400 font-normal text-sm ml-2">using {tool?.name}</span>
                        </h3>
                        <button onClick={() => setSteps(steps.filter(s => s.id !== step.id))} className="text-gray-300 hover:text-red-400">
                          <Trash2 size={16} />
                        </button>
                     </div>

                     {/* Ingredients Mini List */}
                     <div className="flex flex-wrap gap-2 mb-3">
                        {step.ingredients.map((si, i) => {
                           const ingData = INGREDIENTS.find(k => k.id === si.id);
                           return (
                             <span key={i} className="bg-orange-50 text-toon-dark text-xs px-2 py-1 rounded-lg border border-orange-100 flex items-center gap-1">
                                {ingData?.emoji} <b>{si.amount} {si.unit}</b> {ingData?.name}
                             </span>
                           )
                        })}
                     </div>

                     {/* Settings Tags */}
                     <div className="flex gap-2 text-xs font-bold">
                        {step.settings?.temperature && (
                          <span className="bg-red-100 text-red-600 px-2 py-1 rounded-md flex items-center gap-1"><Flame size={12}/> {step.settings.temperature}</span>
                        )}
                        {step.settings?.duration && (
                          <span className="bg-blue-100 text-blue-600 px-2 py-1 rounded-md flex items-center gap-1"><Clock size={12}/> {step.settings.duration}</span>
                        )}
                         {step.settings?.waterLevel && (
                          <span className="bg-cyan-100 text-cyan-600 px-2 py-1 rounded-md flex items-center gap-1"><Droplets size={12}/> {step.settings.waterLevel}</span>
                        )}
                     </div>
                  </div>
               </div>
             )
          })}
       </div>

       {steps.length > 0 && (
         <div className="fixed bottom-24 left-6 z-20">
           <button className="bg-white p-3 rounded-full shadow-lg text-toon-dark border hover:bg-gray-50">
             <Share2 size={24} />
           </button>
         </div>
       )}

       <button 
          aria-label="Add step"
          onClick={handleStartStep}
          className="fixed bottom-24 right-6 w-16 h-16 bg-toon-primary text-white rounded-full shadow-xl flex items-center justify-center hover:scale-110 transition-transform z-20 ring-4 ring-orange-100"
        >
          <Plus size={32} strokeWidth={3} />
        </button>
    </div>
  );

  // EDITOR WIZARD
  const renderEditor = () => {
    return (
      <div className="fixed inset-0 bg-[#FFF5F0] z-50 flex flex-col animate-in slide-in-from-bottom duration-300">
        {/* Editor Header */}
        <div className="bg-white px-6 py-4 shadow-sm flex items-center justify-between">
            <button onClick={() => setView('list')} className="p-2 -ml-2 hover:bg-gray-100 rounded-full">
              <ArrowLeft className="text-toon-dark" />
            </button>
            <h2 className="font-bold text-lg text-toon-dark">
              {stage === 'station' && 'Select Station'}
              {stage === 'tool' && 'Choose Tool'}
              {stage === 'ingredients' && 'Add Ingredients'}
              {stage === 'action' && 'Process'}
              {stage === 'details' && 'Cooking Details'}
            </h2>
            <div className="w-10"></div>
        </div>

        {/* Progress Bar */}
        <div className="h-1 bg-gray-100 w-full">
           <div 
             className="h-full bg-toon-primary transition-all duration-300" 
             style={{ width: `${['station', 'tool', 'ingredients', 'action', 'details'].indexOf(stage) * 25}%`}}
           />
        </div>

        <div className="flex-1 overflow-y-auto p-6">
           
           {/* STAGE 1: STATION */}
           {stage === 'station' && (
             <div className="grid grid-cols-1 gap-4">
                {[
                  { id: 'prep', name: 'Prep Station', desc: 'Chop, Mix, Peel', icon: '🥬', color: 'bg-green-100' },
                  { id: 'cook', name: 'Hot Station', desc: 'Stove, Oven, Grill', icon: '🔥', color: 'bg-red-100' },
                  { id: 'finish', name: 'Plating', desc: 'Serve & Garnish', icon: '🍽️', color: 'bg-yellow-100' }
                ].map(s => (
                  <button 
                    key={s.id}
                    onClick={() => { setActiveStep({...activeStep, station: s.id as any}); setStage(s.id === 'finish' ? 'action' : 'tool'); }}
                    className="flex items-center p-6 bg-white rounded-3xl shadow-sm border-2 border-transparent hover:border-toon-secondary hover:shadow-md transition-all text-left"
                  >
                     <div className={`w-16 h-16 ${s.color} rounded-2xl flex items-center justify-center text-3xl mr-6`}>{s.icon}</div>
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
              <div className="grid grid-cols-2 gap-4">
                 {getToolsByStation(activeStep.station!).map(t => (
                   <button
                    key={t.id}
                    onClick={() => { setActiveStep({...activeStep, toolId: t.id}); setStage('ingredients'); }}
                    className="flex flex-col items-center p-6 bg-white rounded-3xl shadow-sm border-2 border-transparent hover:border-toon-primary transition-all"
                   >
                      <t.icon size={48} strokeWidth={1.5} className="text-toon-dark mb-4" />
                      <span className="font-bold text-toon-dark">{t.name}</span>
                   </button>
                 ))}
              </div>
           )}

           {/* STAGE 3: INGREDIENTS */}
           {stage === 'ingredients' && (
             <div className="space-y-6">
                <div className="flex gap-2 overflow-x-auto pb-2 hide-scrollbar">
                   {activeStep.ingredients?.map(i => {
                      const data = INGREDIENTS.find(d => d.id === i.id);
                      return (
                        <div key={i.id} className="bg-toon-primary text-white px-4 py-2 rounded-full flex items-center gap-2 text-sm shadow-md animate-in zoom-in">
                           <span>{data?.emoji} {data?.name}</span>
                           <button onClick={(e) => {e.stopPropagation(); removeIngredientFromStep(i.id)}}><Trash2 size={12}/></button>
                        </div>
                      )
                   })}
                   {activeStep.ingredients?.length === 0 && <span className="text-gray-400 italic px-2">Select items below...</span>}
                </div>
                
                <div className="grid grid-cols-3 gap-3">
                   {INGREDIENTS.map(ing => (
                     <button
                       key={ing.id}
                       onClick={() => addIngredientToStep(ing)}
                       className="bg-white p-3 rounded-xl shadow-sm border border-gray-100 hover:bg-orange-50 flex flex-col items-center"
                     >
                        <span className="text-3xl mb-1">{ing.emoji}</span>
                        <span className="text-xs font-bold text-gray-600 text-center leading-tight">{ing.name}</span>
                     </button>
                   ))}
                </div>

                <button 
                  onClick={() => setStage('action')} 
                  disabled={activeStep.ingredients?.length === 0}
                  className="w-full bg-toon-dark text-white py-4 rounded-2xl font-bold shadow-lg disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Done with Ingredients
                </button>
             </div>
           )}

           {/* STAGE 4: ACTION */}
           {stage === 'action' && (
              <>
                <div className="mb-4 text-gray-500 text-sm px-2">
                    Compatible actions for selected ingredients:
                </div>
                <div className="grid grid-cols-2 gap-4">
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
                            className="bg-white p-6 rounded-3xl shadow-sm border-2 border-transparent hover:border-toon-accent flex flex-col items-center"
                            >
                            <span className="text-4xl mb-3">{a.icon}</span>
                            <span className="font-bold text-toon-dark">{a.name}</span>
                            </button>
                        ))
                    )}
                </div>
              </>
           )}

           {/* STAGE 5: DETAILS */}
           {stage === 'details' && (
              <div className="space-y-8 animate-in fade-in">
                 
                 {/* Temperature */}
                 {ACTIONS.find(a => a.id === activeStep.actionId)?.requiresHeat && (
                   <div>
                      <label className="flex items-center gap-2 font-bold text-toon-dark mb-3"><Thermometer className="text-red-500"/> Heat Level</label>
                      <div className="flex flex-wrap gap-2">
                        {TEMPERATURES.map(t => (
                          <button 
                            key={t}
                            onClick={() => setActiveStep({...activeStep, settings: {...activeStep.settings, temperature: t}})}
                            className={`px-4 py-2 rounded-full text-sm font-bold border transition-colors ${activeStep.settings?.temperature === t ? 'bg-red-500 text-white border-red-500' : 'bg-white text-gray-500 border-gray-200'}`}
                          >
                            {t}
                          </button>
                        ))}
                      </div>
                   </div>
                 )}

                 {/* Time */}
                 <div>
                    <label className="flex items-center gap-2 font-bold text-toon-dark mb-3"><Clock className="text-blue-500"/> Duration</label>
                    <div className="flex flex-wrap gap-2">
                      {TIMES.map(t => (
                        <button 
                          key={t}
                          onClick={() => setActiveStep({...activeStep, settings: {...activeStep.settings, duration: t}})}
                          className={`px-4 py-2 rounded-full text-sm font-bold border transition-colors ${activeStep.settings?.duration === t ? 'bg-blue-500 text-white border-blue-500' : 'bg-white text-gray-500 border-gray-200'}`}
                        >
                          {t}
                        </button>
                      ))}
                    </div>
                 </div>

                 {/* Water/Liquid */}
                 {activeStep.station === 'cook' && (
                   <div>
                      <label className="flex items-center gap-2 font-bold text-toon-dark mb-3"><Droplets className="text-cyan-500"/> Liquid Added</label>
                      <div className="flex flex-wrap gap-2">
                        {WATER_LEVELS.map(t => (
                          <button 
                            key={t}
                            onClick={() => setActiveStep({...activeStep, settings: {...activeStep.settings, waterLevel: t}})}
                            className={`px-4 py-2 rounded-full text-sm font-bold border transition-colors ${activeStep.settings?.waterLevel === t ? 'bg-cyan-500 text-white border-cyan-500' : 'bg-white text-gray-500 border-gray-200'}`}
                          >
                            {t}
                          </button>
                        ))}
                      </div>
                   </div>
                 )}

                 <button 
                  onClick={handleFinishStep}
                  className="w-full bg-toon-primary text-white py-4 rounded-2xl font-bold text-xl shadow-lg mt-8 hover:scale-[1.02] transition-transform"
                >
                  Add Step to Recipe
                </button>

              </div>
           )}

        </div>
      </div>
    )
  }

  return view === 'list' ? renderTimeline() : renderEditor();
};
