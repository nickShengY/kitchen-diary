
import React, { useEffect, useState } from 'react';
import { Navigation } from './components/Navigation';
import { RecipeBuilder } from './components/RecipeBuilder';
import { Community } from './components/Community';
import { PantryKitchen } from './components/PantryKitchen';
import { DeciderWheel } from './components/DeciderWheel';
import { Profile } from './components/Profile';
import { login, subscribeToAuthState } from './services/authService';
import { AppView, Recipe } from './types';
import { BillingReturn } from './components/BillingReturn';
import { LandingPage } from './components/LandingPage';

function App() {
  const [billingReturn, setBillingReturn] = useState(() => {
    const match = window.location.pathname.match(/^\/billing\/(success|cancel|manage)\/?$/);
    return match ? match[1] as 'success' | 'cancel' | 'manage' : null;
  });
  const [currentView, setCurrentView] = useState<AppView>(AppView.COMMUNITY);
  const [importRecipe, setImportRecipe] = useState<Recipe | undefined>(undefined);
  const [userId, setUserId] = useState<string | undefined>(undefined);
  const [showLanding, setShowLanding] = useState(true);

  useEffect(() => subscribeToAuthState((user) => {
      setUserId(user?.id);
      if (user) setShowLanding(false);
  }), []);

  const handleCookThis = (recipe: Recipe) => {
      setImportRecipe(recipe);
      setCurrentView(AppView.BUILDER);
  };

  const handleNavigate = (view: AppView) => {
      setShowLanding(false);
      if (view === AppView.BUILDER) {
          setImportRecipe(undefined);
      }
      setCurrentView(view);
  };

  const renderView = () => {
    if (showLanding && !userId) {
      return <LandingPage onNavigate={handleNavigate} onSignIn={login} />;
    }
    switch (currentView) {
      case AppView.COMMUNITY:
        return <Community onCookThis={handleCookThis} />;
      case AppView.KITCHEN:
        return <PantryKitchen userId={userId} onCookThis={handleCookThis} />;
      case AppView.BUILDER:
        return (
            <RecipeBuilder
                key={importRecipe?.id || 'new'}
                initialRecipe={importRecipe}
                userId={userId}
                onExit={() => setCurrentView(AppView.COMMUNITY)}
                onShared={() => setCurrentView(AppView.COMMUNITY)}
            />
        );
      case AppView.DECIDER:
        return <DeciderWheel />;
      case AppView.PROFILE:
        return <Profile onCookThis={handleCookThis} />;
      default:
        return <Community onCookThis={handleCookThis} />;
    }
  };

  if (billingReturn) return <BillingReturn mode={billingReturn} onContinue={() => {
    window.history.replaceState(null, '', '/');
    setCurrentView(AppView.PROFILE);
    setShowLanding(false);
    setBillingReturn(null);
  }} />;

  return (
    <div className={`toon-atmosphere min-h-screen font-sans text-toon-dark selection:bg-toon-primary selection:text-white overflow-hidden ${showLanding && !userId ? 'landing-host' : ''}`}>
      <div className={showLanding && !userId ? 'landing-host-inner' : 'toon-atmosphere max-w-md mx-auto min-h-screen relative shadow-2xl sm:border-x sm:border-orange-100 overflow-y-auto hide-scrollbar'}>

        {/* Main Content Area. Screens animate their own content in; main itself
            must stay unanimated so it doesn't become a stacking context that
            would let the nav paint above full-screen overlays rendered inside. */}
        <main key={currentView} className="min-h-screen">
            {renderView()}
        </main>

        {/* Navigation */}
        {!(showLanding && !userId) && <Navigation currentView={currentView} setView={handleNavigate} />}

      </div>
    </div>
  );
}

export default App;
