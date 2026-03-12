import React from 'react';
import { Home, PlusCircle, HelpCircle, User } from 'lucide-react';
import { AppView } from '../types';

interface NavigationProps {
  currentView: AppView;
  setView: (view: AppView) => void;
}

export const Navigation: React.FC<NavigationProps> = ({ currentView, setView }) => {
  const NavItem = ({ view, icon: Icon, label }: { view: AppView, icon: any, label: string }) => (
     <button 
         aria-label={label}
         onClick={() => setView(view)}
         className={`flex-1 flex flex-col items-center justify-center py-2 rounded-full transition-all duration-300 ${currentView === view ? 'text-toon-primary scale-110' : 'text-gray-300 hover:text-gray-400'}`}
       >
         <Icon size={24} strokeWidth={currentView === view ? 2.5 : 2} />
         <span aria-hidden="true" className={`text-[10px] font-bold mt-1 transition-opacity ${currentView === view ? 'opacity-100' : 'opacity-0'}`}>{label}</span>
     </button>
  );

  return (
    <div className={`fixed bottom-6 left-1/2 transform -translate-x-1/2 w-[90%] max-w-sm bg-white/90 backdrop-blur-md rounded-3xl shadow-[0_8px_30px_rgb(0,0,0,0.08)] p-2 z-50 flex justify-between items-center border border-white/50 ${currentView === AppView.BUILDER ? 'pointer-events-none' : ''}`}>
       <NavItem view={AppView.COMMUNITY} icon={Home} label="Home" />
       
       <button 
           aria-label="Create recipe"
           onClick={() => setView(AppView.BUILDER)}
           className={`w-14 h-14 mx-2 rounded-full flex items-center justify-center shadow-lg transition-transform hover:scale-105 active:scale-95 bg-toon-dark text-white`}
         >
           <PlusCircle size={28} />
       </button>

       <NavItem view={AppView.DECIDER} icon={HelpCircle} label="Decider" />
       <NavItem view={AppView.PROFILE} icon={User} label="Me" />
    </div>
  );
};
