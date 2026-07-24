import React, { useEffect, useMemo, useState } from 'react';
import { ChevronLeft, ChevronRight, Clock, Flame, Pause, Play, RotateCcw, Share2, X } from 'lucide-react';
import { RecipeStep } from '../types';
import { ACTIONS, INGREDIENTS, TOOLS } from '../data/kitchenData';
import { kitchenAssetPack } from '../services/kitchenAssetPack';
import { MotionScene, PackAsset } from './AssetImage';

interface RecipePlayerProps {
  recipeName: string;
  steps: RecipeStep[];
  onClose: () => void;
  onShare?: () => void;
}

const SLIDE_DURATION_MS = 4600;

const CONFETTI_COLORS = ['#FF8E72', '#FFC482', '#6EC6CA', '#F9DC5C', '#FF9EAA'];

const STATION_SCENES = {
  prep: {
    label: 'Prep Station',
    emoji: '🥬',
    bg: 'from-green-50 via-white to-emerald-50',
    chip: 'bg-green-100 text-green-700',
  },
  cook: {
    label: 'Hot Station',
    emoji: '🔥',
    bg: 'from-orange-50 via-white to-red-50',
    chip: 'bg-red-100 text-red-600',
  },
  finish: {
    label: 'Plating',
    emoji: '🍽️',
    bg: 'from-yellow-50 via-white to-amber-50',
    chip: 'bg-amber-100 text-amber-700',
  },
} as const;

const FinaleConfetti: React.FC = () => (
  <div aria-hidden="true" className="pointer-events-none absolute inset-x-0 top-0 h-0 overflow-visible">
    {Array.from({ length: 24 }).map((_, index) => (
      <span
        key={index}
        className="confetti-piece"
        style={{
          left: `${4 + index * 4}%`,
          backgroundColor: CONFETTI_COLORS[index % CONFETTI_COLORS.length],
          borderRadius: index % 3 === 0 ? '9999px' : index % 3 === 1 ? '2px' : '40% 60% 55% 45%',
          animationDelay: `${(index % 6) * 90}ms`,
          animationDuration: `${1.05 + (index % 4) * 0.15}s`,
          ['--confetti-x' as string]: `${(index % 2 === 0 ? 1 : -1) * (12 + (index % 5) * 15)}px`,
          ['--confetti-spin' as string]: `${220 + (index % 6) * 60}deg`,
        }}
      />
    ))}
  </div>
);

export const RecipePlayer: React.FC<RecipePlayerProps> = ({ recipeName, steps, onClose, onShare }) => {
  // slideIndex === steps.length is the "Bon Appétit" finale slide.
  const [slideIndex, setSlideIndex] = useState(0);
  const [playing, setPlaying] = useState(() => {
    if (typeof window === 'undefined' || typeof window.matchMedia !== 'function') return true;
    // Under reduced motion the CSS progress animation completes instantly and
    // would skip every slide, so start paused and let the cook tap through.
    return !window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  });

  const isFinale = slideIndex >= steps.length;
  const step = isFinale ? undefined : steps[slideIndex];
  const action = step ? ACTIONS.find((a) => a.id === step.actionId) : undefined;
  const tool = step ? TOOLS.find((t) => t.id === step.toolId) : undefined;
  const scene = STATION_SCENES[step?.station ?? 'finish'];

  const motionAsset = useMemo(() => {
    if (!step || !action) return undefined;
    const primaryIngredient = step.ingredients[0]?.id;
    return primaryIngredient
      ? kitchenAssetPack.transitionMotion(primaryIngredient, action.id) ?? kitchenAssetPack.actionMotion(action.id)
      : kitchenAssetPack.actionMotion(action.id);
  }, [step, action]);

  const heroEmoji = useMemo(() => {
    const firstIngredientId = steps[0]?.ingredients[0]?.id;
    return INGREDIENTS.find((item) => item.id === firstIngredientId)?.emoji ?? '🍽️';
  }, [steps]);

  useEffect(() => {
    if (isFinale) setPlaying(false);
  }, [isFinale]);

  const goTo = (index: number) => {
    setSlideIndex(Math.max(0, Math.min(index, steps.length)));
  };

  const handleProgressDone = () => {
    if (!isFinale) setSlideIndex((current) => Math.min(current + 1, steps.length));
  };

  const handleReplay = () => {
    setSlideIndex(0);
    setPlaying(true);
  };

  return (
    <div className="toon-atmosphere fixed inset-0 z-[60] flex flex-col animate-fade" role="dialog" aria-modal="true" aria-label={`${recipeName} recipe preview`}>
      {/* Story-style progress rail */}
      <div className="flex items-center gap-3 px-4 pt-4">
        <div className="flex flex-1 gap-1.5" aria-hidden="true">
          {steps.map((s, index) => (
            <span key={s.id} className="h-1.5 flex-1 overflow-hidden rounded-full bg-white/80 shadow-inner">
              <span
                onAnimationEnd={index === slideIndex ? handleProgressDone : undefined}
                className="block h-full rounded-full bg-gradient-to-r from-toon-secondary to-toon-primary"
                style={
                  index < slideIndex || isFinale
                    ? { width: '100%' }
                    : index === slideIndex
                      ? {
                          width: '100%',
                          transformOrigin: 'left',
                          animation: `toon-player-progress ${SLIDE_DURATION_MS}ms linear forwards`,
                          animationPlayState: playing ? 'running' : 'paused',
                        }
                      : { width: '100%', transform: 'scaleX(0)', transformOrigin: 'left' }
                }
              />
            </span>
          ))}
        </div>
        <button
          type="button"
          aria-label="Close recipe preview"
          onClick={onClose}
          className="press-springy flex h-10 w-10 items-center justify-center rounded-full bg-white/90 text-toon-dark shadow-toon-soft hover:bg-white"
        >
          <X size={18} />
        </button>
      </div>

      <p className="px-5 pt-3 text-[11px] font-bold uppercase tracking-[0.2em] text-toon-primary">
        {recipeName}
      </p>

      {/* Slide */}
      <div className="flex-1 overflow-y-auto px-5 py-4">
        {isFinale ? (
          <div key="finale" className="relative flex h-full min-h-[420px] flex-col items-center justify-center rounded-[2rem] toon-card p-6 text-center animate-pop-in">
            <FinaleConfetti />
            <span aria-hidden="true" className="toon-sunburst absolute left-1/2 top-14 h-56 w-56 ml-[-7rem] rounded-full" />
            <div className="toon-sticker relative mb-5 flex h-28 w-28 items-center justify-center rounded-full bg-gradient-to-br from-white to-orange-50 text-6xl animate-float">
              {heroEmoji}
            </div>
            <h2 className="relative font-display text-3xl font-semibold text-toon-dark animate-tada">{recipeName}</h2>
            <p className="relative mt-2 flex items-center justify-center gap-2 text-sm font-bold uppercase tracking-widest text-toon-primary">
              <span aria-hidden="true" className="toon-twinkle">✦</span>
              Bon Appétit
              <span aria-hidden="true" className="toon-twinkle" style={{ animationDelay: '0.6s' }}>✦</span>
            </p>
            <p className="relative mt-3 text-sm font-semibold text-gray-500">
              {steps.length} {steps.length === 1 ? 'step' : 'steps'}, cooked up with love.
            </p>
            <div className="relative mt-6 w-full max-w-xs space-y-3">
              {onShare ? (
                <button
                  type="button"
                  onClick={onShare}
                  className="press-springy btn-candy flex w-full items-center justify-center gap-2 rounded-2xl py-3.5 font-display text-lg font-semibold text-white"
                >
                  <Share2 size={18} /> Share to Community
                </button>
              ) : null}
              <button
                type="button"
                onClick={handleReplay}
                className="press-springy flex w-full items-center justify-center gap-2 rounded-2xl border border-orange-200 bg-white py-3 font-bold text-toon-dark hover:border-toon-secondary transition-colors"
              >
                <RotateCcw size={16} /> Watch Again
              </button>
            </div>
          </div>
        ) : (
          <div
            key={step?.id ?? slideIndex}
            className={`relative flex h-full min-h-[420px] flex-col overflow-hidden rounded-[2rem] border border-orange-100 bg-gradient-to-br ${scene.bg} shadow-toon-lift animate-pop-in`}
          >
            <div className="flex items-center justify-between px-5 pt-5">
              <span className={`flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-bold ${scene.chip}`}>
                <span aria-hidden="true">{scene.emoji}</span> {scene.label}
              </span>
              <span className="rounded-full bg-white/80 px-3 py-1 text-xs font-bold text-gray-500 shadow-sm">
                Step {slideIndex + 1} of {steps.length}
              </span>
            </div>

            <div className="relative flex flex-1 items-center justify-center px-4">
              {step?.station === 'cook' ? (
                <span aria-hidden="true" className="pointer-events-none absolute left-1/2 top-6 -translate-x-1/2">
                  <span className="steam-wisp" style={{ left: '-12px' }} />
                  <span className="steam-wisp" style={{ left: '0px', animationDelay: '0.7s' }} />
                  <span className="steam-wisp" style={{ left: '12px', animationDelay: '1.3s' }} />
                </span>
              ) : null}
              {motionAsset ? (
                <MotionScene
                  src={motionAsset}
                  alt={`${action?.name ?? 'Cooking'} animation`}
                  className="h-56 w-[267px] max-w-full drop-shadow-[0_14px_20px_rgba(242,112,79,0.2)]"
                />
              ) : (
                <span className="text-8xl animate-float" aria-hidden="true">
                  {action?.icon ?? scene.emoji}
                </span>
              )}
            </div>

            <div className="bg-white/85 px-5 pb-5 pt-4 backdrop-blur-sm">
              <h2 className="font-display text-2xl font-semibold capitalize text-toon-dark">
                {action?.verb ?? 'Cook'}
                {tool?.name ? <span className="ml-2 text-base font-normal text-gray-400">with {tool.name}</span> : null}
              </h2>

              {step && step.ingredients.length > 0 ? (
                <div className="mt-3 flex gap-2 overflow-x-auto pb-1 hide-scrollbar">
                  {step.ingredients.map((item) => {
                    const data = INGREDIENTS.find((ingredient) => ingredient.id === item.id);
                    return (
                      <span
                        key={item.id}
                        className="flex shrink-0 items-center gap-1.5 rounded-full border border-orange-100 bg-orange-50 px-3 py-1.5 text-xs font-bold text-toon-dark"
                      >
                        <PackAsset
                          src={kitchenAssetPack.ingredientPresentation(item.id).asset}
                          fallback={data?.emoji ?? '🥣'}
                          imageClassName="h-5 w-5"
                        />
                        {item.amount} {item.unit} {data?.name ?? item.id.replace(/_/g, ' ')}
                      </span>
                    );
                  })}
                </div>
              ) : null}

              <div className="mt-3 flex flex-wrap gap-2 text-xs font-bold">
                {step?.settings?.temperature ? (
                  <span className="flex items-center gap-1 rounded-md bg-red-100 px-2 py-1 text-red-600">
                    <Flame size={12} /> {step.settings.temperature}
                  </span>
                ) : null}
                {step?.settings?.duration ? (
                  <span className="flex items-center gap-1 rounded-md bg-blue-100 px-2 py-1 text-blue-600">
                    <Clock size={12} /> {step.settings.duration}
                  </span>
                ) : null}
                {step?.settings?.cutShape ? (
                  <span className="rounded-md bg-amber-100 px-2 py-1 text-amber-700">{step.settings.cutShape}</span>
                ) : null}
                {step?.settings?.cookMethod ? (
                  <span className="rounded-md bg-orange-100 px-2 py-1 text-orange-700">{step.settings.cookMethod}</span>
                ) : null}
                {step?.settings?.garnish ? (
                  <span className="rounded-md bg-green-100 px-2 py-1 text-green-700">{step.settings.garnish}</span>
                ) : null}
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Transport controls */}
      {isFinale ? null : (
        <div className="flex items-center justify-center gap-4 px-6 pb-6">
          <button
            type="button"
            aria-label="Previous step"
            onClick={() => goTo(slideIndex - 1)}
            disabled={slideIndex === 0}
            className="press-springy flex h-12 w-12 items-center justify-center rounded-full bg-white text-toon-dark shadow-toon-soft disabled:opacity-40"
          >
            <ChevronLeft size={22} />
          </button>
          <button
            type="button"
            aria-label={playing ? 'Pause preview' : 'Play preview'}
            onClick={() => setPlaying((current) => !current)}
            className="press-springy btn-candy flex h-16 w-16 items-center justify-center rounded-full text-white"
          >
            {playing ? <Pause size={26} /> : <Play size={26} className="ml-1" />}
          </button>
          <button
            type="button"
            aria-label="Next step"
            onClick={() => goTo(slideIndex + 1)}
            className="press-springy flex h-12 w-12 items-center justify-center rounded-full bg-white text-toon-dark shadow-toon-soft"
          >
            <ChevronRight size={22} />
          </button>
        </div>
      )}
    </div>
  );
};
