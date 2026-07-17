import { beforeEach, describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { Navigation } from '../../components/Navigation';
import { AppView } from '../../types';

describe('Navigation Component', () => {
  const mockSetView = vi.fn();

  beforeEach(() => {
    mockSetView.mockClear();
  });

  describe('rendering', () => {
    it('should render navigation bar', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      expect(screen.getByRole('button', { name: /explore/i })).toBeInTheDocument();
    });

    it('should render all navigation items', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      // The navigation has 4 consistent buttons (Explore, Build, Decide, Profile)
      const buttons = screen.getAllByRole('button');
      expect(buttons.length).toBeGreaterThanOrEqual(4);
    });

    it('should render Explore button', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      const homeButton = screen.getByText('Explore');
      expect(homeButton).toBeInTheDocument();
    });

    it('should render Decide button', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      const deciderButton = screen.getByText('Decide');
      expect(deciderButton).toBeInTheDocument();
    });

    it('should render Profile button', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      const profileButton = screen.getByText('Profile');
      expect(profileButton).toBeInTheDocument();
    });

    it('should render Build button', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      expect(screen.getByRole('button', { name: 'Build' })).toBeInTheDocument();
    });
  });

  describe('navigation actions', () => {
    it('should call setView with COMMUNITY when Explore is clicked', () => {
      render(<Navigation currentView={AppView.BUILDER} setView={mockSetView} />);

      const homeButton = screen.getByText('Explore').closest('button');
      fireEvent.click(homeButton!);

      expect(mockSetView).toHaveBeenCalledWith(AppView.COMMUNITY);
    });

    it('should call setView with DECIDER when Decider is clicked', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      const deciderButton = screen.getByText('Decide').closest('button');
      fireEvent.click(deciderButton!);

      expect(mockSetView).toHaveBeenCalledWith(AppView.DECIDER);
    });

    it('should call setView with PROFILE when Profile is clicked', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      const profileButton = screen.getByText('Profile').closest('button');
      fireEvent.click(profileButton!);

      expect(mockSetView).toHaveBeenCalledWith(AppView.PROFILE);
    });

    it('should call setView with BUILDER when Build is clicked', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      fireEvent.click(screen.getByRole('button', { name: 'Build' }));
      expect(mockSetView).toHaveBeenCalledWith(AppView.BUILDER);
    });
  });

  describe('active state', () => {
    it('should highlight Home when current view is COMMUNITY', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      const homeButton = screen.getByText('Explore').closest('button');
      expect(homeButton?.className).toContain('bg-toon-dark');
    });

    it('should highlight Decider when current view is DECIDER', () => {
      render(<Navigation currentView={AppView.DECIDER} setView={mockSetView} />);

      const deciderButton = screen.getByText('Decide').closest('button');
      expect(deciderButton?.className).toContain('bg-toon-dark');
    });

    it('should highlight Me when current view is PROFILE', () => {
      render(<Navigation currentView={AppView.PROFILE} setView={mockSetView} />);

      const profileButton = screen.getByText('Profile').closest('button');
      expect(profileButton?.className).toContain('bg-toon-dark');
    });

    it('should not highlight inactive items', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      const deciderButton = screen.getByText('Decide').closest('button');
      const profileButton = screen.getByText('Profile').closest('button');

      expect(deciderButton?.className).toContain('text-gray-400');
      expect(profileButton?.className).toContain('text-gray-400');
    });

    it('should show all labels consistently', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      expect(screen.getByText('Explore')).toBeVisible();
      expect(screen.getByText('Build')).toBeVisible();
      expect(screen.getByText('Decide')).toBeVisible();
      expect(screen.getByText('Profile')).toBeVisible();
    });
  });

  describe('visual scaling', () => {
    it('should use the same dimensions for every item', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      screen.getAllByRole('button').forEach((button) => {
        expect(button.className).toContain('h-16');
        expect(button.className).toContain('flex-1');
      });
    });
  });

  describe('accessibility', () => {
    it('should have clickable buttons', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      const buttons = screen.getAllByRole('button');
      buttons.forEach((button) => {
        expect(button).not.toBeDisabled();
      });
    });

    it('should respond to multiple clicks', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      const homeButton = screen.getByText('Explore').closest('button');
      const deciderButton = screen.getByText('Decide').closest('button');

      fireEvent.click(homeButton!);
      fireEvent.click(deciderButton!);
      fireEvent.click(homeButton!);

      expect(mockSetView).toHaveBeenCalledTimes(3);
    });
  });

  describe('layout', () => {
    it('should be fixed position at bottom', () => {
      const { container } = render(
        <Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />
      );

      const nav = container.firstChild as HTMLElement;
      expect(nav.className).toContain('fixed');
      expect(nav.className).toContain('bottom-4');
    });

    it('should be centered horizontally', () => {
      const { container } = render(
        <Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />
      );

      const nav = container.firstChild as HTMLElement;
      expect(nav.className).toContain('left-1/2');
      expect(nav.className).toContain('-translate-x-1/2');
    });

    it('should have z-index for overlay', () => {
      const { container } = render(
        <Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />
      );

      const nav = container.firstChild as HTMLElement;
      expect(nav.className).toContain('z-50');
    });
  });

  describe('all views navigation', () => {
    const views = [AppView.COMMUNITY, AppView.BUILDER, AppView.DECIDER, AppView.PROFILE];

    views.forEach((view) => {
      it(`should render correctly with ${view} as current view`, () => {
        expect(() => {
          render(<Navigation currentView={view} setView={mockSetView} />);
        }).not.toThrow();
      });
    });

    it('should allow navigation from any view to any other view', () => {
      const { rerender } = render(
        <Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />
      );

      // Click Decider from Community
      fireEvent.click(screen.getByText('Decide').closest('button')!);
      expect(mockSetView).toHaveBeenLastCalledWith(AppView.DECIDER);

      // Re-render with Decider view
      rerender(<Navigation currentView={AppView.DECIDER} setView={mockSetView} />);

      // Click Profile from Decider
      fireEvent.click(screen.getByText('Profile').closest('button')!);
      expect(mockSetView).toHaveBeenLastCalledWith(AppView.PROFILE);
    });
  });
});
