import React from 'react';
import { Compass, PlusCircle, Refrigerator, Sparkles, UserRound } from 'lucide-react';
import { AppView } from '../types';

interface NavigationProps {
  currentView: AppView;
  setView: (view: AppView) => void;
}

export const Navigation: React.FC<NavigationProps> = ({ currentView, setView }) => {
  const items = [
    { view: AppView.COMMUNITY, icon: Compass, label: 'Explore' },
    { view: AppView.KITCHEN, icon: Refrigerator, label: 'Kitchen' },
    { view: AppView.BUILDER, icon: PlusCircle, label: 'Build' },
    { view: AppView.DECIDER, icon: Sparkles, label: 'Decide' },
    { view: AppView.PROFILE, icon: UserRound, label: 'Profile' },
  ];

  return (
    <nav
      aria-label="Primary"
      className="fixed bottom-4 left-1/2 z-50 flex w-[92%] max-w-sm -translate-x-1/2 items-center gap-1 rounded-[1.75rem] border border-white/70 bg-white/90 p-1.5 shadow-[inset_0_1.5px_0_rgba(255,255,255,0.9),0_14px_35px_rgba(74,64,58,0.18),0_2px_10px_rgba(242,112,79,0.12)] backdrop-blur-xl"
    >
      {items.map(({ view, icon: Icon, label }) => {
        const active = currentView === view;
        return (
          <button
            key={view}
            aria-label={label}
            aria-current={active ? 'page' : undefined}
            onClick={() => setView(view)}
            className={`group relative flex h-16 flex-1 flex-col items-center justify-center gap-1 rounded-3xl text-[11px] font-bold transition-all duration-300 ${
              active
                ? 'bg-gradient-to-br from-toon-primary to-toon-primary-deep text-white shadow-[inset_0_2px_0_rgba(255,255,255,0.35),0_10px_22px_-6px_rgba(242,112,79,0.55)]'
                : 'text-gray-400 hover:bg-orange-50 hover:text-toon-dark active:scale-95'
            }`}
          >
            <span
              key={active ? 'active' : 'idle'}
              className={`flex items-center justify-center transition-transform duration-300 ${
                active ? '-translate-y-0.5 scale-110 animate-jelly' : 'group-hover:-translate-y-0.5 group-hover:scale-105'
              }`}
            >
              <Icon size={22} strokeWidth={active ? 2.6 : 2.2} />
            </span>
            <span className="leading-none">{label}</span>
            <span
              aria-hidden="true"
              className={`absolute bottom-1.5 h-1 rounded-full bg-white/80 shadow-[0_0_8px_rgba(255,255,255,0.9)] transition-all duration-300 ${
                active ? 'w-6 opacity-100' : 'w-0 opacity-0'
              }`}
            />
            {/* soft twinkle over the active pill */}
            {active && (
              <span aria-hidden="true" className="toon-twinkle absolute right-2.5 top-2 text-[10px] text-white/90">
                ✦
              </span>
            )}
          </button>
        );
      })}
    </nav>
  );
};
