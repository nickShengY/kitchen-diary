
import React, { useState } from 'react';
import { Navigation } from './components/Navigation';
import { RecipeBuilder } from './components/RecipeBuilder';
import { Community } from './components/Community';
import { DeciderWheel } from './components/DeciderWheel';
import { Profile } from './components/Profile';
import { AppView, Recipe } from './types';

function App() {
  const [currentView, setCurrentView] = useState<AppView>(AppView.COMMUNITY);
  const [importRecipe, setImportRecipe] = useState<Recipe | undefined>(undefined);

  const handleCookThis = (recipe: Recipe) => {
      setImportRecipe(recipe);
      setCurrentView(AppView.BUILDER);
  };

  const renderView = () => {
    switch (currentView) {
      case AppView.COMMUNITY:
        return <Community onCookThis={handleCookThis} />;
      case AppView.BUILDER:
        return (
            <RecipeBuilder 
                key={importRecipe?.id || 'new'} 
                initialRecipe={importRecipe} 
                onExit={() => setCurrentView(AppView.COMMUNITY)}
            />
        );
      case AppView.DECIDER:
        return <DeciderWheel />;
      case AppView.PROFILE:
        return <Profile />;
      default:
        return <Community onCookThis={handleCookThis} />;
    }
  };

  return (
    <div className="bg-[#FFF5F0] min-h-screen font-sans text-toon-dark selection:bg-toon-primary selection:text-white overflow-hidden">
      <div className="max-w-md mx-auto min-h-screen bg-[#FFF5F0] relative shadow-2xl sm:border-x sm:border-orange-100 overflow-y-auto hide-scrollbar">
        
        {/* Main Content Area */}
        <main className="animate-in fade-in duration-500 min-h-screen">
            {renderView()}
        </main>

        {/* Navigation */}
        <Navigation currentView={currentView} setView={setCurrentView} />

        {/* Background Decor - Blobs */}
        <div className="fixed top-0 left-0 w-64 h-64 bg-orange-200 rounded-full mix-blend-multiply filter blur-3xl opacity-20 pointer-events-none -z-10 animate-blob"></div>
        <div className="fixed top-0 right-0 w-64 h-64 bg-pink-200 rounded-full mix-blend-multiply filter blur-3xl opacity-20 pointer-events-none -z-10 animate-blob animation-delay-2000"></div>
        <div className="fixed -bottom-8 left-20 w-64 h-64 bg-yellow-200 rounded-full mix-blend-multiply filter blur-3xl opacity-20 pointer-events-none -z-10 animate-blob animation-delay-4000"></div>
      </div>
    </div>
  );
}

export default App;
