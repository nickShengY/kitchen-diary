import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Heart, MessageCircle, Star, Search, Filter, Share2, PlayCircle } from 'lucide-react';
import { SocialPost, Recipe } from '../types';
import { searchSmartRecipes } from '../services/geminiService';
import { fetchCommunityFeed } from '../services/liveDataService';

interface CommunityProps {
  onCookThis: (recipe: Recipe) => void;
}

const TABS = ['Popular', 'Recent', 'Saved'];
const TAGS = ['All', 'Breakfast', 'Lunch', 'Dinner', 'Dessert', 'Healthy', 'Quick'];
const WISHES = ['breakfast', 'chicken', 'noodles', 'dessert', 'vegetarian', 'soup'];

const mapRecipeToSocialPost = (recipe: Recipe): SocialPost => ({
  ...recipe,
  description: recipe.description || 'Fresh ideas from today\'s recipe search.',
});

export const Community: React.FC<CommunityProps> = ({ onCookThis }) => {
  const [activeTab, setActiveTab] = useState('Popular');
  const [activeTag, setActiveTag] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');
  const [posts, setPosts] = useState<SocialPost[]>([]);
  const [basePosts, setBasePosts] = useState<SocialPost[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [isLoadingFeed, setIsLoadingFeed] = useState(true);
  const [feedError, setFeedError] = useState<string | null>(null);
  const [likedPosts, setLikedPosts] = useState<string[]>([]);
  const [shareStatus, setShareStatus] = useState<string | null>(null);
  const searchInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    let cancelled = false;

    const loadFeed = async () => {
      setIsLoadingFeed(true);
      setFeedError(null);
      try {
        const livePosts = await fetchCommunityFeed();
        if (cancelled) return;
        setBasePosts(livePosts);
        setPosts(livePosts);
      } catch (error) {
        if (cancelled) return;
        setBasePosts([]);
        setPosts([]);
        setFeedError('Unable to load community recipes right now.');
      } finally {
        if (!cancelled) {
          setIsLoadingFeed(false);
        }
      }
    };

    loadFeed();
    return () => {
      cancelled = true;
    };
  }, []);

  // Share confirmations melt away on their own so they never block the feed.
  useEffect(() => {
    if (!shareStatus) return;
    const timer = window.setTimeout(() => setShareStatus(null), 4000);
    return () => window.clearTimeout(timer);
  }, [shareStatus]);

  const toggleLike = (id: string) => {
    if (likedPosts.includes(id)) {
      setLikedPosts(likedPosts.filter((postId) => postId !== id));
      return;
    }
    setLikedPosts([...likedPosts, id]);
  };

  const performSearch = async (query: string) => {
    const normalizedQuery = query.trim();
    if (!normalizedQuery) {
      setPosts(basePosts);
      return;
    }

    setIsSearching(true);
    try {
      const liveRecipes = await searchSmartRecipes(normalizedQuery);
      const searchedPosts = liveRecipes.map(mapRecipeToSocialPost);
      const merged = [...searchedPosts, ...basePosts];
      const deduped = merged.filter(
        (post, index) => merged.findIndex((candidate) => candidate.id === post.id) === index,
      );
      setPosts(deduped);
    } catch {
      setPosts(basePosts);
    } finally {
      setIsSearching(false);
    }
  };

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    await performSearch(searchQuery);
  };

  const handleMakeWish = async () => {
    const query = WISHES[Math.floor(Math.random() * WISHES.length)];
    setSearchQuery(query);
    await performSearch(query);
  };

  const handleFilterShortcut = () => {
    setActiveTag('All');
    searchInputRef.current?.focus();
  };

  const sharePost = async (post: SocialPost) => {
    const shareText = `${post.title} from Kitchen Diary`;
    const nav = typeof navigator !== 'undefined' ? navigator : undefined;
    try {
      if (nav && typeof nav.share === 'function') {
        await nav.share({ title: post.title, text: shareText });
      } else if (nav?.clipboard?.writeText) {
        await nav.clipboard.writeText(shareText);
      } else {
        setShareStatus(`${post.title} is ready to share from this browser.`);
        return;
      }
      setShareStatus(`Shared ${post.title}`);
    } catch {
      setShareStatus('Sharing was cancelled.');
    }
  };

  const filteredPosts = useMemo(() => {
    const normalizedQuery = searchQuery.trim().toLowerCase();
    const filtered = posts.filter((post) => {
      const matchesTab = activeTab !== 'Saved' || likedPosts.includes(post.id);
      const matchesTag = activeTag === 'All' || post.tags.includes(activeTag);
      const matchesSearch =
        !normalizedQuery ||
        post.title.toLowerCase().includes(normalizedQuery) ||
        post.description.toLowerCase().includes(normalizedQuery);
      return matchesTab && matchesTag && matchesSearch;
    });

    return [...filtered].sort((a, b) => {
      if (activeTab === 'Recent') return b.createdAt - a.createdAt;
      return (b.likes ?? 0) - (a.likes ?? 0);
    });
  }, [activeTab, activeTag, likedPosts, posts, searchQuery]);

  return (
    <div className="pb-24 min-h-screen">
      <header className="sticky top-0 bg-[#FFF5F0]/90 backdrop-blur-md z-20 pt-6 pb-2 px-4 shadow-[0_10px_30px_-18px_rgba(74,64,58,0.25)]">
        <div className="flex justify-between items-center mb-4">
          <div className="animate-rise">
            <p className="text-[11px] font-bold uppercase tracking-[0.2em] text-toon-primary">Kitchen Diary</p>
            <h1 className="font-display text-3xl font-semibold text-toon-dark leading-tight">Explore</h1>
          </div>
          <button
            type="button"
            aria-label="Focus recipe filters"
            onClick={handleFilterShortcut}
            className="press-springy h-11 w-11 bg-white rounded-full flex items-center justify-center shadow-toon-soft text-toon-primary hover:bg-orange-50 transition-colors"
          >
            <Filter size={20} />
          </button>
        </div>

        <form onSubmit={handleSearch} className="relative mb-4">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
          <input
            ref={searchInputRef}
            type="text"
            placeholder="Find recipes, chefs, tags..."
            value={searchQuery}
            onChange={(event) => setSearchQuery(event.target.value)}
            className="w-full bg-white pl-10 pr-10 py-3 rounded-2xl border border-orange-100/70 shadow-toon-soft text-sm font-medium outline-none transition-shadow focus:ring-2 focus:ring-toon-secondary/60 focus:shadow-toon-glow"
          />
          {(isSearching || isLoadingFeed) && (
            <div
              aria-hidden="true"
              className="absolute right-3.5 top-1/2 -translate-y-1/2 animate-spin rounded-full h-4 w-4 border-2 border-orange-100 border-b-toon-primary"
            />
          )}
        </form>

        <div className="flex justify-between border-b border-orange-100 mb-4" role="tablist" aria-label="Feed sorting">
          {TABS.map((tab) => (
            <button
              key={tab}
              role="tab"
              aria-selected={activeTab === tab}
              onClick={() => setActiveTab(tab)}
              className={`relative min-h-11 px-4 pb-2 font-bold text-sm transition-colors duration-200 ${
                activeTab === tab ? 'text-toon-primary' : 'text-gray-400 hover:text-toon-dark'
              }`}
            >
              {tab}
              <span
                aria-hidden="true"
                className={`absolute bottom-0 left-1/2 h-1 -translate-x-1/2 rounded-t-full bg-toon-primary transition-all duration-300 ${
                  activeTab === tab ? 'w-full opacity-100' : 'w-0 opacity-0'
                }`}
              />
            </button>
          ))}
        </div>

        <div className="flex gap-2 overflow-x-auto hide-scrollbar pb-2">
          {TAGS.map((tag) => (
            <button
              key={tag}
              aria-pressed={activeTag === tag}
              onClick={() => setActiveTag(tag)}
              className={`press-springy min-h-11 px-4 py-2 rounded-full font-bold text-xs whitespace-nowrap transition-all duration-200 ${
                activeTag === tag
                  ? 'bg-toon-dark text-white shadow-md scale-105'
                  : 'bg-white text-gray-500 border border-orange-100 hover:border-toon-secondary hover:text-toon-dark'
              }`}
            >
              {tag}
            </button>
          ))}
        </div>
      </header>

      {/* Screen-reader friendly toast for share results */}
      <div aria-live="polite" className="pointer-events-none fixed inset-x-0 top-4 z-[80] flex justify-center px-4">
        {shareStatus && (
          <p className="animate-pop-in rounded-full border border-green-100 bg-white/95 px-5 py-2.5 text-sm font-bold text-green-700 shadow-toon-soft backdrop-blur">
            {shareStatus}
          </p>
        )}
      </div>

      <div className="px-4 mt-4 columns-2 gap-4 space-y-4">
        <div className="break-inside-avoid relative overflow-hidden bg-gradient-to-br from-toon-secondary to-toon-primary rounded-3xl shadow-lg p-6 text-white text-center mb-4 animate-pop-in">
          <span aria-hidden="true" className="absolute -right-4 -top-4 h-16 w-16 rounded-full bg-white/15" />
          <span aria-hidden="true" className="absolute -left-6 bottom-2 h-20 w-20 rounded-full bg-white/10" />
          <div className="bg-white/20 w-12 h-12 rounded-full flex items-center justify-center mx-auto mb-3 backdrop-blur-sm">
            <Star className="text-white fill-current animate-spin-slow" size={24} />
          </div>
          <h3 className="font-display text-lg font-semibold mb-1">Daily Wish</h3>
          <p className="text-xs opacity-90 mb-4 font-medium">What are you craving today?</p>
          <button
            type="button"
            onClick={handleMakeWish}
            disabled={isSearching}
            className="press-springy min-h-11 bg-white text-toon-primary font-bold px-4 py-2 rounded-full text-xs shadow-sm hover:shadow-md transition-shadow disabled:opacity-70"
          >
            Make a Wish
          </button>
        </div>

        {feedError && (
          <div role="alert" className="break-inside-avoid bg-red-50 text-red-600 border border-red-100 rounded-2xl p-4 text-sm animate-rise">
            {feedError}
          </div>
        )}

        {isLoadingFeed &&
          Array.from({ length: 4 }).map((_, index) => (
            <div
              key={`feed-skeleton-${index}`}
              className="break-inside-avoid overflow-hidden rounded-3xl border border-orange-100 bg-white shadow-sm"
            >
              <div className="h-36 skeleton-shimmer" />
              <div className="space-y-2 p-3">
                <div className="h-3 w-3/4 rounded-full skeleton-shimmer" />
                <div className="h-3 w-1/2 rounded-full skeleton-shimmer" />
                <div className="mt-3 flex gap-2">
                  <div className="h-8 w-8 rounded-full skeleton-shimmer" />
                  <div className="h-8 flex-1 rounded-full skeleton-shimmer" />
                </div>
              </div>
            </div>
          ))}

        {!isLoadingFeed && filteredPosts.length === 0 && !feedError && (
          <div className="break-inside-avoid toon-card rounded-2xl p-5 text-center animate-pop-in">
            <span aria-hidden="true" className="mb-2 block text-3xl">🍽️</span>
            <p className="text-sm font-semibold text-gray-500">
              {activeTab === 'Saved'
                ? 'Like recipes to save them here.'
                : 'No live recipes matched your filters.'}
            </p>
          </div>
        )}

        {filteredPosts.map((post, index) => (
          <article
            key={post.id}
            style={{ animationDelay: `${Math.min(index, 8) * 60}ms` }}
            className="animate-rise break-inside-avoid toon-card rounded-3xl overflow-hidden hover:shadow-xl transition-all duration-300 hover:-translate-y-1 group"
          >
            <div className="relative overflow-hidden">
              <img
                src={post.imageUrl}
                alt={post.title}
                loading="lazy"
                className="w-full h-auto object-cover transition-transform duration-500 group-hover:scale-105"
              />
              {typeof post.likes === 'number' ? (
                <button
                  type="button"
                  aria-label="Like count"
                  onClick={() => toggleLike(post.id)}
                  className="absolute top-2 right-2 flex min-h-11 min-w-11 items-center justify-center gap-1 rounded-full bg-black/25 px-2 py-1 text-[10px] font-bold text-white backdrop-blur-md transition-colors hover:bg-black/40"
                >
                  <Heart size={10} className="fill-white" /> {post.likes + (likedPosts.includes(post.id) ? 1 : 0)}
                </button>
              ) : (
                <div className="absolute top-2 right-2 flex items-center gap-1 bg-black/25 backdrop-blur-md px-2 py-1 rounded-full text-[10px] text-white font-bold">
                  <span aria-hidden="true" className="h-1.5 w-1.5 rounded-full bg-green-400 animate-pulse" />
                  Live
                </div>
              )}

              <div className="absolute inset-0 bg-gradient-to-t from-black/50 via-black/20 to-transparent flex items-center justify-center opacity-0 group-hover:opacity-100 group-focus-within:opacity-100 transition-opacity duration-300">
                <button
                  onClick={() => onCookThis(post)}
                  className="press-springy flex min-h-11 items-center gap-2 rounded-full bg-white px-4 py-2 font-bold text-toon-dark shadow-lg transform translate-y-2 group-hover:translate-y-0 group-focus-within:translate-y-0 transition-transform duration-300"
                >
                  <PlayCircle size={16} className="text-toon-primary" /> Cook This
                </button>
              </div>
            </div>

            <div className="p-3">
              <h3 className="font-bold text-toon-dark text-sm mb-1 leading-tight">{post.title}</h3>
              <div className="flex items-center gap-1.5 mb-2">
                <span className="bg-orange-50 rounded-full w-5 h-5 flex items-center justify-center text-[10px] border border-orange-100">
                  {post.authorAvatar}
                </span>
                <span className="text-[10px] text-gray-500 font-bold truncate">{post.authorName}</span>
              </div>

              <p className="text-[11px] text-gray-400 mb-3 line-clamp-2 leading-relaxed">{post.description}</p>

              <div className="flex items-center justify-between border-t border-orange-50 pt-2">
                <button
                  aria-label="Like post"
                  aria-pressed={likedPosts.includes(post.id)}
                  onClick={() => toggleLike(post.id)}
                  className={`press-springy flex h-11 w-11 items-center justify-center gap-1 rounded-full transition-colors ${
                    likedPosts.includes(post.id) ? 'text-pink-500' : 'text-gray-300 hover:text-pink-400'
                  }`}
                >
                  <Heart size={16} className={likedPosts.includes(post.id) ? 'fill-current animate-pop-in' : ''} />
                </button>
                <div
                  aria-label="Comment count"
                  className="flex items-center gap-1 text-gray-300"
                >
                  <MessageCircle size={16} />
                  {typeof post.comments === 'number' && (
                    <span className="text-[10px] font-bold">{post.comments}</span>
                  )}
                </div>
                <button
                  type="button"
                  aria-label={`Share ${post.title}`}
                  onClick={() => sharePost(post)}
                  className="press-springy flex h-11 w-11 items-center justify-center rounded-full text-gray-300 hover:text-toon-primary transition-colors"
                >
                  <Share2 size={16} />
                </button>
              </div>
            </div>
          </article>
        ))}
      </div>
    </div>
  );
};
