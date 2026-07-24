import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { RecipeBuilder } from '../../components/RecipeBuilder';
import { createMockRecipe, createMockRecipeStep } from '../utils/test-utils';
import { TIMES } from '../../data/kitchenData';

// Walks the wizard to the ingredients stage.
const openEditor = async (user: ReturnType<typeof userEvent.setup>) => {
  await user.click(screen.getByRole('button', { name: /add step/i }));
};

// Picks one ingredient and moves to the action stage.
const pickIngredientAndAdvance = async (
  user: ReturnType<typeof userEvent.setup>,
  ingredientName: string,
) => {
  await user.click(screen.getByRole('button', { name: ingredientName }));
  await user.click(screen.getByRole('button', { name: /cook with/i }));
};

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

    it('should not expose asset or coverage internals to the user', () => {
      render(<RecipeBuilder />);

      expect(screen.queryByText(/visual pantry/i)).not.toBeInTheDocument();
      expect(screen.queryByText(/art loaded/i)).not.toBeInTheDocument();
      expect(screen.queryByText(/generic representation/i)).not.toBeInTheDocument();
    });

    it('should display step count', () => {
      render(<RecipeBuilder />);

      expect(screen.getByText(/0 steps/)).toBeInTheDocument();
    });

    it('should render add step button', () => {
      render(<RecipeBuilder />);

      expect(screen.getByRole('button', { name: /add step/i })).toBeInTheDocument();
    });

    it('should render exit button when onExit is provided', () => {
      render(<RecipeBuilder onExit={mockOnExit} />);

      expect(screen.getByRole('button', { name: /back to explore/i })).toBeInTheDocument();
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
    it('should open on the ingredient stage', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      await openEditor(user);

      expect(screen.getByText("What's cooking?")).toBeInTheDocument();
      expect(await screen.findByRole('button', { name: 'Tomato' })).toBeInTheDocument();
      expect(await screen.findByRole('button', { name: 'Carrot' })).toBeInTheDocument();
      expect(await screen.findByRole('button', { name: 'Onion' })).toBeInTheDocument();
    });

    it('should allow adding ingredients', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      await openEditor(user);
      await user.click(screen.getByRole('button', { name: 'Tomato' }));

      expect(screen.getAllByText('Tomato').length).toBeGreaterThan(1);
    });

    it('should render kitchen asset pack art in the ingredient grid', async () => {
      const user = userEvent.setup();
      const { container } = render(<RecipeBuilder />);

      await openEditor(user);

      const packImage = container.querySelector('img[src*="generated/kitchen_asset_pack"]');
      expect(packImage).toBeInTheDocument();
    });

    it('should filter the large ingredient library by search', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      await openEditor(user);
      await user.type(screen.getByPlaceholderText(/search ingredients/i), 'tomato');

      expect(screen.getByRole('button', { name: 'Tomato' })).toBeInTheDocument();
      expect(screen.queryByRole('button', { name: 'Chicken' })).not.toBeInTheDocument();
    });

    it('should allow removing ingredients', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      await openEditor(user);
      await user.click(screen.getByRole('button', { name: 'Tomato' }));
      await user.click(screen.getByRole('button', { name: /remove tomato/i }));

      expect(screen.queryByRole('button', { name: /remove tomato/i })).not.toBeInTheDocument();
    });

    it('should disable the continue button when no ingredients selected', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      await openEditor(user);

      expect(screen.getByRole('button', { name: /pick your ingredients/i })).toBeDisabled();
    });

    it('should enable the continue button when ingredients selected', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      await openEditor(user);
      await user.click(screen.getByRole('button', { name: 'Tomato' }));

      expect(screen.getByRole('button', { name: /cook with/i })).toBeEnabled();
    });
  });

  describe('action selection', () => {
    it('should combine the technique and its tool in one card', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      await openEditor(user);
      await pickIngredientAndAdvance(user, 'Tomato');

      expect(screen.getByText('How do you cook it?')).toBeInTheDocument();
      expect(screen.getByText('Chop')).toBeInTheDocument();
      expect(screen.getAllByText(/with Chef Knife/i).length).toBeGreaterThan(0);
    });

    it('should hide actions the chosen ingredients cannot do', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      await openEditor(user);
      await pickIngredientAndAdvance(user, 'Chicken');

      // Chicken is not peelable, so Peel never shows up.
      expect(screen.queryByText('Peel')).not.toBeInTheDocument();
    });

    it('should show peel for peelable ingredients', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      await openEditor(user);
      await pickIngredientAndAdvance(user, 'Carrot');

      expect(screen.getByText('Peel')).toBeInTheDocument();
    });

    it('should filter actions by cooking style', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      await openEditor(user);
      await pickIngredientAndAdvance(user, 'Tomato');

      await user.click(screen.getByRole('tab', { name: /heat/i }));

      expect(screen.queryByText('Chop')).not.toBeInTheDocument();
    });
  });

  describe('details step', () => {
    it('should show temperature options for heat-requiring actions', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      await openEditor(user);
      await pickIngredientAndAdvance(user, 'Chicken');
      await user.click(screen.getByText('Stir Fry'));

      expect(screen.getByText('Heat Level')).toBeInTheDocument();
      expect(screen.getByText('Low')).toBeInTheDocument();
      expect(screen.getByText('Medium')).toBeInTheDocument();
      expect(screen.getByText('High')).toBeInTheDocument();
    });

    it('should show an animation for the chosen action', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      await openEditor(user);
      await pickIngredientAndAdvance(user, 'Tomato');
      await user.click(screen.getByText('Chop'));

      expect(screen.getByRole('img', { name: /chop animation/i })).toBeInTheDocument();
    });

    it('should show only details that match the chosen prep action', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      await openEditor(user);
      await pickIngredientAndAdvance(user, 'Tomato');
      await user.click(screen.getByText('Chop'));

      expect(screen.getByRole('button', { name: /chopped/i })).toBeInTheDocument();
      expect(screen.queryByRole('button', { name: /diced/i })).not.toBeInTheDocument();
      expect(screen.queryByRole('button', { name: /peeled/i })).not.toBeInTheDocument();
    });

    it('should show duration options', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      await openEditor(user);
      await pickIngredientAndAdvance(user, 'Chicken');
      await user.click(screen.getByText('Stir Fry'));

      expect(screen.getByText('Duration')).toBeInTheDocument();
      TIMES.forEach((time) => {
        expect(screen.getByText(time)).toBeInTheDocument();
      });
    });

    it('should show water level options for boiling', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      await openEditor(user);
      await pickIngredientAndAdvance(user, 'Pasta');
      await user.click(screen.getByText('Boil'));

      expect(screen.getByText('Liquid Added')).toBeInTheDocument();
    });

    it('should allow selecting temperature', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      await openEditor(user);
      await pickIngredientAndAdvance(user, 'Chicken');
      await user.click(screen.getByText('Stir Fry'));
      await user.click(screen.getByText('High'));

      expect(screen.getByText('High').className).toContain('bg-red-500');
    });
  });

  describe('completing step', () => {
    it('should add step to recipe when completed', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      await openEditor(user);
      await pickIngredientAndAdvance(user, 'Tomato');
      await user.click(screen.getByText('Chop'));
      await user.click(screen.getByText('Add Step to Recipe'));

      expect(screen.getByText('Chopped')).toBeInTheDocument();
    });

    it('should label plating steps with a serving plate tool', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      await openEditor(user);
      await pickIngredientAndAdvance(user, 'Parsley');
      await user.click(screen.getByRole('tab', { name: /plate/i }));
      await user.click(screen.getByRole('button', { name: /^Plate straight/ }));
      await user.click(screen.getByText('Add Step to Recipe'));

      expect(screen.getByText('Plated')).toBeInTheDocument();
      expect(screen.getByText(/using Serving Plate/i)).toBeInTheDocument();
    });

    it('should update step count after adding step', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      await openEditor(user);
      await pickIngredientAndAdvance(user, 'Tomato');
      await user.click(screen.getByText('Chop'));
      await user.click(screen.getByText('Add Step to Recipe'));

      expect(screen.getByText(/1 steps/)).toBeInTheDocument();
    });
  });

  describe('step editing', () => {
    it('should reopen a step for editing and save changes in place', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      await openEditor(user);
      await pickIngredientAndAdvance(user, 'Tomato');
      await user.click(screen.getByText('Chop'));
      await user.click(screen.getByText('Add Step to Recipe'));

      await user.click(screen.getByRole('button', { name: /edit step 1/i }));
      expect(screen.getByText("What's cooking?")).toBeInTheDocument();

      await user.click(screen.getByRole('button', { name: /cook with/i }));
      await user.click(screen.getByText('Dice'));
      await user.click(screen.getByRole('button', { name: /save step/i }));

      expect(screen.getByText('Diced')).toBeInTheDocument();
      expect(screen.getByText(/1 steps/)).toBeInTheDocument();
    });
  });

  describe('step deletion', () => {
    it('should show delete button for each step', () => {
      const recipe = createMockRecipe({
        steps: [createMockRecipeStep()],
      });
      render(<RecipeBuilder initialRecipe={recipe} />);

      expect(screen.getByRole('button', { name: /delete step 1/i })).toBeInTheDocument();
    });
  });

  describe('navigation', () => {
    it('should close editor when back button is clicked', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      await openEditor(user);
      await user.click(screen.getByRole('button', { name: /close step editor/i }));

      expect(screen.queryByText("What's cooking?")).not.toBeInTheDocument();
    });

    it('should call onExit when exit button is clicked', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder onExit={mockOnExit} />);

      await user.click(screen.getByRole('button', { name: /back to explore/i }));
      expect(mockOnExit).toHaveBeenCalled();
    });
  });

  describe('progress bar', () => {
    it('should show progress in editor', async () => {
      const user = userEvent.setup();
      render(<RecipeBuilder />);

      await openEditor(user);

      const progressContainer = screen.getByRole('progressbar', { name: /step editor progress/i });
      expect(progressContainer).toBeInTheDocument();
      expect(progressContainer).toHaveAttribute('aria-valuenow', '1');
      expect(progressContainer).toHaveAttribute('aria-valuemax', '3');
    });
  });

  describe('initial recipe with steps', () => {
    it('should display initial recipe steps', () => {
      const recipe = createMockRecipe({
        steps: [createMockRecipeStep({ actionId: 'chop', toolId: 'knife' })],
      });
      render(<RecipeBuilder initialRecipe={recipe} />);

      expect(screen.getByText('Chopped')).toBeInTheDocument();
    });

    it('should show share button when steps exist', () => {
      const recipe = createMockRecipe({
        steps: [createMockRecipeStep()],
      });
      render(<RecipeBuilder initialRecipe={recipe} />);

      expect(screen.getByRole('button', { name: /share recipe/i })).toBeInTheDocument();
    });
  });
});
