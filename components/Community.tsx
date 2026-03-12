import React, { useEffect, useMemo, useState } from 'react';
import { Heart, MessageCircle, Star, Search, Filter, Share2, PlayCircle } from 'lucide-react';
import { SocialPost, Recipe } from '../types';
import { searchSmartRecipes } from '../services/geminiService';
import { fetchCommunityFeed } from '../services/liveDataService';

interface CommunityProps {
  onCookThis: (recipe: Recipe) => void;
}

const TABS = ['Popular', 'Recent', 'Following'];
const TAGS = ['All', 'Breakfast', 'Lunch', 'Dinner', 'Dessert', 'Healthy', 'Quick'];

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
        setFeedError('Unable to load live community data right now.');
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

  const toggleLike = (id: string) => {
    if (likedPosts.includes(id)) {
      setLikedPosts(likedPosts.filter((postId) => postId !== id));
      return;
    }
    setLikedPosts([...likedPosts, id]);
  };

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    const normalizedQuery = searchQuery.trim();
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

  const filteredPosts = useMemo(() => {
    const normalizedQuery = searchQuery.trim().toLowerCase();
    return posts.filter((post) => {
      const matchesTag = activeTag === 'All' || post.tags.includes(activeTag);
      const matchesSearch =
        !normalizedQuery ||
        post.title.toLowerCase().includes(normalizedQuery) ||
        post.description.toLowerCase().includes(normalizedQuery);
      return matchesTag && matchesSearch;
    });
  }, [activeTag, posts, searchQuery]);

  return (
    <div className="pb-24 min-h-screen bg-[#FFF5F0]">
      <header className="sticky top-0 bg-[#FFF5F0]/95 backdrop-blur-md z-20 pt-6 pb-2 px-4 shadow-sm">
        <div className="flex justify-between items-center mb-4">
          <h1 className="text-3xl font-bold text-toon-dark">Explore</h1>
          <div className="w-10 h-10 bg-white rounded-full flex items-center justify-center shadow-sm text-toon-primary">
            <Filter size={20} />
          </div>
        </div>

        <form onSubmit={handleSearch} className="relative mb-4">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
          <input
            type="text"
            placeholder="Find recipes, chefs, tags..."
            value={searchQuery}
            onChange={(event) => setSearchQuery(event.target.value)}
            className="w-full bg-white pl-10 pr-4 py-3 rounded-2xl shadow-sm text-sm outline-none focus:ring-2 focus:ring-toon-secondary/50"
          />
          {(isSearching || isLoadingFeed) && (
            <div className="absolute right-3 top-1/2 -translate-y-1/2 animate-spin rounded-full h-4 w-4 border-b-2 border-toon-primary" />
          )}
        </form>

        <div className="flex justify-between border-b border-gray-200 mb-4">
          {TABS.map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`pb-2 px-4 font-bold text-sm transition-colors relative ${
                activeTab === tab ? 'text-toon-primary' : 'text-gray-400'
              }`}
            >
              {tab}
              {activeTab === tab && <div className="absolute bottom-0 left-0 w-full h-1 bg-toon-primary rounded-t-full" />}
            </button>
          ))}
        </div>

        <div className="flex gap-2 overflow-x-auto hide-scrollbar pb-2">
          {TAGS.map((tag) => (
            <button
              key={tag}
              onClick={() => setActiveTag(tag)}
              className={`px-4 py-1.5 rounded-full font-bold text-xs whitespace-nowrap transition-all ${
                activeTag === tag
                  ? 'bg-toon-dark text-white shadow-md scale-105'
                  : 'bg-white text-gray-500 border border-gray-100'
              }`}
            >
              {tag}
            </button>
          ))}
        </div>
      </header>

      <div className="px-4 mt-4 columns-2 gap-4 space-y-4">
        <div className="break-inside-avoid bg-gradient-to-br from-toon-secondary to-toon-primary rounded-3xl shadow-lg p-6 text-white text-center mb-4">
          <div className="bg-white/20 w-12 h-12 rounded-full flex items-center justify-center mx-auto mb-3 backdrop-blur-sm">
            <Star className="text-white fill-current animate-spin-slow" size={24} />
          </div>
          <h3 className="font-bold text-lg mb-1">Daily Wish</h3>
          <p className="text-xs opacity-90 mb-4 font-medium">What are you craving today?</p>
          <button className="bg-white text-toon-primary font-bold px-4 py-2 rounded-full text-xs shadow-sm hover:scale-105 transition-transform">
            Make a Wish
          </button>
        </div>

        {feedError && (
          <div className="break-inside-avoid bg-red-50 text-red-600 border border-red-100 rounded-2xl p-4 text-sm">
            {feedError}
          </div>
        )}

        {!isLoadingFeed && filteredPosts.length === 0 && !feedError && (
          <div className="break-inside-avoid bg-white rounded-2xl p-4 text-sm text-gray-500">
            No live recipes matched your filters.
          </div>
        )}

        {filteredPosts.map((post) => (
          <div
            key={post.id}
            className="break-inside-avoid bg-white rounded-3xl shadow-sm overflow-hidden hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 group"
          >
            <div className="relative">
              <img src={post.imageUrl} alt={post.title} className="w-full h-auto object-cover" />
              {typeof post.likes === 'number' ? (
                <button
                  type="button"
                  aria-label="Like count"
                  onClick={() => toggleLike(post.id)}
                  className="absolute top-2 right-2 bg-black/20 backdrop-blur-md px-2 py-1 rounded-full text-[10px] text-white font-bold flex items-center gap-1"
                >
                  <Heart size={10} className="fill-white" /> {post.likes + (likedPosts.includes(post.id) ? 1 : 0)}
                </button>
              ) : (
                <div className="absolute top-2 right-2 bg-black/20 backdrop-blur-md px-2 py-1 rounded-full text-[10px] text-white font-bold">
                  Live
                </div>
              )}

              <div className="absolute inset-0 bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                <button
                  onClick={() => onCookThis(post)}
                  className="bg-white text-toon-dark font-bold px-4 py-2 rounded-full flex items-center gap-2 transform translate-y-2 group-hover:translate-y-0 transition-transform"
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

              <div className="flex items-center justify-between border-t border-gray-50 pt-2">
                <button
                  aria-label="Like post"
                  onClick={() => toggleLike(post.id)}
                  className={`flex items-center gap-1 transition-colors ${
                    likedPosts.includes(post.id) ? 'text-pink-500' : 'text-gray-300 hover:text-pink-400'
                  }`}
                >
                  <Heart size={16} className={likedPosts.includes(post.id) ? 'fill-current animate-blob' : ''} />
                </button>
                <button className="flex items-center gap-1 text-gray-300 hover:text-blue-400 transition-colors">
                  <MessageCircle size={16} />
                  {typeof post.comments === 'number' && (
                    <span className="text-[10px] font-bold">{post.comments}</span>
                  )}
                </button>
                <button className="text-gray-300 hover:text-toon-primary">
                  <Share2 size={16} />
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};
