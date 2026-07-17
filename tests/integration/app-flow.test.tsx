import { describe, it, expect, vi, beforeEach, Mock } from 'vitest';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import React, { useState } from 'react';
import { Navigation } from '../../components/Navigation';
import { Community } from '../../components/Community';
import { RecipeBuilder } from '../../components/RecipeBuilder';
import { DeciderWheel } from '../../components/DeciderWheel';
import { Profile } from '../../components/Profile';
import { AppView, Recipe } from '../../types';

vi.mock('../../services/geminiService', () => ({
  searchSmartRecipes: vi.fn(),
  analyzeMenuImage: vi.fn(),
  getFoodDescription: vi.fn(),
}));

vi.mock('../../services/liveDataService', () => ({
  fetchCommunityFeed: vi.fn(),
  fetchCuisineWheelData: vi.fn(),
}));

vi.mock('../../services/authService', () => ({
  login: vi.fn(),
  logout: vi.fn(),
  getCurrentUser: vi.fn(),
  subscribeToAuthState: vi.fn(() => () => undefined),
}));

import { searchSmartRecipes, analyzeMenuImage, getFoodDescription } from '../../services/geminiService';
import { fetchCommunityFeed, fetchCuisineWheelData } from '../../services/liveDataService';
import { login, logout, getCurrentUser } from '../../services/authService';

const TestApp: React.FC = () => {
  const [currentView, setCurrentView] = useState<AppView>(AppView.COMMUNITY);
  const [selectedRecipe, setSelectedRecipe] = useState<Recipe | null>(null);

  const handleCookThis = (recipe: Recipe) => {
    setSelectedRecipe(recipe);
    setCurrentView(AppView.BUILDER);
  };

  return (
    <div>
      {currentView === AppView.COMMUNITY && <Community onCookThis={handleCookThis} />}
      {currentView === AppView.BUILDER && <RecipeBuilder initialRecipe={selectedRecipe || undefined} />}
      {currentView === AppView.DECIDER && <DeciderWheel />}
      {currentView === AppView.PROFILE && <Profile />}
      <Navigation currentView={currentView} setView={setCurrentView} />
    </div>
  );
};

describe('App integration flows', () => {
  beforeEach(() => {
    vi.useFakeTimers({ shouldAdvanceTime: true });
    (fetchCommunityFeed as Mock).mockResolvedValue([
      {
        id: '1',
        title: 'Live Pasta',
        authorId: 'a1',
        authorName: 'Italian Kitchen',
        authorAvatar: '🍝',
        imageUrl: 'https://example.com/pasta.jpg',
        likes: 100,
        comments: 20,
        description: 'Fresh pasta.',
        steps: [],
        tags: ['Dinner'],
        createdAt: Date.now(),
      },
    ]);
    (searchSmartRecipes as Mock).mockResolvedValue([]);
    (fetchCuisineWheelData as Mock).mockResolvedValue([
      { id: 'it', name: 'Italian', emoji: '🍝', dishes: ['Carbonara'] },
    ]);
    (analyzeMenuImage as Mock).mockResolvedValue([{ name: 'Ramen' }]);
    (getFoodDescription as Mock).mockResolvedValue('Rich broth and noodles.');
    (getCurrentUser as Mock).mockReturnValue(null);
    (login as Mock).mockResolvedValue({
      id: 'u1',
      name: 'Live Chef',
      avatar: '👩‍🍳',
      bio: 'Live bio.',
      favorites: [],
      myRecipes: [],
      recipesCount: 12,
      followersCount: 1200,
      likesReceived: 2800,
    });
    (logout as Mock).mockResolvedValue(undefined);
  });

  it('navigates across all main views', async () => {
    const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime });
    render(<TestApp />);

    await screen.findByText('Live Pasta');
    await user.click(screen.getByRole('button', { name: /^Decide$/ }));
    await screen.findByText('Italian');

    await user.click(screen.getByRole('button', { name: /^Profile$/ }));
    expect(screen.getByText('CookToon')).toBeInTheDocument();

    await user.click(screen.getByRole('button', { name: /^Explore$/ }));
    expect(screen.getByRole('heading', { name: 'Explore' })).toBeInTheDocument();
  });

  it('opens recipe builder from Cook This action', async () => {
    const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime });
    render(<TestApp />);

    const cookThis = await screen.findByRole('button', { name: /cook this/i });
    await user.click(cookThis);

    expect(screen.getByPlaceholderText(/name your recipe/i)).toBeInTheDocument();
  });

  it('supports decider scan mode result', async () => {
    const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime });
    render(<TestApp />);

    await user.click(screen.getByRole('button', { name: /^Decide$/ }));
    await user.click(screen.getByRole('button', { name: /^Scan$/ }));

    const input = document.querySelector('input[type="file"]') as HTMLInputElement;
    const file = new File(['content'], 'menu.jpg', { type: 'image/jpeg' });
    Object.defineProperty(input, 'files', { value: [file] });
    fireEvent.change(input);

    await waitFor(() => {
      expect(screen.getByText('Ramen')).toBeInTheDocument();
    });
  });
});
