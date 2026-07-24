import React, { useEffect, useRef, useState } from 'react';
import {
  Camera,
  Sparkles,
  RefreshCw,
  Edit2,
  X,
  Plus,
  ChevronLeft,
  ChevronRight,
  Settings,
} from 'lucide-react';
import { analyzeMenuImage, getFoodDescription } from '../services/geminiService';
import { fetchCuisineWheelData } from '../services/liveDataService';
import { CUISINE_CATEGORIES } from '../data/kitchenData';
import { CuisineCategory } from '../types';

const createLocalId = (): string => {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID();
  }

  return `${Date.now()}-${Math.random().toString(16).slice(2)}`;
};

const CONFETTI_COLORS = ['#FF8E72', '#FFC482', '#6EC6CA', '#F9DC5C', '#FF9EAA'];

const ConfettiBurst: React.FC = () => (
  <div aria-hidden="true" className="pointer-events-none absolute inset-x-0 top-0 h-0 overflow-visible">
    {Array.from({ length: 26 }).map((_, index) => (
      <span
        key={index}
        className="confetti-piece"
        style={{
          left: `${3 + index * 3.7}%`,
          backgroundColor: CONFETTI_COLORS[index % CONFETTI_COLORS.length],
          // Mix of ribbons, dots, and squares so the burst reads hand-tossed
          borderRadius: index % 3 === 0 ? '9999px' : index % 3 === 1 ? '2px' : '40% 60% 55% 45%',
          width: index % 3 === 0 ? '7px' : '9px',
          height: index % 3 === 0 ? '7px' : '13px',
          animationDelay: `${(index % 7) * 80}ms`,
          animationDuration: `${1 + (index % 4) * 0.15}s`,
          ['--confetti-x' as string]: `${(index % 2 === 0 ? 1 : -1) * (10 + (index % 5) * 16)}px`,
          ['--confetti-spin' as string]: `${200 + (index % 6) * 70}deg`,
        }}
      />
    ))}
  </div>
);

export const DeciderWheel: React.FC = () => {
  const [mode, setMode] = useState<'wheel' | 'scan'>('wheel');
  const [cuisines, setCuisines] = useState<CuisineCategory[]>([]);
  const [phase, setPhase] = useState<'CATEGORY' | 'DISH'>('CATEGORY');
  const [selectedCuisine, setSelectedCuisine] = useState<CuisineCategory | null>(null);
  const [selectedDish, setSelectedDish] = useState<string | null>(null);
  const [isSpinning, setIsSpinning] = useState(false);
  const [spotlightIndex, setSpotlightIndex] = useState<number | null>(null);
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

        if (liveCuisines.length > 0) {
          setCuisines(liveCuisines);
        } else {
          setCuisines(CUISINE_CATEGORIES);
          setCuisineError('Spinning with our starter cuisines today!');
        }
      } catch {
        if (cancelled) return;
        setCuisines(CUISINE_CATEGORIES);
        setCuisineError('Spinning with our starter cuisines today!');
      } finally {
        if (!cancelled) setIsLoadingCuisines(false);
      }
    };

    loadCuisines();

    return () => {
      cancelled = true;
    };
  }, []);

  // While the wheel "spins", a spotlight hops across the options like a roulette.
  useEffect(() => {
    if (!isSpinning) {
      setSpotlightIndex(null);
      return;
    }

    const optionCount =
      phase === 'CATEGORY' ? cuisines.length : selectedCuisine?.dishes.length ?? 0;
    if (optionCount === 0) return;

    let tick = 0;
    const interval = window.setInterval(() => {
      tick += 1;
      setSpotlightIndex(tick % optionCount);
    }, 110);

    return () => window.clearInterval(interval);
  }, [isSpinning, phase, cuisines.length, selectedCuisine]);

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
        emoji: '\u{1F37D}️',
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
        cuisine.id === cuisineId
          ? { ...cuisine, dishes: [...cuisine.dishes, dishName] }
          : cuisine,
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
      } else {
        setScanResult({
          name: "We couldn't read that menu",
          desc: 'Try a brighter photo with the dish names in focus.',
        });
      }
    };

    reader.readAsDataURL(file);
  };

  return (
    <div className="min-h-screen overflow-hidden px-4 pb-32">
      <header className="sticky top-0 z-10 flex items-center justify-between bg-[#FFF5F0]/90 py-6 backdrop-blur">
        <div className="animate-rise">
          <p className="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-[0.2em] text-toon-primary">
            <span aria-hidden="true" className="toon-twinkle inline-block">✦</span>
            Can't choose?
          </p>
          <h1 className="font-display text-3xl font-semibold leading-tight">
            <span className="text-candy">Decide</span>{' '}
            <span aria-hidden="true" className="inline-block animate-bob text-2xl">🎲</span>
          </h1>
        </div>
        <div className="flex rounded-full border border-orange-100 bg-white p-1 shadow-toon-soft">
          <button
            onClick={() => setMode('wheel')}
            aria-pressed={mode === 'wheel'}
            className={`rounded-full px-4 py-1.5 text-xs font-bold transition-all duration-200 ${mode === 'wheel' ? 'bg-toon-dark text-white shadow-md' : 'text-gray-400 hover:text-toon-dark'}`}
          >
            Wheel
          </button>
          <button
            onClick={() => setMode('scan')}
            aria-pressed={mode === 'scan'}
            className={`rounded-full px-4 py-1.5 text-xs font-bold transition-all duration-200 ${mode === 'scan' ? 'bg-toon-dark text-white shadow-md' : 'text-gray-400 hover:text-toon-dark'}`}
          >
            Scan
          </button>
        </div>
      </header>

      {mode === 'wheel' && (
        <div className="mt-4 flex flex-col items-center">
          <div className="mb-6 flex items-center gap-2 text-sm font-bold text-gray-400" aria-label={`Step ${phase === 'CATEGORY' ? 1 : 2} of 2`}>
            <span
              className={`rounded-full px-3 py-1 transition-all duration-300 ${phase === 'CATEGORY' ? 'bg-toon-primary text-white shadow-md scale-105' : 'bg-white text-gray-400'}`}
            >
              1. Cuisine
            </span>
            <ChevronRight size={16} aria-hidden="true" />
            <span
              className={`rounded-full px-3 py-1 transition-all duration-300 ${phase === 'DISH' ? 'bg-toon-primary text-white shadow-md scale-105' : 'bg-white text-gray-400'}`}
            >
              2. Dish
            </span>
          </div>

          <div
            className={`relative mb-8 h-[320px] w-full overflow-y-auto rounded-3xl toon-card p-4 transition-shadow ${
              isSpinning ? 'animate-pulse-ring' : ''
            }`}
          >
            {selectedDish && <ConfettiBurst />}
            {isLoadingCuisines && (
              <div className="flex h-full flex-col justify-center text-gray-500">
                <div className="mb-5 flex flex-col items-center text-center">
                  <RefreshCw className="mb-2 animate-spin text-toon-primary" />
                  <p className="font-semibold">Loading cuisines...</p>
                </div>
                <div className="grid grid-cols-2 gap-3">
                  {Array.from({ length: 4 }).map((_, index) => (
                    <div
                      key={`cuisine-skeleton-${index}`}
                      className="rounded-xl border border-orange-100 bg-white p-3 text-center"
                    >
                      <div className="mx-auto mb-2 h-8 w-8 rounded-full skeleton-shimmer" />
                      <div className="mx-auto h-3 w-20 rounded-full skeleton-shimmer" />
                    </div>
                  ))}
                </div>
              </div>
            )}

            {!isLoadingCuisines && cuisineError && (
              <div className="mb-4 rounded-2xl border border-orange-100 bg-orange-50 px-4 py-3 text-center text-sm font-medium text-orange-700 animate-rise">
                {cuisineError}
              </div>
            )}

            {!isLoadingCuisines && (
              <>
                {!selectedCuisine || (phase === 'CATEGORY' && isSpinning) ? (
                  <div className={`grid grid-cols-2 gap-3 ${isSpinning ? '' : 'stagger-children'}`}>
                    {cuisines.map((cuisine, index) => {
                      const spotlit = isSpinning && spotlightIndex === index;
                      return (
                        <div
                          key={cuisine.id}
                          className={`rounded-xl border p-3 text-center transition-all duration-100 ${
                            spotlit
                              ? 'scale-105 border-toon-primary bg-toon-primary text-white shadow-toon-glow'
                              : 'border-orange-100 bg-orange-50'
                          }`}
                        >
                          <div className={`mb-1 text-2xl ${spotlit ? 'animate-drum-roll' : ''}`}>{cuisine.emoji}</div>
                          <div className={`text-sm font-bold ${spotlit ? 'text-white' : 'text-toon-dark'}`}>{cuisine.name}</div>
                        </div>
                      );
                    })}
                  </div>
                ) : !selectedDish && phase === 'DISH' ? (
                  <div className={`grid grid-cols-1 gap-2 ${isSpinning ? '' : 'stagger-children'}`}>
                    {selectedCuisine.dishes.map((dish, index) => {
                      const spotlit = isSpinning && spotlightIndex === index;
                      return (
                        <div
                          key={`${selectedCuisine.id}-${index}`}
                          className={`rounded-xl border p-3 text-center font-bold transition-all duration-100 ${
                            spotlit
                              ? 'scale-[1.03] border-toon-primary bg-toon-primary text-white shadow-toon-glow'
                              : 'border-orange-100 bg-orange-50 text-toon-dark'
                          }`}
                        >
                          {dish}
                        </div>
                      );
                    })}
                  </div>
                ) : selectedDish ? (
                  <div aria-live="polite" className="relative flex h-full flex-col items-center justify-center animate-pop-in">
                    <span aria-hidden="true" className="toon-sunburst absolute left-1/2 top-8 h-52 w-52 ml-[-6.5rem] rounded-full" />
                    <div className="relative mb-4 text-8xl animate-float drop-shadow-[0_10px_16px_rgba(242,112,79,0.25)]">
                      {selectedCuisine?.emoji}
                    </div>
                    <h2 className="animate-tada relative mb-2 text-center font-display text-4xl font-semibold text-toon-dark">
                      {selectedDish}
                    </h2>
                    <p className="relative flex items-center gap-2 text-sm font-bold uppercase tracking-widest text-toon-primary">
                      <span aria-hidden="true" className="toon-twinkle">✦</span>
                      Bon Appetit
                      <span aria-hidden="true" className="toon-twinkle" style={{ animationDelay: '0.6s' }}>✦</span>
                    </p>
                  </div>
                ) : (
                  <div aria-live="polite" className="flex h-full flex-col items-center justify-center animate-pop-in">
                    <div className="mb-4 text-6xl animate-float">{selectedCuisine?.emoji}</div>
                    <h2 className="mb-4 font-display text-3xl font-semibold text-toon-dark">
                      {selectedCuisine?.name}
                    </h2>
                    <button
                      onClick={handlePhase2Start}
                      className="press-springy btn-candy rounded-2xl px-8 py-3 font-bold text-white"
                    >
                      Find a Dish <ChevronRight className="ml-1 inline" aria-hidden="true" />
                    </button>
                  </div>
                )}
              </>
            )}
          </div>

          <div className="z-20 mt-4 w-full max-w-xs space-y-3">
            {!selectedDish && (
              <button
                onClick={spin}
                disabled={
                  isSpinning ||
                  isLoadingCuisines ||
                  cuisines.length === 0 ||
                  (phase === 'DISH' && selectedCuisine?.dishes.length === 0)
                }
                className="flex w-full items-center justify-center gap-2 rounded-2xl bg-toon-dark py-4 text-xl font-bold text-white shadow-[0_6px_0_rgb(60,50,45)] transition-all active:translate-y-[6px] active:shadow-none disabled:opacity-50 disabled:active:translate-y-0 disabled:active:shadow-[0_6px_0_rgb(60,50,45)]"
              >
                {isSpinning ? 'Rolling...' : phase === 'CATEGORY' ? 'Spin Cuisine' : 'Spin Dish'}
                <RefreshCw className={isSpinning ? 'animate-spin' : ''} aria-hidden="true" />
              </button>
            )}

            {selectedCuisine && phase === 'CATEGORY' && !selectedDish && !isSpinning && (
              <button
                onClick={handlePhase2Start}
                className="press-springy btn-candy w-full rounded-2xl py-3 font-bold text-white animate-rise"
              >
                Move to Dishes
              </button>
            )}

            {selectedDish && (
              <div className="flex gap-2 animate-rise">
                <button
                  onClick={() => {
                    setSelectedDish(null);
                    spin();
                  }}
                  className="press-springy btn-candy flex-1 rounded-2xl py-3 font-bold text-white"
                >
                  Respin Dish
                </button>
                <button
                  onClick={resetAll}
                  className="press-springy flex-1 rounded-2xl border border-orange-200 bg-white py-3 font-bold text-gray-500 hover:text-toon-dark hover:border-toon-secondary transition-colors"
                >
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
                className="w-full py-2 font-bold text-gray-400 hover:text-toon-dark transition-colors"
              >
                Back to Cuisines
              </button>
            )}

            {!isSpinning && (
              <button
                onClick={() => setIsEditing(true)}
                className="flex w-full items-center justify-center gap-2 rounded-xl py-2 text-sm font-bold text-gray-400 hover:bg-white/60 hover:text-toon-dark transition-colors"
              >
                <Edit2 size={14} aria-hidden="true" /> Customize Wheel
              </button>
            )}
          </div>
        </div>
      )}

      {isEditing && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4 backdrop-blur-sm animate-fade">
          <div
            role="dialog"
            aria-modal="true"
            aria-label={editCategory ? `Edit ${editCategory.name}` : 'Edit Cuisines'}
            className="flex h-[80vh] w-full max-w-md flex-col overflow-hidden rounded-3xl bg-white shadow-2xl animate-pop-in"
          >
            <div className="flex items-center justify-between border-b border-orange-100 bg-toon-cream p-4">
              <div>
                <h3 className="font-display text-lg font-semibold text-toon-dark">
                  {editCategory ? `Edit ${editCategory.name}` : 'Edit Cuisines'}
                </h3>
                <p className="text-xs text-gray-400">
                  {editCategory ? 'Manage dishes' : 'Manage categories'}
                </p>
              </div>
              <button
                aria-label={editCategory ? 'Back to cuisine list' : 'Close editor'}
                onClick={() => {
                  if (editCategory) setEditCategory(null);
                  else setIsEditing(false);
                }}
                className="press-springy rounded-full bg-white p-2 text-gray-500 shadow-sm hover:text-red-500 transition-colors"
              >
                {editCategory ? <ChevronLeft size={20} /> : <X size={20} />}
              </button>
            </div>

            <div className="flex-1 space-y-2 overflow-y-auto p-4">
              {editCategory ? (
                editCategory.dishes.length === 0 ? (
                  <p className="py-10 text-center text-gray-400">No dishes yet.</p>
                ) : (
                  editCategory.dishes.map((dish, index) => (
                    <div
                      key={`${editCategory.id}-dish-${index}`}
                      className="flex items-center justify-between rounded-xl border border-orange-100 bg-white p-3 shadow-sm animate-rise"
                      style={{ animationDelay: `${Math.min(index, 8) * 40}ms` }}
                    >
                      <span className="font-medium text-gray-700">{dish}</span>
                      <button
                        aria-label={`Delete ${dish}`}
                        onClick={() => deleteDish(editCategory.id, dish)}
                        className="flex h-11 w-11 items-center justify-center rounded-full text-red-300 hover:text-red-500 hover:bg-red-50 transition-colors"
                      >
                        <X size={18} />
                      </button>
                    </div>
                  ))
                )
              ) : (
                cuisines.map((cuisine, index) => (
                  <div
                    key={cuisine.id}
                    className="flex cursor-pointer items-center justify-between rounded-xl border border-orange-100 bg-white p-3 shadow-sm hover:border-toon-secondary hover:shadow-md transition-all animate-rise"
                    style={{ animationDelay: `${Math.min(index, 8) * 40}ms` }}
                    onClick={() => setEditCategory(cuisine)}
                  >
                    <div className="flex items-center gap-3">
                      <span className="text-2xl">{cuisine.emoji}</span>
                      <span className="font-bold text-gray-700">{cuisine.name}</span>
                      <span className="rounded-full bg-orange-50 px-2 py-1 text-xs font-semibold text-gray-500">
                        {cuisine.dishes.length} dishes
                      </span>
                    </div>
                    <div className="flex gap-1">
                      <button
                        aria-label={`Edit ${cuisine.name} dishes`}
                        onClick={(event) => {
                          event.stopPropagation();
                          setEditCategory(cuisine);
                        }}
                        className="flex h-11 w-11 items-center justify-center rounded-full text-gray-300 hover:text-blue-500 hover:bg-blue-50 transition-colors"
                      >
                        <Settings size={18} />
                      </button>
                      <button
                        aria-label={`Delete ${cuisine.name}`}
                        onClick={(event) => {
                          event.stopPropagation();
                          deleteCuisine(cuisine.id);
                        }}
                        className="flex h-11 w-11 items-center justify-center rounded-full text-gray-300 hover:text-red-500 hover:bg-red-50 transition-colors"
                      >
                        <X size={18} />
                      </button>
                    </div>
                  </div>
                ))
              )}
            </div>

            <form
              className="flex gap-2 border-t border-orange-100 bg-toon-cream p-4"
              onSubmit={(event) => {
                event.preventDefault();
                handleAddItem();
              }}
            >
              <input
                name="value"
                value={editInputValue}
                onChange={(event) => setEditInputValue(event.target.value)}
                className="flex-1 rounded-xl border border-orange-200 px-4 py-3 outline-none transition-colors focus:border-toon-primary"
                placeholder={editCategory ? 'Add a new dish...' : 'Add new cuisine...'}
              />
              <button
                type="submit"
                aria-label={editCategory ? 'Add dish' : 'Add cuisine'}
                className="press-springy rounded-xl bg-toon-primary p-3 text-white shadow-md hover:bg-toon-primary-deep transition-colors"
              >
                <Plus />
              </button>
            </form>
          </div>
        </div>
      )}

      {mode === 'scan' && (
        <div className="mt-10 flex flex-col items-center justify-center px-4 animate-rise">
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            className="hidden"
            aria-label="Upload a menu photo"
            onChange={handleFileUpload}
          />
          {!scanImage ? (
            <button
              type="button"
              onClick={() => fileInputRef.current?.click()}
              className="group flex aspect-[4/5] w-full max-w-sm cursor-pointer flex-col items-center justify-center rounded-3xl border-4 border-dashed border-orange-200 transition-colors hover:bg-white/60 hover:border-toon-secondary"
            >
              <div className="mb-4 flex h-20 w-20 items-center justify-center rounded-full bg-orange-100 transition-transform duration-300 group-hover:scale-110 animate-glow-pulse">
                <Camera size={40} className="text-orange-400" aria-hidden="true" />
              </div>
              <p className="font-display text-lg font-semibold text-toon-dark">Snap a Menu</p>
              <p className="text-xs text-gray-400">Secure menu scanning is coming soon</p>
            </button>
          ) : (
            <div className="w-full max-w-sm rounded-3xl toon-card p-6">
              {isScanning ? (
                <div className="py-10 text-center" aria-live="polite">
                  <Sparkles
                    className="mx-auto mb-4 animate-spin text-toon-accent"
                    size={40}
                    aria-hidden="true"
                  />
                  <p className="font-bold text-toon-dark">Reading menu...</p>
                </div>
              ) : (
                <div className="text-center animate-pop-in" aria-live="polite">
                  <div className="relative mb-6 h-40 w-full overflow-hidden rounded-2xl bg-gray-100">
                    <img src={scanImage} alt="Uploaded menu" className="h-full w-full object-cover" />
                    <div className="absolute inset-0 bg-black/20" />
                  </div>
                  <h2 className="mb-2 font-display text-3xl font-semibold text-toon-primary">
                    {scanResult?.name}
                  </h2>
                  <p className="mb-6 text-sm italic text-gray-500">
                    "{scanResult?.desc}"
                  </p>
                  <button
                    onClick={() => {
                      setScanImage(null);
                      setScanResult(null);
                    }}
                    className="press-springy w-full rounded-xl bg-orange-50 py-3 font-bold text-toon-dark hover:bg-orange-100 transition-colors"
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
