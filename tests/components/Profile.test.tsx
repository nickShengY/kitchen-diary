import { describe, it, expect, vi, beforeEach, Mock } from 'vitest';
import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Profile } from '../../components/Profile';

vi.mock('../../services/authService', () => ({
  login: vi.fn(),
  logout: vi.fn(),
  getCurrentUser: vi.fn(),
  subscribeToAuthState: vi.fn(() => () => undefined),
}));

import { login, logout, getCurrentUser } from '../../services/authService';
import { savePantry, EMPTY_PANTRY, loadPantry } from '../../services/pantryStore';
import { shareRecipeToCommunity } from '../../services/communityStore';

describe('Profile Component', () => {
  const mockUser = {
    id: 'live-user',
    name: 'Live Chef',
    avatar: '👩‍🍳',
    bio: 'Cooking with real data.',
    favorites: [],
    myRecipes: [],
    recipesCount: 12,
    followersCount: 1500,
    likesReceived: 3400,
  };

  beforeEach(() => {
    (login as Mock).mockReset();
    (logout as Mock).mockReset();
    (getCurrentUser as Mock).mockReset();
    (login as Mock).mockResolvedValue(mockUser);
    (logout as Mock).mockResolvedValue(undefined);
    (getCurrentUser as Mock).mockReturnValue(null);
  });

  it('renders signed-out state by default', () => {
    render(<Profile />);

    expect(screen.getByText('Kitchen Diary')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /continue with google/i })).toBeInTheDocument();
  });

  it('shows profile after successful login', async () => {
    const user = userEvent.setup();
    render(<Profile />);

    await user.click(screen.getByRole('button', { name: /continue with google/i }));

    await waitFor(() => {
      expect(screen.getByText('Live Chef')).toBeInTheDocument();
      expect(screen.getByText('Followers')).toBeInTheDocument();
    });
  });

  it('loads persisted profile on mount', () => {
    (getCurrentUser as Mock).mockReturnValue(mockUser);
    render(<Profile />);

    expect(screen.getByText('Live Chef')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /sign out/i })).toBeInTheDocument();
  });

  it('opens the saved recipes panel', async () => {
    (getCurrentUser as Mock).mockReturnValue(mockUser);
    const user = userEvent.setup();
    render(<Profile />);

    await user.click(screen.getByRole('button', { name: /^saved/i }));

    expect(screen.getByRole('dialog', { name: /saved recipes/i })).toBeInTheDocument();
    expect(screen.getByText('No saved recipes yet')).toBeInTheDocument();
  });

  it('opens the cookbook panel', async () => {
    (getCurrentUser as Mock).mockReturnValue(mockUser);
    const user = userEvent.setup();
    render(<Profile />);

    await user.click(screen.getByRole('button', { name: /^cookbook/i }));

    expect(screen.getByRole('dialog', { name: /my cookbook/i })).toBeInTheDocument();
    expect(screen.getByText('No cookbook recipes yet')).toBeInTheDocument();
  });

  it('opens profile settings', async () => {
    (getCurrentUser as Mock).mockReturnValue(mockUser);
    const user = userEvent.setup();
    render(<Profile />);

    await user.click(screen.getByRole('button', { name: /profile settings/i }));

    expect(screen.getByRole('dialog', { name: /profile settings/i })).toBeInTheDocument();
    expect(screen.getByText('Signed in with your Google account.')).toBeInTheDocument();
    expect(screen.getByText(/Web checkout is not available/)).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /get kitchen diary plus|manage subscription/i })).not.toBeInTheDocument();
  });

  it.each(['google_play', 'stripe'])('preserves existing %s access without web checkout', async (billingProvider) => {
    (getCurrentUser as Mock).mockReturnValue({ ...mockUser, isVip: true, billingProvider, billingStatus: 'ready' });
    render(<Profile />);
    await userEvent.setup().click(screen.getByRole('button', { name: /profile settings/i }));
    expect(screen.getByText(/Your subscription is active/)).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /get kitchen diary plus|manage subscription/i })).not.toBeInTheDocument();
    if (billingProvider === 'google_play') expect(screen.getByRole('link', { name: 'Manage in Google Play' })).toHaveAttribute('href', 'https://play.google.com/store/account/subscriptions?package=com.kitchendiary.app');
    else expect(screen.getByText(/Your existing access is still recognized/)).toBeInTheDocument();
  });

  it('returns to signed-out state after logout', async () => {
    (getCurrentUser as Mock).mockReturnValue(mockUser);
    const user = userEvent.setup();
    render(<Profile />);

    await user.click(screen.getByRole('button', { name: /sign out/i }));

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /continue with google/i })).toBeInTheDocument();
    });
  });

  describe('local kitchen', () => {
    it('reaches saved dishes and history without signing in', async () => {
      savePantry({
        ...EMPTY_PANTRY,
        favorites: ['tomato-scrambled-eggs'],
        history: ['egg-fried-rice'],
      });
      const user = userEvent.setup();
      render(<Profile />);

      // The sign-in card is still there, but it no longer blocks the kitchen.
      expect(screen.getByRole('button', { name: /continue with google/i })).toBeInTheDocument();

      await user.click(screen.getByRole('button', { name: /^saved/i }));
      expect(screen.getByText('Tomato Scrambled Eggs')).toBeInTheDocument();
    });

    it('lists recently cooked dishes newest first', async () => {
      savePantry({ ...EMPTY_PANTRY, history: ['egg-fried-rice', 'tomato-pasta'] });
      const user = userEvent.setup();
      render(<Profile />);

      await user.click(screen.getByRole('button', { name: /^history/i }));

      const dialog = screen.getByRole('dialog', { name: /recently cooked/i });
      const titles = within(dialog).getAllByRole('article').map((row) => row.textContent);
      expect(titles[0]).toContain('Leftover Egg Fried Rice');
      expect(titles[1]).toContain('Ten-Minute Tomato Pasta');
    });

    it('unsaves a dish and writes it back to storage', async () => {
      savePantry({ ...EMPTY_PANTRY, favorites: ['tomato-scrambled-eggs'] });
      const user = userEvent.setup();
      render(<Profile />);

      await user.click(screen.getByRole('button', { name: /^saved/i }));
      await user.click(screen.getByRole('button', { name: /unsave tomato scrambled eggs/i }));

      expect(screen.getByText('No saved recipes yet')).toBeInTheDocument();
      await waitFor(() => expect(loadPantry().favorites).toEqual([]));
    });

    it('clears the whole history', async () => {
      savePantry({ ...EMPTY_PANTRY, history: ['egg-fried-rice', 'tomato-pasta'] });
      const user = userEvent.setup();
      render(<Profile />);

      await user.click(screen.getByRole('button', { name: /^history/i }));
      await user.click(screen.getByRole('button', { name: /clear all/i }));

      expect(screen.getByText('Nothing cooked yet')).toBeInTheDocument();
      await waitFor(() => expect(loadPantry().history).toEqual([]));
    });

    it('sends a saved dish to the builder and records it as cooked', async () => {
      savePantry({ ...EMPTY_PANTRY, favorites: ['tomato-scrambled-eggs'] });
      const onCookThis = vi.fn();
      const user = userEvent.setup();
      render(<Profile onCookThis={onCookThis} />);

      await user.click(screen.getByRole('button', { name: /^saved/i }));
      await user.click(screen.getByRole('button', { name: /^cook$/i }));

      expect(onCookThis).toHaveBeenCalledTimes(1);
      expect(onCookThis.mock.calls[0][0].id).toBe('pantry-tomato-scrambled-eggs');
      await waitFor(() => expect(loadPantry().history).toEqual(['tomato-scrambled-eggs']));
    });

    it('files shared recipes into the cookbook', async () => {
      shareRecipeToCommunity({
        title: 'My Shared Dish',
        description: 'From the builder.',
        tags: ['Quick'],
        steps: [
          { id: 's1', station: 'prep', ingredients: [{ id: 'egg', amount: '1', unit: 'pcs' }], toolId: 'bowl', actionId: 'mix' },
        ],
      });
      const user = userEvent.setup();
      render(<Profile />);

      await user.click(screen.getByRole('button', { name: /^cookbook/i }));

      expect(screen.getByText('My Shared Dish')).toBeInTheDocument();
      expect(screen.getByText(/1 step . shared by you/i)).toBeInTheDocument();
    });

    it('drops dishes that are no longer in the corpus', async () => {
      savePantry({ ...EMPTY_PANTRY, favorites: ['a-recipe-we-deleted'] });
      const user = userEvent.setup();
      render(<Profile />);

      await user.click(screen.getByRole('button', { name: /^saved/i }));

      expect(screen.getByText('No saved recipes yet')).toBeInTheDocument();
    });
  });
});
