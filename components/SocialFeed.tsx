import React from 'react';
import { Heart, MessageCircle, Star } from 'lucide-react';

import { SocialPost } from '../types';

interface SocialFeedProps {
  posts?: SocialPost[];
}

export const SocialFeed: React.FC<SocialFeedProps> = ({ posts = [] }) => {
  return (
    <div className="pb-24 px-4 min-h-screen">
      <header className="py-6 sticky top-0 bg-[#FFF5F0]/90 backdrop-blur-sm z-10">
        <h1 className="text-3xl font-bold text-toon-dark">Community</h1>
        <div className="flex gap-4 mt-4 overflow-x-auto hide-scrollbar pb-2">
          {['Popular', 'Recent', 'Baking', 'Healthy', 'Quick'].map(
            (tag, index) => (
              <button
                key={tag}
                className={`px-4 py-2 rounded-full font-bold text-sm whitespace-nowrap ${
                  index === 0
                    ? 'bg-toon-primary text-white shadow-md'
                    : 'bg-white text-gray-500 border border-gray-100'
                }`}
              >
                {tag}
              </button>
            ),
          )}
        </div>
      </header>

      {posts.length === 0 ? (
        <div className="mt-10 rounded-3xl bg-white p-8 text-center shadow-md">
          <Star className="mx-auto mb-3 text-toon-primary" size={28} />
          <h2 className="text-xl font-bold text-toon-dark">No posts yet</h2>
          <p className="mt-2 text-sm text-gray-500">
            Connect the community feed to backend data to show real posts here.
          </p>
        </div>
      ) : (
        <div className="columns-2 gap-4 space-y-4">
          {posts.map((post) => (
            <div
              key={post.id}
              className="break-inside-avoid bg-white rounded-3xl shadow-md overflow-hidden hover:shadow-xl transition-shadow duration-300"
            >
              <div className="relative group">
                {post.imageUrl ? (
                  <img
                    src={post.imageUrl}
                    alt={post.title}
                    className="w-full h-auto object-cover"
                  />
                ) : (
                  <div className="flex h-48 items-center justify-center bg-orange-50 text-5xl">
                    {post.authorAvatar}
                  </div>
                )}
                <div className="absolute inset-0 bg-black/0 group-hover:bg-black/10 transition-colors" />
              </div>
              <div className="p-4">
                <h3 className="font-bold text-toon-dark mb-1">{post.title}</h3>
                <div className="flex items-center gap-2 mb-3">
                  <span className="bg-gray-100 rounded-full w-6 h-6 flex items-center justify-center text-xs">
                    {post.authorAvatar}
                  </span>
                  <span className="text-xs text-gray-500 font-medium truncate">
                    {post.authorName}
                  </span>
                </div>
                <p className="text-xs text-gray-400 mb-4 line-clamp-2">
                  {post.description}
                </p>

                <div className="flex items-center justify-between text-gray-400">
                  <button className="flex items-center gap-1 hover:text-pink-500 transition-colors">
                    <Heart size={16} />{' '}
                    <span className="text-xs font-bold">{post.likes}</span>
                  </button>
                  <button className="flex items-center gap-1 hover:text-blue-500 transition-colors">
                    <MessageCircle size={16} />{' '}
                    <span className="text-xs font-bold">{post.comments}</span>
                  </button>
                </div>
              </div>
            </div>
          ))}

          <div className="break-inside-avoid bg-gradient-to-br from-toon-secondary to-toon-primary rounded-3xl shadow-md p-6 text-white text-center">
            <Star className="mx-auto mb-2 text-yellow-200 fill-current" size={32} />
            <h3 className="font-bold text-xl mb-2">Make a Wish!</h3>
            <p className="text-sm opacity-90 mb-4">
              Can&apos;t find what you need? Ask the community.
            </p>
            <button className="bg-white text-toon-primary font-bold px-4 py-2 rounded-full text-sm shadow-sm hover:scale-105 transition-transform">
              Post Request
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
