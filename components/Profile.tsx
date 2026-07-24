import React, { useEffect, useState } from 'react';
import { UserProfile } from '../types';
import { login, logout, getCurrentUser, subscribeToAuthState } from '../services/authService';
import { isFirebaseConfigured } from '../services/firebase';
import { isStripeCheckoutConfigured, startStripeCheckout } from '../services/billingService';
import { LogOut, Heart, BookOpen, Settings, X } from 'lucide-react';

type ProfilePanel = 'favorites' | 'cookbook' | 'settings' | null;

const formatCount = (value: number | undefined): string => {
  const safe = value ?? 0;
  if (safe >= 1000) return `${(safe / 1000).toFixed(1)}k`;
  return `${safe}`;
};

const FLOATING_TREATS = ['🥞', '🍜', '🧁', '🥑', '🍕', '🍓'];

/** Google accounts give a photo URL; guests get an emoji. Render each properly. */
const Avatar: React.FC<{ avatar: string; name: string }> = ({ avatar, name }) =>
  /^https:\/\//i.test(avatar) ? (
    <img
      src={avatar}
      alt={`${name}'s avatar`}
      referrerPolicy="no-referrer"
      className="h-full w-full rounded-full object-cover"
    />
  ) : (
    <span aria-hidden="true">{avatar}</span>
  );

export const Profile: React.FC = () => {
  const [user, setUser] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(false);
  const [authError, setAuthError] = useState<string | null>(null);
  const [billingError, setBillingError] = useState<string | null>(null);
  const [checkoutLoading, setCheckoutLoading] = useState(false);
  const [activePanel, setActivePanel] = useState<ProfilePanel>(null);
  const stats = user
    ? [
        {
          label: 'Recipes',
          value: formatCount(user.recipesCount ?? user.myRecipes.length),
        },
        ...(typeof user.followersCount === 'number'
          ? [{ label: 'Followers', value: formatCount(user.followersCount) }]
          : []),
        ...(typeof user.likesReceived === 'number'
          ? [{ label: 'Likes', value: formatCount(user.likesReceived) }]
          : []),
      ]
    : [];

  useEffect(() => {
    setUser(getCurrentUser());
    return subscribeToAuthState(setUser);
  }, []);

  const handleLogin = async () => {
    setLoading(true);
    setAuthError(null);
    try {
      const liveUser = await login();
      setUser(liveUser);
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : 'Google sign-in could not be completed.');
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = async () => {
    try {
      await logout();
      setUser(null);
      setActivePanel(null);
    } catch {
      // Ignore logout failures to keep UI stable.
    }
  };

  const handleCheckout = async () => {
    setCheckoutLoading(true);
    setBillingError(null);
    try {
      await startStripeCheckout('monthly');
    } catch (error) {
      setBillingError(error instanceof Error ? error.message : 'Unable to start secure checkout.');
    } finally {
      setCheckoutLoading(false);
    }
  };

  const renderPanel = () => {
    if (!user || !activePanel) return null;

    const panelTitle =
      activePanel === 'favorites'
        ? 'Favorites'
        : activePanel === 'cookbook'
          ? 'My Cookbook'
          : 'Profile Settings';

    return (
      <div
        className="fixed inset-0 z-[70] flex items-end bg-black/30 px-4 pb-4 backdrop-blur-sm animate-fade"
        onClick={(event) => {
          if (event.target === event.currentTarget) setActivePanel(null);
        }}
      >
        <section
          role="dialog"
          aria-modal="true"
          aria-labelledby="profile-panel-title"
          className="mx-auto w-full max-w-md rounded-[2rem] bg-white p-5 shadow-2xl animate-sheet-up"
        >
          <div aria-hidden="true" className="mx-auto mb-3 h-1.5 w-12 rounded-full bg-orange-100" />
          <div className="mb-4 flex items-center justify-between gap-4">
            <h2 id="profile-panel-title" className="font-display text-xl font-semibold text-toon-dark">
              {panelTitle}
            </h2>
            <button
              type="button"
              aria-label="Close profile panel"
              onClick={() => setActivePanel(null)}
              className="press-springy rounded-full bg-gray-50 p-2 text-gray-400 transition-colors hover:bg-gray-100 hover:text-toon-dark"
            >
              <X size={20} />
            </button>
          </div>

          {activePanel === 'favorites' && (
            <div className="space-y-3 stagger-children">
              {user.favorites.length > 0 ? (
                user.favorites.map((favoriteId) => (
                  <div key={favoriteId} className="rounded-2xl border border-pink-100 bg-pink-50 p-4">
                    <p className="font-bold text-toon-dark">{favoriteId}</p>
                    <p className="mt-1 text-sm text-gray-500">Saved favorite recipe</p>
                  </div>
                ))
              ) : (
                <div className="rounded-2xl border border-dashed border-pink-100 bg-pink-50/60 p-5 text-center">
                  <Heart className="mx-auto mb-3 text-pink-400 animate-float" aria-hidden="true" />
                  <p className="font-bold text-toon-dark">No favorites yet</p>
                  <p className="mt-1 text-sm text-gray-500">
                    Recipes saved to this profile will appear here.
                  </p>
                </div>
              )}
            </div>
          )}

          {activePanel === 'cookbook' && (
            <div className="space-y-3 stagger-children">
              {user.myRecipes.length > 0 ? (
                user.myRecipes.map((recipe) => (
                  <article key={recipe.id} className="rounded-2xl border border-blue-100 bg-blue-50 p-4">
                    <p className="font-bold text-toon-dark">{recipe.title}</p>
                    <p className="mt-1 text-sm text-gray-500">
                      {recipe.steps.length} {recipe.steps.length === 1 ? 'step' : 'steps'}
                    </p>
                  </article>
                ))
              ) : (
                <div className="rounded-2xl border border-dashed border-blue-100 bg-blue-50/60 p-5 text-center">
                  <BookOpen className="mx-auto mb-3 text-blue-400 animate-float" aria-hidden="true" />
                  <p className="font-bold text-toon-dark">No cookbook recipes yet</p>
                  <p className="mt-1 text-sm text-gray-500">
                    Recipes attached to this profile will appear here.
                  </p>
                </div>
              )}
            </div>
          )}

          {activePanel === 'settings' && (
            <div className="space-y-3 stagger-children">
              <div className="rounded-2xl bg-orange-50 p-4">
                <p className="text-xs font-bold uppercase tracking-wider text-toon-primary">Display name</p>
                <p className="mt-1 font-bold text-toon-dark">{user.name}</p>
              </div>
              <div className="rounded-2xl bg-gray-50 p-4">
                <p className="text-xs font-bold uppercase tracking-wider text-gray-400">Account</p>
                <p className="mt-1 text-sm font-semibold text-gray-600">
                  Signed in with your Google account.
                </p>
              </div>
              <div className="rounded-2xl border border-orange-100 bg-orange-50/60 p-4">
                <p className="text-xs font-bold uppercase tracking-wider text-toon-primary">Kitchen Diary Plus</p>
                <p className="mt-1 text-sm text-gray-600">Manage a web subscription through secure Stripe Checkout.</p>
                <button
                  type="button"
                  onClick={handleCheckout}
                  disabled={checkoutLoading || !isStripeCheckoutConfigured()}
                  className="press-springy mt-3 w-full rounded-xl bg-toon-primary py-2.5 text-sm font-bold text-white transition-colors hover:bg-toon-primary-deep disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {checkoutLoading ? 'Opening checkout...' : 'Get Kitchen Diary Plus'}
                </button>
                {!isStripeCheckoutConfigured() && (
                  <p className="mt-2 text-xs text-gray-500">Subscriptions are coming soon.</p>
                )}
                {billingError && <p role="alert" className="mt-2 text-xs font-medium text-red-500">{billingError}</p>}
              </div>
              <button
                type="button"
                onClick={handleLogout}
                className="press-springy mt-2 flex w-full items-center justify-center gap-2 rounded-2xl bg-red-50 py-3 font-bold text-red-400 transition-colors hover:bg-red-100"
              >
                <LogOut size={18} aria-hidden="true" /> Sign Out
              </button>
            </div>
          )}
        </section>
      </div>
    );
  };

  if (!user) {
    return (
      <div className="relative min-h-screen flex flex-col items-center justify-center p-6 overflow-hidden">
        {/* Floating pantry treats set a playful, welcoming scene */}
        <div aria-hidden="true" className="pointer-events-none absolute inset-0">
          {FLOATING_TREATS.map((treat, index) => (
            <span
              key={treat}
              className="animate-float absolute text-3xl opacity-40"
              style={{
                left: `${8 + index * 15}%`,
                top: `${12 + (index % 3) * 26}%`,
                animationDelay: `${index * 0.6}s`,
                animationDuration: `${3.6 + (index % 3)}s`,
              }}
            >
              {treat}
            </span>
          ))}
        </div>

        <div className="relative mb-6">
          <span aria-hidden="true" className="toon-sunburst absolute -inset-14 rounded-full" />
          <div className="animate-pop-in toon-sticker relative w-24 h-24 bg-gradient-to-br from-white to-orange-50 rounded-full flex items-center justify-center [&>span:last-child]:hidden">
            <span className="text-5xl" aria-hidden="true">{'\u{1F9D1}‍\u{1F373}'}</span>
            <span className="text-5xl">🍳</span>
          </div>
        </div>
        <h1 className="animate-rise font-display text-4xl font-semibold mb-2" style={{ animationDelay: '100ms' }}>
          <span className="text-candy">CookToon</span>
        </h1>
        <p className="animate-rise text-gray-500 mb-8 text-center max-w-xs" style={{ animationDelay: '180ms' }}>
          Sign in securely with your Google account to save your Kitchen Diary.
        </p>

        <button
          onClick={handleLogin}
          disabled={loading}
          className="press-springy btn-candy animate-rise w-full max-w-xs text-white font-bold py-4 rounded-2xl disabled:opacity-70"
          style={{ animationDelay: '260ms' }}
        >
          {loading ? 'Opening Google...' : 'Continue with Google'}
        </button>
        <p className="animate-rise mt-4 text-xs text-gray-400" style={{ animationDelay: '340ms' }}>
          Google sign-in is the only supported login method.
        </p>
        {!isFirebaseConfigured() && (
          <p role="alert" className="mt-3 max-w-xs text-center text-xs font-medium text-red-500">
            Google sign-in is not configured for this app yet.
          </p>
        )}
        {authError && <p role="alert" className="mt-3 max-w-xs text-center text-xs font-medium text-red-500">{authError}</p>}
      </div>
    );
  }

  return (
      <div className="pb-24 px-4 min-h-screen">
      <header className="py-6 flex justify-end">
        <button
          type="button"
          aria-label="Profile settings"
          onClick={() => setActivePanel('settings')}
          className="press-springy flex h-11 w-11 items-center justify-center rounded-full text-gray-400 transition-colors hover:bg-white hover:text-toon-dark hover:shadow-toon-soft"
        >
          <Settings size={24} />
        </button>
      </header>

      <div className="toon-card rounded-[2rem] p-6 mb-6 relative mt-10 animate-pop-in">
        <div className="toon-sticker absolute -top-12 left-1/2 -translate-x-1/2 w-24 h-24 overflow-hidden bg-gradient-to-br from-orange-100 to-toon-secondary/50 rounded-full flex items-center justify-center text-4xl animate-float">
          <Avatar avatar={user.avatar} name={user.name} />
        </div>

        <div className="mt-12 text-center">
          <h2 className="font-display text-2xl font-semibold text-toon-dark">{user.name}</h2>
          <p className="text-gray-400 text-sm mt-1">{user.bio}</p>

          <div className="flex justify-center gap-8 mt-6 border-t border-orange-50 pt-6 stagger-children">
            {stats.map((stat) => (
              <div key={stat.label} className="text-center">
                <div className="font-display font-semibold text-xl text-toon-dark">{stat.value}</div>
                <div className="text-xs text-gray-400 uppercase font-bold tracking-wider">{stat.label}</div>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4 mb-6 stagger-children">
        <button
          type="button"
          onClick={() => setActivePanel('favorites')}
          className="press-springy toon-card group p-4 rounded-2xl hover:shadow-toon-lift hover:-translate-y-1 transition-all flex flex-col items-center gap-2"
        >
          <span className="flex h-11 w-11 items-center justify-center rounded-full bg-gradient-to-br from-pink-50 to-pink-100 shadow-[inset_0_1px_0_rgba(255,255,255,0.8)] transition-transform duration-300 group-hover:scale-110 group-hover:-rotate-6">
            <Heart className="text-pink-400" aria-hidden="true" />
          </span>
          <span className="font-bold text-sm text-gray-600">Favorites</span>
        </button>
        <button
          type="button"
          onClick={() => setActivePanel('cookbook')}
          className="press-springy toon-card group p-4 rounded-2xl hover:shadow-toon-lift hover:-translate-y-1 transition-all flex flex-col items-center gap-2"
        >
          <span className="flex h-11 w-11 items-center justify-center rounded-full bg-gradient-to-br from-blue-50 to-blue-100 shadow-[inset_0_1px_0_rgba(255,255,255,0.8)] transition-transform duration-300 group-hover:scale-110 group-hover:rotate-6">
            <BookOpen className="text-blue-400" aria-hidden="true" />
          </span>
          <span className="font-bold text-sm text-gray-600">My Cookbook</span>
        </button>
      </div>

      <button
        onClick={handleLogout}
        className="press-springy w-full bg-white text-red-400 font-bold py-4 rounded-2xl flex items-center justify-center gap-2 border border-red-50 hover:bg-red-50 transition-colors"
      >
        <LogOut size={20} aria-hidden="true" /> Sign Out
      </button>
      {renderPanel()}
    </div>
  );
};
