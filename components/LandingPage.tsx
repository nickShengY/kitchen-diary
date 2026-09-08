import React, { useState } from 'react';
import { PANTRY_RECIPES } from '../data/pantryRecipes';
import { AppView } from '../types';

interface LandingPageProps {
  onNavigate: (view: AppView) => void;
  onSignIn: () => Promise<void>;
}

export function LandingPage({ onNavigate, onSignIn }: LandingPageProps) {
  const [signingIn, setSigningIn] = useState(false);
  const [signInError, setSignInError] = useState(false);
  const featuredRecipes = PANTRY_RECIPES.slice(0, 3);

  const handleSignIn = async () => {
    setSigningIn(true);
    setSignInError(false);
    try {
      await onSignIn();
    } catch {
      setSignInError(true);
    } finally {
      setSigningIn(false);
    }
  };

  return (
    <div className="landing-page">
      <div className="landing-shell">
        <header className="landing-nav">
          <button className="landing-wordmark" type="button" onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}>
            Kitchen Diary
          </button>
          <nav className="landing-nav-links" aria-label="Kitchen Diary">
            <button type="button" onClick={() => onNavigate(AppView.COMMUNITY)}>Recipes</button>
            <button type="button" onClick={() => onNavigate(AppView.KITCHEN)}>Your pantry</button>
            <button type="button" onClick={() => onNavigate(AppView.PROFILE)}>Journal</button>
          </nav>
          <button className="landing-sign-in" type="button" onClick={handleSignIn} disabled={signingIn}>
            {signingIn ? 'Opening…' : 'Sign in'}
          </button>
        </header>

        {signInError && <p className="landing-sign-in-error" role="status">Sign-in could not be opened. Please try again.</p>}

        <main>
          <section className="landing-hero" aria-labelledby="landing-title">
            <div className="landing-hero-copy">
              <p className="landing-eyebrow">A kinder way to cook</p>
              <h1 id="landing-title">A little inspiration.<br />Something delicious.</h1>
              <p className="landing-intro">
                Turn what you have into something special. Kitchen Diary helps you cook with confidence,
                keep track of your favorites, and make everyday meals more meaningful.
              </p>
              <button className="landing-primary-cta" type="button" onClick={() => onNavigate(AppView.KITCHEN)}>
                Start cooking <span aria-hidden="true">→</span>
              </button>
            </div>
            <div className="landing-hero-image" role="img" aria-label="A warm bowl of pasta ready to share" />
          </section>

          <section className="landing-feature-strip" aria-label="Kitchen Diary features">
            <article>
              <span className="landing-feature-number">01</span>
              <h2>Your pantry</h2>
              <p>Find dishes that fit what is already in your kitchen.</p>
            </article>
            <article>
              <span className="landing-feature-number">02</span>
              <h2>Guided cooking</h2>
              <p>Build a recipe around real steps, tools, and timing.</p>
            </article>
            <article>
              <span className="landing-feature-number">03</span>
              <h2>Saved recipes</h2>
              <p>Keep favorites, cooking history, and your own ideas close.</p>
            </article>
          </section>

          <section className="landing-recipes" aria-labelledby="landing-recipes-title">
            <div className="landing-section-heading">
              <div>
                <p className="landing-eyebrow">From the pantry</p>
                <h2 id="landing-recipes-title">Discover what’s cooking</h2>
              </div>
              <button className="landing-text-cta" type="button" onClick={() => onNavigate(AppView.COMMUNITY)}>
                Browse recipes <span aria-hidden="true">↗</span>
              </button>
            </div>
            <div className="landing-recipe-grid">
              {featuredRecipes.map((recipe) => (
                <article className="landing-recipe-card" key={recipe.id}>
                  <div className="landing-recipe-art" aria-hidden="true">{recipe.emoji}</div>
                  <div className="landing-recipe-card-copy">
                    <p>{recipe.cuisine} · {recipe.minutes} min</p>
                    <h3>{recipe.title}</h3>
                    <span>{recipe.blurb}</span>
                  </div>
                </article>
              ))}
            </div>
          </section>
        </main>
      </div>
    </div>
  );
}
