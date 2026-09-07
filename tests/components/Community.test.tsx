import { describe, it, expect, vi, beforeEach, Mock } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Community } from '../../components/Community';

vi.mock('../../services/geminiService', () => ({
  searchSmartRecipes: vi.fn(),
}));

vi.mock('../../services/liveDataService', () => ({
  fetchCommunityFeed: vi.fn(),
}));

import { searchSmartRecipes } from '../../services/geminiService';
import { fetchCommunityFeed } from '../../services/liveDataService';

describe('Community Component', () => {
  const mockOnCookThis = vi.fn();
  const livePosts = [
    {
      id: 'meal-1',
      title: 'Chicken Alfredo',
      authorId: 'italian-1',
      authorName: 'Italian Kitchen',
      authorAvatar: '🍝',
      imageUrl: 'https://example.com/a.jpg',
      likes: 120,
      comments: 22,
      description: 'Creamy pasta.',
      steps: [],
      tags: ['Dinner', 'Italian'],
      createdAt: Date.now(),
    },
  ];

  beforeEach(() => {
    mockOnCookThis.mockReset();
    (searchSmartRecipes as Mock).mockReset();
    (fetchCommunityFeed as Mock).mockReset();
    (fetchCommunityFeed as Mock).mockResolvedValue(livePosts);
    (searchSmartRecipes as Mock).mockResolvedValue([]);
  });

  it('renders header and search input', async () => {
    render(<Community onCookThis={mockOnCookThis} />);

    expect(screen.getByText('Explore')).toBeInTheDocument();
    expect(screen.getByPlaceholderText(/find recipes, chefs, tags/i)).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText('Chicken Alfredo')).toBeInTheDocument();
    });
  });

  it('calls live smart search on submit', async () => {
    const user = userEvent.setup();
    render(<Community onCookThis={mockOnCookThis} />);

    const input = screen.getByPlaceholderText(/find recipes/i);
    await user.type(input, 'alfredo');
    await user.keyboard('{Enter}');

    await waitFor(() => {
      expect(searchSmartRecipes).toHaveBeenCalledWith('alfredo');
    });
  });

  it('announces the smart-search loading state to assistive technology', async () => {
    let resolveSearch: ((recipes: never[]) => void) | undefined;
    (searchSmartRecipes as Mock).mockReturnValueOnce(new Promise<never[]>((resolve) => {
      resolveSearch = resolve;
    }));
    const user = userEvent.setup();
    render(<Community onCookThis={mockOnCookThis} />);

    await screen.findByText('Chicken Alfredo');
    const input = screen.getByPlaceholderText(/find recipes/i);
    await user.type(input, 'alfredo');
    await user.keyboard('{Enter}');

    await waitFor(() => {
      expect(input.closest('form')).toHaveAttribute('aria-busy', 'true');
      expect(screen.getByText('Searching live recipes.')).toBeInTheDocument();
    });

    resolveSearch?.([]);
    await waitFor(() => {
      expect(input.closest('form')).toHaveAttribute('aria-busy', 'false');
    });
  });

  it('toggles likes on a post', async () => {
    const user = userEvent.setup();
    render(<Community onCookThis={mockOnCookThis} />);

    const likeCountButton = await screen.findByRole('button', { name: 'Like count' });
    expect(likeCountButton).toContainHTML('120');

    await user.click(likeCountButton);
    expect(likeCountButton).toContainHTML('121');
  });

  it('triggers Cook This with selected post', async () => {
    const user = userEvent.setup();
    render(<Community onCookThis={mockOnCookThis} />);

    const cookButton = await screen.findByRole('button', { name: /cook this/i });
    await user.click(cookButton);

    expect(mockOnCookThis).toHaveBeenCalledWith(
      expect.objectContaining({ id: 'meal-1', title: 'Chicken Alfredo' }),
    );
  });
});
