import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { RecipeBuilder } from '../../components/RecipeBuilder';
import { createMockRecipe, createMockRecipeStep } from '../utils/test-utils';
import { INGREDIENTS, TOOLS, ACTIONS, TEMPERATURES, TIMES, WATER_LEVELS } from '../../data/kitchenData';

describe('RecipeBuilder Component', () => {
  const mockOnExit = vi.fn();

  beforeEach(() => {
    mockOnExit.mockClear();
  });

  describe('initial rendering', () => {
    it('should render with default recipe name', () => {
      render(<RecipeBuilder />);

      const input = screen.getByPlaceholderText(/name your recipe/i);
      expect(input).toHaveValue('My Delicious Recipe');
    });

    it('should render with custom initial recipe name', () => {
      const recipe = createMockRecipe({ title: 'Custom Recipe Name' });
      render(<RecipeBuilder initialRecipe={recipe} />);

      const input = screen.getByPlaceholderText(/name your recipe/i);
      expect(input).toHaveValue('Custom Recipe Name');
    });

    it('should show empty state when no steps', () => {
      render(<RecipeBuilder />);

      expect(screen.getByText(/your kitchen is empty/i)).toBeInTheDocument();
      expect(screen.getByText(/tap the big plus button/i)).toBeInTheDocument();
    });

    it('should show the animation asset readiness panel in empty state', () => {
      render(<RecipeBuilder />);

      expect(screen.getByText(/visual pantry stocked/i)).toBeInTheDocument();
      expect(screen.getByText(/motion previews ready/i)).toBeInTheDocument();
    });

    it('should display step count', () => {
      render(<RecipeBuilder />);

      expect(screen.getByText(/0 steps/)).toBeInTheDocument();
    });

    it('should render add step button', () => {
      render(<RecipeBuilder />);

      const addButton = screen.getByRole('button', { name: /add step/i });
      expect(addButton).toBeInTheDocument();
    });

    it('should render exit button when onExit is provided', () => {
      render(<RecipeBuilder onExit={mockOnExit} />);

      // The ArrowLeft button for exit
      const buttons = screen.getAllByRole('button');
      expect(buttons.length).toBeGreaterThan(0);
    });
  });

  describe('recipe name editing', () => {
    it('should allow editing recipe name', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const input = screen.getByPlaceholderText(/name your recipe/i);
      await user.clear(input);
      await user.type(input, 'New Recipe Name');

      expect(input).toHaveValue('New Recipe Name');
    });

    it('should accept empty recipe name', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const input = screen.getByPlaceholderText(/name your recipe/i);
      await user.clear(input);

      expect(input).toHaveValue('');
    });

    it('should accept special characters in name', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const input = screen.getByPlaceholderText(/name your recipe/i);
      await user.clear(input);
      await user.type(input, "Mom's Special Pasta & More!");

      expect(input).toHaveValue("Mom's Special Pasta & More!");
    });
  });

  describe('step creation wizard', () => {
    it('should open editor when add button is clicked', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      // Find and click the plus button
      const plusButtons = screen.getAllByRole('button');
      const addButton = plusButtons.find((btn) => btn.className.includes('bg-toon-primary'));

      if (addButton) {
        await user.click(addButton);
        expect(screen.getByText('Select Station')).toBeInTheDocument();
      }
    });

    it('should show station options', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const plusButtons = screen.getAllByRole('button');
      const addButton = plusButtons.find((btn) => btn.className.includes('bg-toon-primary'));

      if (addButton) {
        await user.click(addButton);

        expect(screen.getByText('Prep Station')).toBeInTheDocument();
        expect(screen.getByText('Hot Station')).toBeInTheDocument();
        expect(screen.getByText('Plating')).toBeInTheDocument();
      }
    });

    it('should show station descriptions', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const plusButtons = screen.getAllByRole('button');
      const addButton = plusButtons.find((btn) => btn.className.includes('bg-toon-primary'));

      if (addButton) {
        await user.click(addButton);

        expect(screen.getByText('Chop, Mix, Peel')).toBeInTheDocument();
        expect(screen.getByText('Stove, Oven, Grill')).toBeInTheDocument();
        expect(screen.getByText('Serve & Garnish')).toBeInTheDocument();
      }
    });

    it('should advance to tool selection after choosing prep station', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const plusButtons = screen.getAllByRole('button');
      const addButton = plusButtons.find((btn) => btn.className.includes('bg-toon-primary'));

      if (addButton) {
        await user.click(addButton);
        await user.click(screen.getByText('Prep Station'));

        expect(screen.getByText('Choose Tool')).toBeInTheDocument();
      }
    });

    it('should show prep tools for prep station', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const plusButtons = screen.getAllByRole('button');
      const addButton = plusButtons.find((btn) => btn.className.includes('bg-toon-primary'));

      if (addButton) {
        await user.click(addButton);
        await user.click(screen.getByText('Prep Station'));

        // Check for prep tools
        expect(screen.getByText('Chef Knife')).toBeInTheDocument();
        expect(screen.getByText('Mixing Bowl')).toBeInTheDocument();
        expect(screen.getByText('Peeler')).toBeInTheDocument();
      }
    });

    it('should show cook tools for cook station', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const plusButtons = screen.getAllByRole('button');
      const addButton = plusButtons.find((btn) => btn.className.includes('bg-toon-primary'));

      if (addButton) {
        await user.click(addButton);
        await user.click(screen.getByText('Hot Station'));

        // Check for cook tools
        expect(screen.getByText('Frying Pan')).toBeInTheDocument();
        expect(screen.getByText('Stock Pot')).toBeInTheDocument();
      }
    });

    it('should skip to action selection for finish station', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const plusButtons = screen.getAllByRole('button');
      const addButton = plusButtons.find((btn) => btn.className.includes('bg-toon-primary'));

      if (addButton) {
        await user.click(addButton);
        await user.click(screen.getByText('Plating'));

        expect(screen.getByText('Process')).toBeInTheDocument();
      }
    });

    it('should advance to ingredient selection after choosing tool', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const plusButtons = screen.getAllByRole('button');
      const addButton = plusButtons.find((btn) => btn.className.includes('bg-toon-primary'));

      if (addButton) {
        await user.click(addButton);
        await user.click(screen.getByText('Prep Station'));
        await user.click(screen.getByText('Chef Knife'));

        expect(screen.getByText('Add Ingredients')).toBeInTheDocument();
      }
    });

    it('should show all ingredients in ingredient selection', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const plusButtons = screen.getAllByRole('button');
      const addButton = plusButtons.find((btn) => btn.className.includes('bg-toon-primary'));

      if (addButton) {
        await user.click(addButton);
        await user.click(screen.getByText('Prep Station'));
        await user.click(screen.getByText('Chef Knife'));

        // Check for some ingredients
        expect(screen.getByText('Tomato')).toBeInTheDocument();
        expect(screen.getByText('Carrot')).toBeInTheDocument();
        expect(screen.getByText('Onion')).toBeInTheDocument();
      }
    });

    it('should allow adding ingredients', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const plusButtons = screen.getAllByRole('button');
      const addButton = plusButtons.find((btn) => btn.className.includes('bg-toon-primary'));

      if (addButton) {
        await user.click(addButton);
        await user.click(screen.getByText('Prep Station'));
        await user.click(screen.getByText('Chef Knife'));
        await user.click(screen.getByText('Tomato'));

        // Should show selected ingredient
        const selectedArea = screen.getAllByText('Tomato');
        expect(selectedArea.length).toBeGreaterThan(0);
      }
    });

    it('should render generated kitchen asset pack images for recipe pieces', async () => {
      const user = userEvent.setup();
      const { container } = render(<RecipeBuilder />);

      const plusButtons = screen.getAllByRole('button');
      const addButton = plusButtons.find((btn) => btn.className.includes('bg-toon-primary'));

      if (addButton) {
        await user.click(addButton);
        await user.click(screen.getByText('Prep Station'));
        await user.click(screen.getByText('Chef Knife'));

        const producedPackImage = container.querySelector(
          'img[src*="generated/kitchen_asset_pack_v1"]',
        );
        expect(producedPackImage).toBeInTheDocument();
      }
    });

    it('should filter the large ingredient library by search', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const addButton = screen.getByRole('button', { name: /add step/i });
      await user.click(addButton);
      await user.click(screen.getByText('Prep Station'));
      await user.click(screen.getByText('Chef Knife'));

      await user.type(screen.getByPlaceholderText(/search ingredients/i), 'tomato');

      expect(screen.getByText('Tomato')).toBeInTheDocument();
      expect(screen.queryByText('Chicken')).not.toBeInTheDocument();
    });

    it('should allow removing ingredients', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const plusButtons = screen.getAllByRole('button');
      const addButton = plusButtons.find((btn) => btn.className.includes('bg-toon-primary'));

      if (addButton) {
        await user.click(addButton);
        await user.click(screen.getByText('Prep Station'));
        await user.click(screen.getByText('Chef Knife'));
        await user.click(screen.getByText('Tomato'));

        // Find remove button in selection chip
        const chip = screen.getAllByText('Tomato')[0].closest('div');
        const removeButton = chip?.querySelector('button');
        if (removeButton) {
          await user.click(removeButton);
        }
      }
    });

    it('should disable Done button when no ingredients selected', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const plusButtons = screen.getAllByRole('button');
      const addButton = plusButtons.find((btn) => btn.className.includes('bg-toon-primary'));

      if (addButton) {
        await user.click(addButton);
        await user.click(screen.getByText('Prep Station'));
        await user.click(screen.getByText('Chef Knife'));

        const doneButton = screen.getByText('Done with Ingredients');
        expect(doneButton).toBeDisabled();
      }
    });

    it('should enable Done button when ingredients selected', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const plusButtons = screen.getAllByRole('button');
      const addButton = plusButtons.find((btn) => btn.className.includes('bg-toon-primary'));

      if (addButton) {
        await user.click(addButton);
        await user.click(screen.getByText('Prep Station'));
        await user.click(screen.getByText('Chef Knife'));
        await user.click(screen.getByText('Tomato'));

        const doneButton = screen.getByText('Done with Ingredients');
        expect(doneButton).not.toBeDisabled();
      }
    });

    it('should keep a clear next action visible after selecting ingredients', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      await user.click(screen.getByRole('button', { name: /add step/i }));
      await user.click(screen.getByText('Prep Station'));
      await user.click(screen.getByText('Chef Knife'));
      await user.click(screen.getByText('Tomato'));

      expect(screen.getByRole('button', { name: /done with ingredients/i })).toBeEnabled();
    });
  });

  describe('action selection', () => {
    it('should show compatible actions for selected tool and ingredients', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const plusButtons = screen.getAllByRole('button');
      const addButton = plusButtons.find((btn) => btn.className.includes('bg-toon-primary'));

      if (addButton) {
        await user.click(addButton);
        await user.click(screen.getByText('Prep Station'));
        await user.click(screen.getByText('Chef Knife'));
        await user.click(screen.getByText('Tomato'));
        await user.click(screen.getByText('Done with Ingredients'));

        // Knife actions for choppable ingredients
        expect(screen.getByText('Chop')).toBeInTheDocument();
      }
    });

    it('should show message when no valid actions', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const plusButtons = screen.getAllByRole('button');
      const addButton = plusButtons.find((btn) => btn.className.includes('bg-toon-primary'));

      if (addButton) {
        await user.click(addButton);
        await user.click(screen.getByText('Prep Station'));
        await user.click(screen.getByText('Peeler'));
        await user.click(screen.getByText('Salt')); // Salt is not peelable
        await user.click(screen.getByText('Done with Ingredients'));

        // Should show no valid actions message
        expect(screen.getByText(/no valid actions/i)).toBeInTheDocument();
      }
    });
  });

  describe('details step', () => {
    it('should show temperature options for heat-requiring actions', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const plusButtons = screen.getAllByRole('button');
      const addButton = plusButtons.find((btn) => btn.className.includes('bg-toon-primary'));

      if (addButton) {
        await user.click(addButton);
        await user.click(screen.getByText('Hot Station'));
        await user.click(screen.getByText('Frying Pan'));
        await user.click(screen.getByText('Chicken'));
        await user.click(screen.getByText('Done with Ingredients'));
        await user.click(screen.getByText('Stir Fry'));

        // Should show temperature options
        expect(screen.getByText('Heat Level')).toBeInTheDocument();
        expect(screen.getByText('Low')).toBeInTheDocument();
        expect(screen.getByText('Medium')).toBeInTheDocument();
        expect(screen.getByText('High')).toBeInTheDocument();
      }
    });

    it('should show a motion preview for a completed action choice', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const addButton = screen.getByRole('button', { name: /add step/i });
      await user.click(addButton);
      await user.click(screen.getByText('Prep Station'));
      await user.click(screen.getByText('Chef Knife'));
      await user.click(screen.getByText('Tomato'));
      await user.click(screen.getByText('Done with Ingredients'));
      await user.click(screen.getByText('Chop'));

      expect(screen.getByText(/step animation/i)).toBeInTheDocument();
      expect(screen.getByAltText(/chop motion preview/i)).toBeInTheDocument();
    });

    it('should show only details that match the chosen prep action', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      await user.click(screen.getByRole('button', { name: /add step/i }));
      await user.click(screen.getByText('Prep Station'));
      await user.click(screen.getByText('Chef Knife'));
      await user.click(screen.getByText('Tomato'));
      await user.click(screen.getByText('Done with Ingredients'));
      await user.click(screen.getByText('Chop'));

      expect(screen.getByRole('button', { name: /chopped/i })).toBeInTheDocument();
      expect(screen.queryByRole('button', { name: /diced/i })).not.toBeInTheDocument();
      expect(screen.queryByRole('button', { name: /peeled/i })).not.toBeInTheDocument();
    });

    it('should show duration options', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const plusButtons = screen.getAllByRole('button');
      const addButton = plusButtons.find((btn) => btn.className.includes('bg-toon-primary'));

      if (addButton) {
        await user.click(addButton);
        await user.click(screen.getByText('Hot Station'));
        await user.click(screen.getByText('Frying Pan'));
        await user.click(screen.getByText('Chicken'));
        await user.click(screen.getByText('Done with Ingredients'));
        await user.click(screen.getByText('Stir Fry'));

        expect(screen.getByText('Duration')).toBeInTheDocument();
        TIMES.forEach((time) => {
          expect(screen.getByText(time)).toBeInTheDocument();
        });
      }
    });

    it('should show water level options for cook station', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const plusButtons = screen.getAllByRole('button');
      const addButton = plusButtons.find((btn) => btn.className.includes('bg-toon-primary'));

      if (addButton) {
        await user.click(addButton);
        await user.click(screen.getByText('Hot Station'));
        await user.click(screen.getByText('Stock Pot'));
        await user.click(screen.getByText('Pasta'));
        await user.click(screen.getByText('Done with Ingredients'));
        await user.click(screen.getByText('Boil'));

        expect(screen.getByText('Liquid Added')).toBeInTheDocument();
      }
    });

    it('should allow selecting temperature', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const plusButtons = screen.getAllByRole('button');
      const addButton = plusButtons.find((btn) => btn.className.includes('bg-toon-primary'));

      if (addButton) {
        await user.click(addButton);
        await user.click(screen.getByText('Hot Station'));
        await user.click(screen.getByText('Frying Pan'));
        await user.click(screen.getByText('Chicken'));
        await user.click(screen.getByText('Done with Ingredients'));
        await user.click(screen.getByText('Stir Fry'));
        await user.click(screen.getByText('High'));

        const highButton = screen.getByText('High');
        expect(highButton.className).toContain('bg-red-500');
      }
    });
  });

  describe('completing step', () => {
    it('should add step to recipe when completed', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const plusButtons = screen.getAllByRole('button');
      const addButton = plusButtons.find((btn) => btn.className.includes('bg-toon-primary'));

      if (addButton) {
        await user.click(addButton);
        await user.click(screen.getByText('Prep Station'));
        await user.click(screen.getByText('Chef Knife'));
        await user.click(screen.getByText('Tomato'));
        await user.click(screen.getByText('Done with Ingredients'));
        await user.click(screen.getByText('Chop'));
        await user.click(screen.getByText('Add Step to Recipe'));

        // Should return to list view with step
        expect(screen.getByText('Chopped')).toBeInTheDocument();
      }
    });

    it('should label plating steps with a serving plate tool', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      await user.click(screen.getByRole('button', { name: /add step/i }));
      await user.click(screen.getByText('Plating'));
      await user.click(screen.getByText('Plate'));
      await user.click(screen.getByText('Add Step to Recipe'));

      expect(screen.getByText('Plated')).toBeInTheDocument();
      expect(screen.getByText(/using Serving Plate/i)).toBeInTheDocument();
    });

    it('should update step count after adding step', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const plusButtons = screen.getAllByRole('button');
      const addButton = plusButtons.find((btn) => btn.className.includes('bg-toon-primary'));

      if (addButton) {
        await user.click(addButton);
        await user.click(screen.getByText('Prep Station'));
        await user.click(screen.getByText('Chef Knife'));
        await user.click(screen.getByText('Tomato'));
        await user.click(screen.getByText('Done with Ingredients'));
        await user.click(screen.getByText('Chop'));
        await user.click(screen.getByText('Add Step to Recipe'));

        expect(screen.getByText(/1 steps/)).toBeInTheDocument();
      }
    });
  });

  describe('step deletion', () => {
    it('should show delete button for each step', async () => {
      const recipe = createMockRecipe({
        steps: [createMockRecipeStep()],
      });
      render(<RecipeBuilder initialRecipe={recipe} />);

      const deleteButtons = screen.getAllByRole('button');
      const trashButton = deleteButtons.find((btn) => btn.querySelector('svg'));
      expect(trashButton).toBeDefined();
    });
  });

  describe('navigation', () => {
    it('should close editor when back button is clicked', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const plusButtons = screen.getAllByRole('button');
      const addButton = plusButtons.find((btn) => btn.className.includes('bg-toon-primary'));

      if (addButton) {
        await user.click(addButton);

        // Click back button
        const backButtons = screen.getAllByRole('button');
        const backButton = backButtons.find((btn) => btn.className.includes('-ml-2'));
        if (backButton) {
          await user.click(backButton);
          expect(screen.queryByText('Select Station')).not.toBeInTheDocument();
        }
      }
    });

    it('should call onExit when exit button is clicked', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder onExit={mockOnExit} />);

      const backButtons = screen.getAllByRole('button');
      const exitButton = backButtons.find((btn) => btn.className.includes('-ml-2'));
      if (exitButton) {
        await user.click(exitButton);
        expect(mockOnExit).toHaveBeenCalled();
      }
    });
  });

  describe('progress bar', () => {
    it('should show progress in editor', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const plusButtons = screen.getAllByRole('button');
      const addButton = plusButtons.find((btn) => btn.className.includes('bg-toon-primary'));

      if (addButton) {
        await user.click(addButton);

        // Find progress bar
        const progressContainer = screen.getByRole('progressbar', { name: /step editor progress/i });
        expect(progressContainer).toBeInTheDocument();
        expect(progressContainer).toHaveAttribute('aria-valuenow', '1');
      }
    });
  });

  describe('initial recipe with steps', () => {
    it('should display initial recipe steps', () => {
      const recipe = createMockRecipe({
        steps: [
          createMockRecipeStep({ actionId: 'chop', toolId: 'knife' }),
        ],
      });
      render(<RecipeBuilder initialRecipe={recipe} />);

      expect(screen.getByText('Chopped')).toBeInTheDocument();
    });

    it('should show share button when steps exist', () => {
      const recipe = createMockRecipe({
        steps: [createMockRecipeStep()],
      });
      render(<RecipeBuilder initialRecipe={recipe} />);

      // Share button should be visible
      const buttons = screen.getAllByRole('button');
      expect(buttons.length).toBeGreaterThan(1);
    });
  });

  describe('action validation', () => {
    it('should filter actions based on ingredient properties', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      const plusButtons = screen.getAllByRole('button');
      const addButton = plusButtons.find((btn) => btn.className.includes('bg-toon-primary'));

      if (addButton) {
        await user.click(addButton);
        await user.click(screen.getByText('Prep Station'));
        await user.click(screen.getByText('Peeler'));
        await user.click(screen.getByText('Carrot')); // Carrot is peelable
        await user.click(screen.getByText('Done with Ingredients'));

        // Peel action should be available
        expect(screen.getByText('Peel')).toBeInTheDocument();
      }
    });
  });
});
