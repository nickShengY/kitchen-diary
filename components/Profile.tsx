import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Recipe, SocialPost, UserProfile } from '../types';
import { login, logout, getCurrentUser, subscribeToAuthState } from '../services/authService';
import { isFirebaseConfigured } from '../services/firebase';
import { isStripeCheckoutConfigured, isStripePortalConfigured, openStripePortal, startStripeCheckout } from '../services/billingService';
import { getSharedPosts, removeSharedPost } from '../services/communityStore';
import { PANTRY_RECIPE_BY_ID, PantryRecipe, pantryRecipeToRecipe } from '../data/pantryRecipes';
import { loadPantry, toggleId, updatePantry } from '../services/pantryStore';
import { kitchenAssetPack } from '../services/kitchenAssetPack';
import { PackAsset } from './AssetImage';
import { BookOpen, Clock, Heart, History, LogOut, PlayCircle, Settings, Trash2, X } from 'lucide-react';

interface ProfileProps {
  /** Opens a saved dish in the builder. Optional so the screen renders standalone. */
  onCookThis?: (recipe: Recipe) => void;
}

type ProfilePanel = 'favorites' | 'history' | 'cookbook' | 'settings' | null;

const formatCount = (value: number | undefined): string => {
  const safe = value ?? 0;
  if (safe >= 1000) return `${(safe / 1000).toFixed(1)}k`;
  return `${safe}`;
};

const FLOATING_TREATS = ['🥞', '🍜', '🧁', '🥑', '🍕', '🍓'];

const PANEL_TITLES: Record<Exclude<ProfilePanel, null>, string> = {
  favorites: 'Saved Recipes',
  history: 'Recently Cooked',
  cookbook: 'My Cookbook',
  settings: 'Profile Settings',
};

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

const heroAssetFor = (recipe: PantryRecipe) =>
  kitchenAssetPack.dishHero(recipe.id) ?? kitchenAssetPack.ingredient(recipe.core[0] ?? '');

/** One saved or previously cooked dish, with the same art the Kitchen tab uses. */
const DishRow: React.FC<{
  recipe: PantryRecipe;
  actionLabel: string;
  onCook?: () => void;
  onRemove?: () => void;
  removeLabel?: string;
}> = ({ recipe, actionLabel, onCook, onRemove, removeLabel }) => (
  <article className="flex items-center gap-3 rounded-2xl border border-orange-100 bg-white p-3 shadow-sm">
    <span className="flex h-12 w-12 shrink-0 items-center justify-center overflow-hidden rounded-xl bg-gradient-to-br from-orange-50 to-toon-cream">
      <PackAsset
        src={heroAssetFor(recipe)}
        fallback={<span aria-hidden="true" className="text-2xl">{recipe.emoji}</span>}
        className="flex h-full w-full items-center justify-center text-2xl"
        imageClassName="h-10 w-10 object-contain"
      />
    </span>
    <div className="min-w-0 flex-1">
      <p className="truncate font-bold text-toon-dark">{recipe.title}</p>
      <p className="mt-0.5 flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-wider text-gray-400">
        <Clock size={10} aria-hidden="true" />
        {recipe.minutes}m · {recipe.cuisine}
      </p>
    </div>
    {onRemove && (
      <button
        type="button"
        aria-label={`${removeLabel ?? 'Remove'} ${recipe.title}`}
        onClick={onRemove}
        className="press-springy flex h-11 w-11 items-center justify-center rounded-full text-gray-300 transition-colors hover:bg-red-50 hover:text-red-400"
      >
        <Trash2 size={16} />
      </button>
    )}
    {onCook && (
      <button
        type="button"
        onClick={onCook}
        className="press-springy btn-candy flex min-h-11 items-center gap-1.5 rounded-full px-4 text-xs font-bold text-white"
      >
        <PlayCircle size={14} aria-hidden="true" /> {actionLabel}
      </button>
    )}
  </article>
);

const EmptyPanel: React.FC<{ icon: React.ReactNode; title: string; body: string; tone: string }> = ({
  icon,
  title,
  body,
  tone,
}) => (
  <div className={`rounded-2xl border border-dashed p-5 text-center ${tone}`}>
    <span className="mx-auto mb-3 flex h-11 w-11 items-center justify-center">{icon}</span>
    <p className="font-bold text-toon-dark">{title}</p>
    <p className="mt-1 text-sm text-gray-500">{body}</p>
  </div>
);

export const Profile: React.FC<ProfileProps> = ({ onCookThis }) => {
  const [user, setUser] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(false);
  const [authError, setAuthError] = useState<string | null>(null);
  const [billingError, setBillingError] = useState<string | null>(null);
  const [checkoutLoading, setCheckoutLoading] = useState(false);
  const [activePanel, setActivePanel] = useState<ProfilePanel>(null);

  // The kitchen lives on this device, so it loads whether or not anyone is
  // signed in — a login wall would hide the cook's own saved dishes.
  const [favoriteIds, setFavoriteIds] = useState<string[]>([]);
  const [historyIds, setHistoryIds] = useState<string[]>([]);
  const [sharedPosts, setSharedPosts] = useState<SocialPost[]>([]);

  useEffect(() => {
    const pantry = loadPantry();
    setFavoriteIds(pantry.favorites);
    setHistoryIds(pantry.history);
    setSharedPosts(getSharedPosts());
  }, []);

  useEffect(() => {
    setUser(getCurrentUser());
    return subscribeToAuthState(setUser);
  }, []);

  const resolve = (ids: string[]): PantryRecipe[] =>
    ids.map((id) => PANTRY_RECIPE_BY_ID.get(id)).filter((item): item is PantryRecipe => Boolean(item));

  const favorites = useMemo(() => resolve(favoriteIds), [favoriteIds]);
  const history = useMemo(() => resolve(historyIds), [historyIds]);

  const unsaveRecipe = useCallback((id: string) => {
    const next = updatePantry((state) => ({ ...state, favorites: toggleId(state.favorites, id) }));
    setFavoriteIds(next.favorites);
  }, []);

  const forgetCooked = useCallback((id: string) => {
    const next = updatePantry((state) => ({
      ...state,
      history: state.history.filter((entry) => entry !== id),
    }));
    setHistoryIds(next.history);
  }, []);

  const clearHistory = useCallback(() => {
    const next = updatePantry((state) => ({ ...state, history: [] }));
    setHistoryIds(next.history);
  }, []);

  const deleteSharedPost = useCallback((id: string) => {
    removeSharedPost(id);
    setSharedPosts(getSharedPosts());
  }, []);

  const cookPantryRecipe = useCallback(
    (recipe: PantryRecipe) => {
      const next = updatePantry((state) => ({
        ...state,
        history: [recipe.id, ...state.history.filter((entry) => entry !== recipe.id)].slice(0, 20),
      }));
      setHistoryIds(next.history);
      setActivePanel(null);
      onCookThis?.(pantryRecipeToRecipe(recipe));
    },
    [onCookThis],
  );

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
      if (user?.isVip || user?.billingProvider === 'stripe') await openStripePortal();
      else await startStripeCheckout('monthly');
    } catch (error) {
      setBillingError(error instanceof Error ? error.message : 'Unable to start secure checkout.');
    } finally {
      setCheckoutLoading(false);
    }
  };

  const kitchenStats = [
    { label: 'Cooked', value: formatCount(history.length) },
    { label: 'Saved', value: formatCount(favorites.length) },
    { label: 'Shared', value: formatCount(sharedPosts.length) },
  ];

  const accountStats = user
    ? [
        ...(typeof user.followersCount === 'number'
          ? [{ label: 'Followers', value: formatCount(user.followersCount) }]
          : []),
        ...(typeof user.likesReceived === 'number'
          ? [{ label: 'Likes', value: formatCount(user.likesReceived) }]
          : []),
      ]
    : [];

  const cookbookRecipes = user?.myRecipes ?? [];

  const renderPanel = () => {
    if (!activePanel) return null;

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
          className="mx-auto max-h-[80vh] w-full max-w-md overflow-y-auto rounded-[2rem] bg-white p-5 shadow-2xl animate-sheet-up hide-scrollbar"
        >
          <div aria-hidden="true" className="mx-auto mb-3 h-1.5 w-12 rounded-full bg-orange-100" />
          <div className="mb-4 flex items-center justify-between gap-4">
            <h2 id="profile-panel-title" className="font-display text-xl font-semibold text-toon-dark">
              {PANEL_TITLES[activePanel]}
            </h2>
            <div className="flex items-center gap-1">
              {activePanel === 'history' && history.length > 0 && (
                <button
                  type="button"
                  onClick={clearHistory}
                  className="press-springy min-h-11 rounded-full px-3 text-xs font-bold text-gray-400 transition-colors hover:text-red-400"
                >
                  Clear all
                </button>
              )}
              <button
                type="button"
                aria-label="Close profile panel"
                onClick={() => setActivePanel(null)}
                className="press-springy rounded-full bg-gray-50 p-2 text-gray-400 transition-colors hover:bg-gray-100 hover:text-toon-dark"
              >
                <X size={20} />
              </button>
            </div>
          </div>

          {activePanel === 'favorites' && (
            <div className="space-y-3 stagger-children">
              {favorites.length > 0 ? (
                favorites.map((recipe) => (
                  <DishRow
                    key={recipe.id}
                    recipe={recipe}
                    actionLabel="Cook"
                    onCook={() => cookPantryRecipe(recipe)}
                    onRemove={() => unsaveRecipe(recipe.id)}
                    removeLabel="Unsave"
                  />
                ))
              ) : (
                <EmptyPanel
                  icon={<Heart className="text-pink-400 animate-float" aria-hidden="true" />}
                  title="No saved recipes yet"
                  body="Tap the heart on a dish in the Kitchen tab and it lands here."
                  tone="border-pink-100 bg-pink-50/60"
                />
              )}
            </div>
          )}

          {activePanel === 'history' && (
            <div className="space-y-3 stagger-children">
              {history.length > 0 ? (
                history.map((recipe) => (
                  <DishRow
                    key={recipe.id}
                    recipe={recipe}
                    actionLabel="Again"
                    onCook={() => cookPantryRecipe(recipe)}
                    onRemove={() => forgetCooked(recipe.id)}
                    removeLabel="Forget"
                  />
                ))
              ) : (
                <EmptyPanel
                  icon={<History className="text-amber-500 animate-float" aria-hidden="true" />}
                  title="Nothing cooked yet"
                  body="Dishes you open from the Kitchen tab show up here, newest first."
                  tone="border-amber-100 bg-amber-50/60"
                />
              )}
            </div>
          )}

          {activePanel === 'cookbook' && (
            <div className="space-y-3 stagger-children">
              {sharedPosts.map((post) => (
                <article
                  key={post.id}
                  className="flex items-center gap-3 rounded-2xl border border-blue-100 bg-blue-50 p-3"
                >
                  <div className="min-w-0 flex-1">
                    <p className="truncate font-bold text-toon-dark">{post.title}</p>
                    <p className="mt-0.5 text-xs text-gray-500">
                      {post.steps.length} {post.steps.length === 1 ? 'step' : 'steps'} · shared by you
                    </p>
                  </div>
                  <button
                    type="button"
                    aria-label={`Delete ${post.title}`}
                    onClick={() => deleteSharedPost(post.id)}
                    className="press-springy flex h-11 w-11 items-center justify-center rounded-full text-gray-300 transition-colors hover:bg-red-50 hover:text-red-400"
                  >
                    <Trash2 size={16} />
                  </button>
                  {onCookThis && post.steps.length > 0 && (
                    <button
                      type="button"
                      onClick={() => {
                        setActivePanel(null);
                        onCookThis(post);
                      }}
                      className="press-springy btn-candy flex min-h-11 items-center gap-1.5 rounded-full px-4 text-xs font-bold text-white"
                    >
                      <PlayCircle size={14} aria-hidden="true" /> Open
                    </button>
                  )}
                </article>
              ))}

              {cookbookRecipes.map((recipe) => (
                <article key={recipe.id} className="rounded-2xl border border-blue-100 bg-blue-50 p-4">
                  <p className="font-bold text-toon-dark">{recipe.title}</p>
                  <p className="mt-1 text-sm text-gray-500">
                    {recipe.steps.length} {recipe.steps.length === 1 ? 'step' : 'steps'}
                  </p>
                </article>
              ))}

              {sharedPosts.length === 0 && cookbookRecipes.length === 0 && (
                <EmptyPanel
                  icon={<BookOpen className="text-blue-400 animate-float" aria-hidden="true" />}
                  title="No cookbook recipes yet"
                  body="Build a recipe and share it to the community — it is filed here too."
                  tone="border-blue-100 bg-blue-50/60"
                />
              )}
            </div>
          )}

          {activePanel === 'settings' && user && (
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
                <p className="mt-1 text-sm text-gray-600">
                  {user.isVip
                    ? 'Your subscription is active across your signed-in kitchens.'
                    : 'Manage a web subscription through secure Stripe Checkout.'}
                </p>
                <button
                  type="button"
                  onClick={handleCheckout}
                  disabled={checkoutLoading || user.billingStatus === 'loading' || user.billingStatus === 'error' || user.billingProvider === 'google_play' || ((user.isVip || user.billingProvider === 'stripe') ? !isStripePortalConfigured() : !isStripeCheckoutConfigured())}
                  className="press-springy mt-3 w-full rounded-xl bg-toon-primary py-2.5 text-sm font-bold text-white transition-colors hover:bg-toon-primary-deep disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {checkoutLoading ? 'Opening secure billing...' : user.billingProvider === 'google_play' ? 'Managed through Google Play' : (user.isVip || user.billingProvider === 'stripe') ? 'Manage subscription' : 'Get Kitchen Diary Plus'}
                </button>
                {user.billingProvider === 'google_play' && <a className="mt-2 block text-sm underline" href="https://play.google.com/store/account/subscriptions?package=com.kitchendiary.app">Manage in Google Play</a>}
                {user.billingStatus === 'loading' && <p role="status" className="mt-2 text-sm">Checking your subscription…</p>}
                {user.billingStatus === 'error' && <p role="alert" className="mt-2 text-sm">Unable to check your subscription. Please reload or contact support before starting checkout.</p>}
                {(user.isVip || user.billingProvider === 'stripe') && user.billingProvider !== 'google_play' && !isStripePortalConfigured() && <p className="mt-2 text-sm text-gray-600">Subscription management is not available yet. Please contact support.</p>}
                {!user.isVip && !user.billingProvider && !isStripeCheckoutConfigured() && (
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

  /** Saved / History / Cookbook — identical whether or not anyone is signed in. */
  const kitchenShelf = (
    <section aria-labelledby="kitchen-shelf-heading" className="mb-6">
      <h2 id="kitchen-shelf-heading" className="mb-3 font-display text-lg font-semibold text-toon-dark">
        Your kitchen
      </h2>
      <div className="grid grid-cols-3 gap-3 stagger-children">
        <button
          type="button"
          onClick={() => setActivePanel('favorites')}
          className="press-springy toon-card group flex flex-col items-center gap-2 rounded-2xl p-4 transition-all hover:-translate-y-1 hover:shadow-toon-lift"
        >
          <span className="flex h-11 w-11 items-center justify-center rounded-full bg-gradient-to-br from-pink-50 to-pink-100 shadow-[inset_0_1px_0_rgba(255,255,255,0.8)] transition-transform duration-300 group-hover:scale-110 group-hover:-rotate-6">
            <Heart className="text-pink-400" aria-hidden="true" />
          </span>
          <span className="text-sm font-bold text-gray-600">Saved</span>
          <span className="text-[10px] font-bold uppercase tracking-wider text-gray-400">
            {favorites.length}
          </span>
        </button>
        <button
          type="button"
          onClick={() => setActivePanel('history')}
          className="press-springy toon-card group flex flex-col items-center gap-2 rounded-2xl p-4 transition-all hover:-translate-y-1 hover:shadow-toon-lift"
        >
          <span className="flex h-11 w-11 items-center justify-center rounded-full bg-gradient-to-br from-amber-50 to-amber-100 shadow-[inset_0_1px_0_rgba(255,255,255,0.8)] transition-transform duration-300 group-hover:scale-110 group-hover:rotate-6">
            <History className="text-amber-500" aria-hidden="true" />
          </span>
          <span className="text-sm font-bold text-gray-600">History</span>
          <span className="text-[10px] font-bold uppercase tracking-wider text-gray-400">
            {history.length}
          </span>
        </button>
        <button
          type="button"
          onClick={() => setActivePanel('cookbook')}
          className="press-springy toon-card group flex flex-col items-center gap-2 rounded-2xl p-4 transition-all hover:-translate-y-1 hover:shadow-toon-lift"
        >
          <span className="flex h-11 w-11 items-center justify-center rounded-full bg-gradient-to-br from-blue-50 to-blue-100 shadow-[inset_0_1px_0_rgba(255,255,255,0.8)] transition-transform duration-300 group-hover:scale-110 group-hover:rotate-6">
            <BookOpen className="text-blue-400" aria-hidden="true" />
          </span>
          <span className="text-sm font-bold text-gray-600">Cookbook</span>
          <span className="text-[10px] font-bold uppercase tracking-wider text-gray-400">
            {sharedPosts.length + cookbookRecipes.length}
          </span>
        </button>
      </div>
    </section>
  );

  if (!user) {
    return (
      <div className="relative min-h-screen overflow-hidden px-4 pb-28">
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

        <div className="relative flex flex-col items-center pt-12">
          <div className="relative mb-6">
            <span aria-hidden="true" className="toon-sunburst absolute -inset-14 rounded-full" />
            <div className="animate-pop-in toon-sticker relative flex h-24 w-24 items-center justify-center rounded-full bg-gradient-to-br from-white to-orange-50 [&>span:last-child]:hidden">
              <span className="text-5xl" aria-hidden="true">{'\u{1F9D1}‍\u{1F373}'}</span>
              <span className="text-5xl">🍳</span>
            </div>
          </div>
          <h1 className="animate-rise mb-2 font-display text-4xl font-semibold" style={{ animationDelay: '100ms' }}>
            <span className="text-candy">CookToon</span>
          </h1>
          <p
            className="animate-rise mb-6 max-w-xs text-center text-gray-500"
            style={{ animationDelay: '180ms' }}
          >
            Sign in securely with your Google account to save your Kitchen Diary.
          </p>

          <button
            onClick={handleLogin}
            disabled={loading}
            className="press-springy btn-candy animate-rise w-full max-w-xs rounded-2xl py-4 font-bold text-white disabled:opacity-70"
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
          {authError && (
            <p role="alert" className="mt-3 max-w-xs text-center text-xs font-medium text-red-500">
              {authError}
            </p>
          )}
        </div>

        {/* Saved dishes and cook history belong to this device, so they stay
            reachable without an account. */}
        <div className="relative mt-10">
          <div className="toon-card mb-6 flex justify-around rounded-[2rem] p-5 stagger-children">
            {kitchenStats.map((stat) => (
              <div key={stat.label} className="text-center">
                <div className="font-display text-xl font-semibold text-toon-dark">{stat.value}</div>
                <div className="text-xs font-bold uppercase tracking-wider text-gray-400">{stat.label}</div>
              </div>
            ))}
          </div>
          {kitchenShelf}
          <p className="text-center text-xs text-gray-400">
            Saved on this device. Sign in to sync it across your kitchens.
          </p>
        </div>

        {renderPanel()}
      </div>
    );
  }

  return (
    <div className="min-h-screen px-4 pb-28">
      <header className="flex justify-end py-6">
        <button
          type="button"
          aria-label="Profile settings"
          onClick={() => setActivePanel('settings')}
          className="press-springy flex h-11 w-11 items-center justify-center rounded-full text-gray-400 transition-colors hover:bg-white hover:text-toon-dark hover:shadow-toon-soft"
        >
          <Settings size={24} />
        </button>
      </header>

      <div className="toon-card relative mb-6 mt-10 rounded-[2rem] p-6 animate-pop-in">
        <div className="toon-sticker absolute -top-12 left-1/2 flex h-24 w-24 -translate-x-1/2 items-center justify-center overflow-hidden rounded-full bg-gradient-to-br from-orange-100 to-toon-secondary/50 text-4xl animate-float">
          <Avatar avatar={user.avatar} name={user.name} />
        </div>

        <div className="mt-12 text-center">
          <h2 className="font-display text-2xl font-semibold text-toon-dark">{user.name}</h2>
          <p className="mt-1 text-sm text-gray-400">{user.bio}</p>

          <div className="mt-6 flex justify-center gap-8 border-t border-orange-50 pt-6 stagger-children">
            {[...kitchenStats, ...accountStats].map((stat) => (
              <div key={stat.label} className="text-center">
                <div className="font-display text-xl font-semibold text-toon-dark">{stat.value}</div>
                <div className="text-xs font-bold uppercase tracking-wider text-gray-400">{stat.label}</div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {kitchenShelf}

      <button
        onClick={handleLogout}
        className="press-springy flex w-full items-center justify-center gap-2 rounded-2xl border border-red-50 bg-white py-4 font-bold text-red-400 transition-colors hover:bg-red-50"
      >
        <LogOut size={20} aria-hidden="true" /> Sign Out
      </button>
      {renderPanel()}
    </div>
  );
};
