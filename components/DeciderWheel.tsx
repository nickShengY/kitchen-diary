import React, { useEffect, useRef, useState } from 'react';
import { Camera, Sparkles, RefreshCw, Edit2, X, Plus, ChevronLeft, ChevronRight, Settings } from 'lucide-react';
import { analyzeMenuImage, getFoodDescription } from '../services/geminiService';
import { fetchCuisineWheelData } from '../services/liveDataService';
import { CuisineCategory } from '../types';

const createLocalId = (): string => {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID();
  }
  return `${Date.now()}-${Math.random().toString(16).slice(2)}`;
};

export const DeciderWheel: React.FC = () => {
  const [mode, setMode] = useState<'wheel' | 'scan'>('wheel');
  const [cuisines, setCuisines] = useState<CuisineCategory[]>([]);
  const [phase, setPhase] = useState<'CATEGORY' | 'DISH'>('CATEGORY');
  const [selectedCuisine, setSelectedCuisine] = useState<CuisineCategory | null>(null);
  const [selectedDish, setSelectedDish] = useState<string | null>(null);
  const [isSpinning, setIsSpinning] = useState(false);
  const [isLoadingCuisines, setIsLoadingCuisines] = useState(true);
  const [cuisineError, setCuisineError] = useState<string | null>(null);

  const [isEditing, setIsEditing] = useState(false);
  const [editCategory, setEditCategory] = useState<CuisineCategory | null>(null);
  const [editInputValue, setEditInputValue] = useState('');

  const [scanImage, setScanImage] = useState<string | null>(null);
  const [scanResult, setScanResult] = useState<{ name: string; desc: string } | null>(null);
  const [isScanning, setIsScanning] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    let cancelled = false;

    const loadCuisines = async () => {
      setIsLoadingCuisines(true);
      setCuisineError(null);
      try {
        const liveCuisines = await fetchCuisineWheelData();
        if (cancelled) return;
        setCuisines(liveCuisines);
      } catch {
        if (cancelled) return;
        setCuisines([]);
        setCuisineError('Unable to load live cuisine categories.');
      } finally {
        if (!cancelled) setIsLoadingCuisines(false);
      }
    };

    loadCuisines();
    return () => {
      cancelled = true;
    };
  }, []);

  const spin = () => {
    if (isSpinning || cuisines.length === 0) return;
    setIsSpinning(true);

    setTimeout(() => {
      if (phase === 'CATEGORY') {
        const randomCuisine = cuisines[Math.floor(Math.random() * cuisines.length)];
        setSelectedCuisine(randomCuisine);
      } else if (selectedCuisine) {
        const dishes = selectedCuisine.dishes;
        if (dishes.length > 0) {
          setSelectedDish(dishes[Math.floor(Math.random() * dishes.length)]);
        }
      }
      setIsSpinning(false);
    }, 3000);
  };

  const handlePhase2Start = () => {
    if (!selectedCuisine) return;
    setPhase('DISH');
    setSelectedDish(null);
  };

  const resetAll = () => {
    setPhase('CATEGORY');
    setSelectedCuisine(null);
    setSelectedDish(null);
  };

  const addCuisine = (name: string) => {
    setCuisines((previous) => [
      ...previous,
      {
        id: createLocalId(),
        name,
        emoji: '🍽️',
        dishes: [],
      },
    ]);
  };

  const deleteCuisine = (id: string) => {
    setCuisines((previous) => previous.filter((cuisine) => cuisine.id !== id));
    if (selectedCuisine?.id === id) resetAll();
    if (editCategory?.id === id) setEditCategory(null);
  };

  const addDish = (cuisineId: string, dishName: string) => {
    setCuisines((previous) =>
      previous.map((cuisine) =>
        cuisine.id === cuisineId ? { ...cuisine, dishes: [...cuisine.dishes, dishName] } : cuisine,
      ),
    );
    if (editCategory?.id === cuisineId) {
      setEditCategory({ ...editCategory, dishes: [...editCategory.dishes, dishName] });
    }
  };

  const deleteDish = (cuisineId: string, dishName: string) => {
    setCuisines((previous) =>
      previous.map((cuisine) =>
        cuisine.id === cuisineId
          ? { ...cuisine, dishes: cuisine.dishes.filter((dish) => dish !== dishName) }
          : cuisine,
      ),
    );
    if (editCategory?.id === cuisineId) {
      setEditCategory({
        ...editCategory,
        dishes: editCategory.dishes.filter((dish) => dish !== dishName),
      });
    }
  };

  const handleAddItem = () => {
    const value = editInputValue.trim();
    if (!value) return;
    if (editCategory) addDish(editCategory.id, value);
    else addCuisine(value);
    setEditInputValue('');
  };

  const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onloadend = async () => {
      const base64 = reader.result as string;
      setScanImage(base64);
      setIsScanning(true);

      const cleanBase64 = base64.split(',')[1];
      const menuItems = await analyzeMenuImage(cleanBase64);
      setIsScanning(false);

      if (menuItems.length > 0) {
        const selected = menuItems[Math.floor(Math.random() * menuItems.length)];
        const description = await getFoodDescription(selected.name);
        setScanResult({
          name: selected.name,
          desc: selected.description || description,
        });
      }
    };

    reader.readAsDataURL(file);
  };

  return (
    <div className="pb-32 px-4 min-h-screen bg-[#FFF5F0] overflow-hidden">
      <header className="py-6 flex justify-between items-center sticky top-0 z-10 bg-[#FFF5F0]/90 backdrop-blur">
        <h1 className="text-3xl font-bold text-toon-dark">Decider</h1>
        <div className="flex bg-white rounded-full p-1 shadow-sm border border-gray-100">
          <button
            onClick={() => setMode('wheel')}
            className={`px-4 py-1.5 rounded-full text-xs font-bold transition-all ${mode === 'wheel' ? 'bg-toon-dark text-white' : 'text-gray-400'}`}
          >
            Wheel
          </button>
          <button
            onClick={() => setMode('scan')}
            className={`px-4 py-1.5 rounded-full text-xs font-bold transition-all ${mode === 'scan' ? 'bg-toon-dark text-white' : 'text-gray-400'}`}
          >
            Scan
          </button>
        </div>
      </header>

      {mode === 'wheel' && (
        <div className="flex flex-col items-center mt-4">
          <div className="flex items-center gap-2 mb-6 text-sm font-bold text-gray-400">
            <span className={`px-3 py-1 rounded-full ${phase === 'CATEGORY' ? 'bg-toon-primary text-white' : 'bg-white'}`}>1. Cuisine</span>
            <ChevronRight size={16} />
            <span className={`px-3 py-1 rounded-full ${phase === 'DISH' ? 'bg-toon-primary text-white' : 'bg-white'}`}>2. Dish</span>
          </div>

          <div className="w-full h-[320px] bg-white rounded-3xl shadow-sm border border-orange-100 mb-8 p-4 overflow-y-auto">
            {isLoadingCuisines && (
              <div className="h-full flex flex-col items-center justify-center text-gray-500">
                <RefreshCw className="animate-spin mb-2" />
                Loading cuisines...
              </div>
            )}

            {!isLoadingCuisines && cuisineError && (
              <div className="h-full flex items-center justify-center text-red-500 text-sm text-center">{cuisineError}</div>
            )}

            {!isLoadingCuisines && !cuisineError && (
              <>
                {!selectedCuisine || (phase === 'CATEGORY' && isSpinning) ? (
                  <div className="grid grid-cols-2 gap-3">
                    {cuisines.map((cuisine) => (
                      <div key={cuisine.id} className="bg-orange-50 rounded-xl p-3 text-center border border-orange-100">
                        <div className="text-2xl mb-1">{cuisine.emoji}</div>
                        <div className="font-bold text-sm text-toon-dark">{cuisine.name}</div>
                      </div>
                    ))}
                  </div>
                ) : !selectedDish && phase === 'DISH' ? (
                  <div className="grid grid-cols-1 gap-2">
                    {selectedCuisine.dishes.map((dish, index) => (
                      <div key={`${selectedCuisine.id}-${index}`} className="bg-orange-50 rounded-xl p-3 text-toon-dark font-bold text-center border border-orange-100">
                        {dish}
                      </div>
                    ))}
                  </div>
                ) : selectedDish ? (
                  <div className="h-full flex flex-col items-center justify-center animate-in zoom-in duration-500">
                    <div className="text-8xl mb-4">{selectedCuisine?.emoji}</div>
                    <h2 className="text-4xl font-bold text-toon-dark text-center mb-2">{selectedDish}</h2>
                    <p className="text-gray-400 font-bold uppercase tracking-widest text-sm">Bon Appetit</p>
                  </div>
                ) : (
                  <div className="h-full flex flex-col items-center justify-center animate-in zoom-in">
                    <div className="text-6xl mb-4">{selectedCuisine?.emoji}</div>
                    <h2 className="text-3xl font-bold text-toon-dark mb-4">{selectedCuisine?.name}</h2>
                    <button
                      onClick={handlePhase2Start}
                      className="bg-toon-primary text-white font-bold px-8 py-3 rounded-2xl shadow-lg hover:scale-105 transition-transform"
                    >
                      Find a Dish <ChevronRight className="inline ml-1" />
                    </button>
                  </div>
                )}
              </>
            )}
          </div>

          <div className="w-full max-w-xs space-y-3 z-20 mt-4">
            {!selectedDish && (
              <button
                onClick={spin}
                disabled={isSpinning || isLoadingCuisines || cuisines.length === 0 || (phase === 'DISH' && selectedCuisine?.dishes.length === 0)}
                className="w-full bg-toon-dark text-white font-bold py-4 rounded-2xl shadow-[0_6px_0_rgb(60,50,45)] active:shadow-none active:translate-y-[6px] transition-all text-xl flex items-center justify-center gap-2 disabled:opacity-50"
              >
                {isSpinning ? 'Rolling...' : phase === 'CATEGORY' ? 'Spin Cuisine' : 'Spin Dish'}{' '}
                <RefreshCw className={isSpinning ? 'animate-spin' : ''} />
              </button>
            )}

            {selectedDish && (
              <div className="flex gap-2">
                <button onClick={() => { setSelectedDish(null); spin(); }} className="flex-1 bg-toon-primary text-white font-bold py-3 rounded-2xl shadow-sm">
                  Respin Dish
                </button>
                <button onClick={resetAll} className="flex-1 bg-white text-gray-500 font-bold py-3 rounded-2xl border border-gray-200">
                  New Cuisine
                </button>
              </div>
            )}

            {phase === 'DISH' && !isSpinning && !selectedDish && (
              <button
                onClick={() => {
                  setPhase('CATEGORY');
                  setSelectedCuisine(null);
                  setSelectedDish(null);
                }}
                className="w-full text-gray-400 font-bold py-2 hover:text-toon-dark"
              >
                Back to Cuisines
              </button>
            )}

            {!isSpinning && (
              <button
                onClick={() => setIsEditing(true)}
                className="w-full flex items-center justify-center gap-2 text-gray-400 text-sm font-bold py-2 hover:bg-white/50 rounded-xl"
              >
                <Edit2 size={14} /> Customize Wheel
              </button>
            )}
          </div>
        </div>
      )}

      {isEditing && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white w-full max-w-md h-[80vh] rounded-3xl shadow-2xl flex flex-col overflow-hidden animate-in zoom-in-95 duration-200">
            <div className="p-4 border-b border-gray-100 flex justify-between items-center bg-gray-50">
              <div>
                <h3 className="font-bold text-lg text-toon-dark">{editCategory ? `Edit ${editCategory.name}` : 'Edit Cuisines'}</h3>
                <p className="text-xs text-gray-400">{editCategory ? 'Manage dishes' : 'Manage categories'}</p>
              </div>
              <button
                onClick={() => {
                  if (editCategory) setEditCategory(null);
                  else setIsEditing(false);
                }}
                className="bg-white p-2 rounded-full shadow-sm text-gray-500 hover:text-red-500"
              >
                {editCategory ? <ChevronLeft size={20} /> : <X size={20} />}
              </button>
            </div>

            <div className="flex-1 overflow-y-auto p-4 space-y-2">
              {editCategory ? (
                editCategory.dishes.length === 0 ? (
                  <p className="text-center text-gray-400 py-10">No dishes yet.</p>
                ) : (
                  editCategory.dishes.map((dish, index) => (
                    <div key={`${editCategory.id}-dish-${index}`} className="flex items-center justify-between bg-white border border-gray-100 p-3 rounded-xl shadow-sm">
                      <span className="font-medium text-gray-700">{dish}</span>
                      <button onClick={() => deleteDish(editCategory.id, dish)} className="text-red-300 hover:text-red-500">
                        <X size={18} />
                      </button>
                    </div>
                  ))
                )
              ) : (
                cuisines.map((cuisine) => (
                  <div
                    key={cuisine.id}
                    className="flex items-center justify-between bg-white border border-gray-100 p-3 rounded-xl shadow-sm cursor-pointer hover:border-toon-secondary"
                    onClick={() => setEditCategory(cuisine)}
                  >
                    <div className="flex items-center gap-3">
                      <span className="text-2xl">{cuisine.emoji}</span>
                      <span className="font-bold text-gray-700">{cuisine.name}</span>
                      <span className="text-xs bg-gray-100 px-2 py-1 rounded text-gray-500">{cuisine.dishes.length} dishes</span>
                    </div>
                    <div className="flex gap-2">
                      <button onClick={(event) => { event.stopPropagation(); setEditCategory(cuisine); }} className="text-gray-300 hover:text-blue-500">
                        <Settings size={18} />
                      </button>
                      <button onClick={(event) => { event.stopPropagation(); deleteCuisine(cuisine.id); }} className="text-gray-300 hover:text-red-500">
                        <X size={18} />
                      </button>
                    </div>
                  </div>
                ))
              )}
            </div>

            <form
              className="p-4 bg-gray-50 border-t border-gray-100 flex gap-2"
              onSubmit={(event) => {
                event.preventDefault();
                handleAddItem();
              }}
            >
              <input
                name="value"
                value={editInputValue}
                onChange={(event) => setEditInputValue(event.target.value)}
                className="flex-1 px-4 py-3 rounded-xl border border-gray-200 outline-none focus:border-toon-primary"
                placeholder={editCategory ? 'Add a new dish...' : 'Add new cuisine...'}
              />
              <button type="submit" className="bg-toon-primary text-white p-3 rounded-xl shadow-md hover:bg-orange-500">
                <Plus />
              </button>
            </form>
          </div>
        </div>
      )}

      {mode === 'scan' && (
        <div className="flex flex-col items-center justify-center mt-10 px-4">
          {!scanImage ? (
            <div
              onClick={() => fileInputRef.current?.click()}
              className="w-full max-w-sm aspect-[4/5] border-4 border-dashed border-gray-200 rounded-3xl flex flex-col items-center justify-center cursor-pointer hover:bg-white/50 transition-colors group"
            >
              <div className="w-20 h-20 bg-orange-100 rounded-full flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
                <Camera size={40} className="text-orange-400" />
              </div>
              <p className="font-bold text-toon-dark">Snap a Menu</p>
              <p className="text-xs text-gray-400">AI will pick for you</p>
              <input ref={fileInputRef} type="file" accept="image/*" className="hidden" onChange={handleFileUpload} />
            </div>
          ) : (
            <div className="w-full max-w-sm bg-white rounded-3xl p-6 shadow-xl">
              {isScanning ? (
                <div className="text-center py-10">
                  <Sparkles className="mx-auto text-toon-accent animate-spin mb-4" size={40} />
                  <p className="font-bold text-toon-dark">Reading menu...</p>
                </div>
              ) : (
                <div className="text-center animate-in fade-in">
                  <div className="w-full h-40 bg-gray-100 rounded-2xl mb-6 overflow-hidden relative">
                    <img src={scanImage} className="w-full h-full object-cover" />
                    <div className="absolute inset-0 bg-black/20" />
                  </div>
                  <h2 className="text-3xl font-bold text-toon-primary mb-2">{scanResult?.name}</h2>
                  <p className="text-gray-500 text-sm mb-6 italic">"{scanResult?.desc}"</p>
                  <button
                    onClick={() => {
                      setScanImage(null);
                      setScanResult(null);
                    }}
                    className="w-full bg-gray-100 text-gray-600 font-bold py-3 rounded-xl hover:bg-gray-200"
                  >
                    Try Again
                  </button>
                </div>
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
};
