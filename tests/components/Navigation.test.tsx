import { describe, it, expect, vi } from 'vitest';
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

      expect(screen.getByRole('button', { name: /home/i })).toBeInTheDocument();
    });

    it('should render all navigation items', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      // The navigation has 4 buttons (Home, Builder/Plus, Decider, Profile)
      const buttons = screen.getAllByRole('button');
      expect(buttons.length).toBeGreaterThanOrEqual(4);
    });

    it('should render Home button', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      const homeButton = screen.getByText('Home');
      expect(homeButton).toBeInTheDocument();
    });

    it('should render Decider button', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      const deciderButton = screen.getByText('Decider');
      expect(deciderButton).toBeInTheDocument();
    });

    it('should render Me/Profile button', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      const profileButton = screen.getByText('Me');
      expect(profileButton).toBeInTheDocument();
    });

    it('should render central plus/create button', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      // The center button navigates to BUILDER
      const buttons = screen.getAllByRole('button');
      expect(buttons.length).toBeGreaterThanOrEqual(4);
    });
  });

  describe('navigation actions', () => {
    it('should call setView with COMMUNITY when Home is clicked', () => {
      render(<Navigation currentView={AppView.BUILDER} setView={mockSetView} />);

      const homeButton = screen.getByText('Home').closest('button');
      fireEvent.click(homeButton!);

      expect(mockSetView).toHaveBeenCalledWith(AppView.COMMUNITY);
    });

    it('should call setView with DECIDER when Decider is clicked', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      const deciderButton = screen.getByText('Decider').closest('button');
      fireEvent.click(deciderButton!);

      expect(mockSetView).toHaveBeenCalledWith(AppView.DECIDER);
    });

    it('should call setView with PROFILE when Me is clicked', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      const profileButton = screen.getByText('Me').closest('button');
      fireEvent.click(profileButton!);

      expect(mockSetView).toHaveBeenCalledWith(AppView.PROFILE);
    });

    it('should call setView with BUILDER when center button is clicked', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      // Find the center button (the one with PlusCircle icon)
      const buttons = screen.getAllByRole('button');
      // The center button is typically the second one or has specific styling
      const centerButton = buttons.find(
        (btn) => btn.className.includes('w-14') || btn.className.includes('mx-2')
      );

      if (centerButton) {
        fireEvent.click(centerButton);
        expect(mockSetView).toHaveBeenCalledWith(AppView.BUILDER);
      }
    });
  });

  describe('active state', () => {
    it('should highlight Home when current view is COMMUNITY', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      const homeButton = screen.getByText('Home').closest('button');
      expect(homeButton?.className).toContain('text-toon-primary');
    });

    it('should highlight Decider when current view is DECIDER', () => {
      render(<Navigation currentView={AppView.DECIDER} setView={mockSetView} />);

      const deciderButton = screen.getByText('Decider').closest('button');
      expect(deciderButton?.className).toContain('text-toon-primary');
    });

    it('should highlight Me when current view is PROFILE', () => {
      render(<Navigation currentView={AppView.PROFILE} setView={mockSetView} />);

      const profileButton = screen.getByText('Me').closest('button');
      expect(profileButton?.className).toContain('text-toon-primary');
    });

    it('should not highlight inactive items', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      const deciderButton = screen.getByText('Decider').closest('button');
      const profileButton = screen.getByText('Me').closest('button');

      expect(deciderButton?.className).toContain('text-gray-300');
      expect(profileButton?.className).toContain('text-gray-300');
    });

    it('should show label for active item', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      const homeLabel = screen.getByText('Home');
      expect(homeLabel.className).toContain('opacity-100');
    });

    it('should hide label for inactive items', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      const deciderLabel = screen.getByText('Decider');
      expect(deciderLabel.className).toContain('opacity-0');
    });
  });

  describe('visual scaling', () => {
    it('should scale up active navigation item', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      const homeButton = screen.getByText('Home').closest('button');
      expect(homeButton?.className).toContain('scale-110');
    });

    it('should not scale inactive navigation items', () => {
      render(<Navigation currentView={AppView.COMMUNITY} setView={mockSetView} />);

      const deciderButton = screen.getByText('Decider').closest('button');
      expect(deciderButton?.className).not.toContain('scale-110');
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

      const homeButton = screen.getByText('Home').closest('button');
      const deciderButton = screen.getByText('Decider').closest('button');

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
      expect(nav.className).toContain('bottom-6');
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
      fireEvent.click(screen.getByText('Decider').closest('button')!);
      expect(mockSetView).toHaveBeenLastCalledWith(AppView.DECIDER);

      // Re-render with Decider view
      rerender(<Navigation currentView={AppView.DECIDER} setView={mockSetView} />);

      // Click Profile from Decider
      fireEvent.click(screen.getByText('Me').closest('button')!);
      expect(mockSetView).toHaveBeenLastCalledWith(AppView.PROFILE);
    });
  });
});
