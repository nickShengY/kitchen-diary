import React, { useEffect, useState } from 'react';
import { UserProfile } from '../types';
import { login, logout, getCurrentUser } from '../services/authService';
import { LogOut, Heart, BookOpen, Settings } from 'lucide-react';

const formatCount = (value: number | undefined): string => {
  const safe = value ?? 0;
  if (safe >= 1000) return `${(safe / 1000).toFixed(1)}k`;
  return `${safe}`;
};

export const Profile: React.FC = () => {
  const [user, setUser] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(false);
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
  }, []);

  const handleLogin = async () => {
    setLoading(true);
    try {
      const liveUser = await login();
      setUser(liveUser);
    } catch {
      // Keep user on login screen if auth request fails.
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = async () => {
    try {
      await logout();
      setUser(null);
    } catch {
      // Ignore logout failures to keep UI stable.
    }
  };

  if (!user) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center p-6 bg-[#FFF5F0]">
        <div className="w-24 h-24 bg-white rounded-full shadow-lg flex items-center justify-center mb-6 animate-bounce-slow">
          <span className="text-5xl">🍳</span>
        </div>
        <h1 className="text-3xl font-bold text-toon-dark mb-2">CookToon</h1>
        <p className="text-gray-500 mb-8 text-center">Join the cooking community and sync your live profile.</p>

        <button
          onClick={handleLogin}
          disabled={loading}
          className="w-full max-w-xs bg-toon-primary text-white font-bold py-4 rounded-2xl shadow-lg hover:bg-orange-400 disabled:opacity-70 transition-all"
        >
          {loading ? 'Signing you in...' : 'Sign In with Google'}
        </button>
        <p className="mt-4 text-xs text-gray-400">Powered by live identity data</p>
      </div>
    );
  }

  return (
    <div className="pb-24 px-4 min-h-screen bg-[#FFF5F0]">
      <header className="py-6 flex justify-end">
        <button className="p-2 text-gray-400 hover:text-toon-dark">
          <Settings size={24} />
        </button>
      </header>

      <div className="bg-white rounded-[2rem] p-6 shadow-sm mb-6 relative mt-10">
        <div className="absolute -top-12 left-1/2 -translate-x-1/2 w-24 h-24 bg-orange-100 rounded-full border-4 border-white flex items-center justify-center text-4xl shadow-md">
          {user.avatar}
        </div>

        <div className="mt-12 text-center">
          <h2 className="text-2xl font-bold text-toon-dark">{user.name}</h2>
          <p className="text-gray-400 text-sm mt-1">{user.bio}</p>

          <div className="flex justify-center gap-8 mt-6 border-t border-gray-50 pt-6">
            {stats.map((stat) => (
              <div key={stat.label} className="text-center">
                <div className="font-bold text-xl text-toon-dark">{stat.value}</div>
                <div className="text-xs text-gray-400 uppercase font-bold tracking-wider">{stat.label}</div>
              </div>
            ))}
          </div>
          {stats.length === 1 && (
            <p className="mt-4 text-xs text-gray-400">
              Social totals will appear once your connected backend provides them.
            </p>
          )}
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4 mb-6">
        <button className="bg-white p-4 rounded-2xl shadow-sm hover:shadow-md transition-all flex flex-col items-center gap-2">
          <Heart className="text-pink-400" />
          <span className="font-bold text-sm text-gray-600">Favorites</span>
        </button>
        <button className="bg-white p-4 rounded-2xl shadow-sm hover:shadow-md transition-all flex flex-col items-center gap-2">
          <BookOpen className="text-blue-400" />
          <span className="font-bold text-sm text-gray-600">My Cookbook</span>
        </button>
      </div>

      <button
        onClick={handleLogout}
        className="w-full bg-white text-red-400 font-bold py-4 rounded-2xl flex items-center justify-center gap-2 hover:bg-red-50 transition-colors"
      >
        <LogOut size={20} /> Sign Out
      </button>
    </div>
  );
};
