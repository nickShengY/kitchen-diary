import { describe, it, expect, vi, beforeEach, Mock } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Profile } from '../../components/Profile';

vi.mock('../../services/authService', () => ({
  login: vi.fn(),
  logout: vi.fn(),
  getCurrentUser: vi.fn(),
}));

import { login, logout, getCurrentUser } from '../../services/authService';

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

    expect(screen.getByText('CookToon')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /sign in with google/i })).toBeInTheDocument();
  });

  it('shows profile after successful login', async () => {
    const user = userEvent.setup();
    render(<Profile />);

    await user.click(screen.getByRole('button', { name: /sign in with google/i }));

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

  it('returns to signed-out state after logout', async () => {
    (getCurrentUser as Mock).mockReturnValue(mockUser);
    const user = userEvent.setup();
    render(<Profile />);

    await user.click(screen.getByRole('button', { name: /sign out/i }));

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /sign in with google/i })).toBeInTheDocument();
    });
  });
});
