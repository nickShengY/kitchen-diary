import React, { useMemo, useState } from 'react';
import { Send, Sparkles, X } from 'lucide-react';
import { RecipeStep } from '../types';
import { INGREDIENTS } from '../data/kitchenData';
import { shareRecipeToCommunity } from '../services/communityStore';

interface ShareSheetProps {
  recipeName: string;
  steps: RecipeStep[];
  onClose: () => void;
  onShared: () => void;
}

const SHARE_TAGS = ['Breakfast', 'Lunch', 'Dinner', 'Dessert', 'Healthy', 'Quick'];

export const ShareSheet: React.FC<ShareSheetProps> = ({ recipeName, steps, onClose, onShared }) => {
  const [title, setTitle] = useState(recipeName);
  const [description, setDescription] = useState('');
  const [selectedTags, setSelectedTags] = useState<string[]>([]);
  const [isSharing, setIsSharing] = useState(false);

  const ingredientEmojis = useMemo(() => {
    const ids = steps.flatMap((step) => step.ingredients.map((item) => item.id));
    const unique = Array.from(new Set(ids));
    return unique
      .map((id) => INGREDIENTS.find((ingredient) => ingredient.id === id)?.emoji)
      .filter((emoji): emoji is string => Boolean(emoji))
      .slice(0, 6);
  }, [steps]);

  const toggleTag = (tag: string) => {
    setSelectedTags((current) =>
      current.includes(tag) ? current.filter((t) => t !== tag) : [...current, tag],
    );
  };

  const handleShare = () => {
    if (isSharing) return;
    setIsSharing(true);
    shareRecipeToCommunity({
      title,
      description,
      tags: selectedTags,
      steps,
    });
    // A tiny beat so the button's "Sharing..." state reads as a real handoff.
    window.setTimeout(onShared, 450);
  };

  return (
    <div
      className="fixed inset-0 z-[70] flex items-end bg-black/30 px-4 pb-4 backdrop-blur-sm animate-fade"
      onClick={(event) => {
        if (event.target === event.currentTarget) onClose();
      }}
    >
      <section
        role="dialog"
        aria-modal="true"
        aria-labelledby="share-sheet-title"
        className="mx-auto w-full max-w-md rounded-[2rem] bg-white p-5 shadow-2xl animate-sheet-up"
      >
        <div aria-hidden="true" className="mx-auto mb-3 h-1.5 w-12 rounded-full bg-orange-100" />
        <div className="mb-4 flex items-center justify-between gap-4">
          <h2 id="share-sheet-title" className="flex items-center gap-2 font-display text-xl font-semibold text-toon-dark">
            <Sparkles size={18} className="text-toon-primary" aria-hidden="true" /> Share your recipe
          </h2>
          <button
            type="button"
            aria-label="Close share sheet"
            onClick={onClose}
            className="press-springy rounded-full bg-gray-50 p-2 text-gray-400 transition-colors hover:bg-gray-100 hover:text-toon-dark"
          >
            <X size={20} />
          </button>
        </div>

        {/* Recipe summary card */}
        <div className="mb-4 rounded-2xl border border-orange-100 bg-gradient-to-br from-orange-50 to-toon-cream p-4">
          <div className="flex items-center justify-between gap-3">
            <div className="min-w-0">
              <p className="truncate font-bold text-toon-dark">{title || 'My Kitchen Diary Recipe'}</p>
              <p className="mt-0.5 text-xs font-semibold text-gray-500">
                {steps.length} {steps.length === 1 ? 'step' : 'steps'} · plays like a little cartoon
              </p>
            </div>
            {ingredientEmojis.length > 0 ? (
              <div className="flex shrink-0 -space-x-2" aria-hidden="true">
                {ingredientEmojis.map((emoji, index) => (
                  <span
                    key={`${emoji}-${index}`}
                    className="flex h-8 w-8 items-center justify-center rounded-full border-2 border-white bg-white text-base shadow-sm"
                  >
                    {emoji}
                  </span>
                ))}
              </div>
            ) : null}
          </div>
        </div>

        <label className="mb-3 block">
          <span className="mb-1 block text-xs font-bold uppercase tracking-wide text-toon-primary">Title</span>
          <input
            value={title}
            onChange={(event) => setTitle(event.target.value)}
            placeholder="Name your recipe..."
            className="w-full rounded-2xl border border-orange-100 bg-orange-50/60 px-4 py-3 text-sm font-semibold text-toon-dark outline-none transition focus:border-toon-primary focus:bg-white"
          />
        </label>

        <label className="mb-3 block">
          <span className="mb-1 block text-xs font-bold uppercase tracking-wide text-toon-primary">Say something tasty</span>
          <textarea
            value={description}
            onChange={(event) => setDescription(event.target.value)}
            rows={2}
            placeholder="What makes this dish special?"
            className="w-full resize-none rounded-2xl border border-orange-100 bg-orange-50/60 px-4 py-3 text-sm font-medium text-toon-dark outline-none transition focus:border-toon-primary focus:bg-white"
          />
        </label>

        <p className="mb-2 text-xs font-bold uppercase tracking-wide text-toon-primary">Tags</p>
        <div className="mb-5 flex flex-wrap gap-2">
          {SHARE_TAGS.map((tag) => (
            <button
              key={tag}
              type="button"
              aria-pressed={selectedTags.includes(tag)}
              onClick={() => toggleTag(tag)}
              className={`press-springy min-h-10 rounded-full px-4 py-2 text-xs font-bold transition-all ${
                selectedTags.includes(tag)
                  ? 'bg-toon-dark text-white shadow-md scale-105'
                  : 'bg-orange-50 text-gray-500 border border-orange-100 hover:border-toon-secondary hover:text-toon-dark'
              }`}
            >
              {tag}
            </button>
          ))}
        </div>

        <button
          type="button"
          onClick={handleShare}
          disabled={isSharing || steps.length === 0}
          className="press-springy btn-candy flex w-full items-center justify-center gap-2 rounded-2xl py-4 font-display text-lg font-semibold text-white disabled:opacity-60"
        >
          <Send size={18} aria-hidden="true" />
          {isSharing ? 'Sharing...' : 'Share to Community'}
        </button>
      </section>
    </div>
  );
};
