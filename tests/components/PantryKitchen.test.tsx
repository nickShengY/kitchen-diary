import { beforeEach, describe, it, expect, vi } from 'vitest';
import { screen, waitFor, within } from '@testing-library/react';
import { renderWithProviders } from '../utils/test-utils';
import { PantryKitchen } from '../../components/PantryKitchen';
import { loadPantry } from '../../services/pantryStore';

describe('PantryKitchen', () => {
  const onCookThis = vi.fn();

  beforeEach(() => {
    onCookThis.mockClear();
    window.localStorage.clear();
    // jsdom has no layout engine, so scrollIntoView is not implemented.
    Element.prototype.scrollIntoView = vi.fn();
  });

  it('renders the pantry, cookware, and mode sections', () => {
    renderWithProviders(<PantryKitchen onCookThis={onCookThis} />);

    expect(screen.getByRole('heading', { name: /kitchen/i, level: 1 })).toBeInTheDocument();
    expect(screen.getByRole('heading', { name: /in your kitchen/i })).toBeInTheDocument();
    expect(screen.getByRole('heading', { name: /what can you cook with/i })).toBeInTheDocument();
    expect(screen.getByRole('heading', { name: /how strict should we be/i })).toBeInTheDocument();
  });

  it('shows every dish as an idea before anything is selected', () => {
    renderWithProviders(<PantryKitchen onCookThis={onCookThis} />);

    expect(screen.getByRole('heading', { name: /ideas to get you started/i })).toBeInTheDocument();
  });

  it('adds an ingredient to the kitchen and narrows the results', async () => {
    const { user } = renderWithProviders(<PantryKitchen onCookThis={onCookThis} />);

    await user.click(screen.getByRole('tab', { name: /^protein$/i }));
    const chickenTile = screen.getByRole('button', { name: /^chicken$/i });
    await user.click(chickenTile);

    expect(chickenTile).toHaveAttribute('aria-pressed', 'true');
    await waitFor(() =>
      expect(screen.getByRole('heading', { name: /you can cook/i })).toBeInTheDocument(),
    );
  });

  it('persists the pantry so a reload keeps the selection', async () => {
    const { user, unmount } = renderWithProviders(<PantryKitchen onCookThis={onCookThis} />);

    await user.click(screen.getByRole('button', { name: /fill it in/i }));
    await waitFor(() => expect(loadPantry().ingredients.length).toBeGreaterThan(0));

    unmount();
    renderWithProviders(<PantryKitchen onCookThis={onCookThis} />);

    await waitFor(() =>
      expect(screen.getByRole('button', { name: /remove egg from your kitchen/i })).toBeInTheDocument(),
    );
  });

  it('switches match mode and keeps it in storage', async () => {
    const { user } = renderWithProviders(<PantryKitchen onCookThis={onCookThis} />);

    await user.click(screen.getByRole('tab', { name: /survival/i }));

    expect(screen.getByRole('tab', { name: /survival/i })).toHaveAttribute('aria-selected', 'true');
    await waitFor(() => expect(loadPantry().mode).toBe('survival'));
  });

  it('rolls a menu and lists the requested number of dishes', async () => {
    const { user } = renderWithProviders(<PantryKitchen onCookThis={onCookThis} />);

    await user.click(screen.getByRole('button', { name: /fill it in/i }));
    await user.click(screen.getByRole('button', { name: /roll tonight's menu/i }));

    const menu = screen.getByRole('region', { name: /tonight's menu/i });
    await waitFor(() => expect(within(menu).getAllByRole('listitem').length).toBe(3));
    expect(within(menu).getByRole('button', { name: /shopping list/i })).toBeInTheDocument();
  });

  it('opens a recipe sheet and hands the recipe to the builder', async () => {
    const { user } = renderWithProviders(<PantryKitchen onCookThis={onCookThis} />);

    const results = screen.getByRole('region', { name: /ideas to get you started/i });
    const firstCard = within(results).getAllByRole('listitem')[0];
    await user.click(within(firstCard).getAllByRole('button')[0]);

    const sheet = await screen.findByRole('dialog');
    expect(within(sheet).getByRole('heading', { name: /how it goes/i })).toBeInTheDocument();

    await user.click(within(sheet).getByRole('button', { name: /open in the builder/i }));

    expect(onCookThis).toHaveBeenCalledTimes(1);
    const handed = onCookThis.mock.calls[0][0];
    expect(handed.id).toMatch(/^pantry-/);
    expect(handed.steps.length).toBeGreaterThan(0);
  });

  it('records a cooked dish in history', async () => {
    const { user } = renderWithProviders(<PantryKitchen onCookThis={onCookThis} />);

    const results = screen.getByRole('region', { name: /ideas to get you started/i });
    const firstCard = within(results).getAllByRole('listitem')[0];
    await user.click(within(firstCard).getByRole('button', { name: /^cook$/i }));

    await waitFor(() => expect(loadPantry().history).toHaveLength(1));
  });

  it('persists the cooked dish even when cooking unmounts the screen', async () => {
    // "Cook" navigates to the builder, so this screen goes away in the same
    // commit. A save that waited for an effect would never run.
    const { user, unmount } = renderWithProviders(
      <PantryKitchen onCookThis={() => unmount()} />,
    );

    const results = screen.getByRole('region', { name: /ideas to get you started/i });
    const firstCard = within(results).getAllByRole('listitem')[0];
    await user.click(within(firstCard).getByRole('button', { name: /^cook$/i }));

    expect(loadPantry().history).toHaveLength(1);
  });

  it('saves a favorite recipe', async () => {
    const { user } = renderWithProviders(<PantryKitchen onCookThis={onCookThis} />);

    const results = screen.getByRole('region', { name: /ideas to get you started/i });
    const firstCard = within(results).getAllByRole('listitem')[0];
    const saveButton = within(firstCard).getByRole('button', { name: /^save /i });
    await user.click(saveButton);

    expect(saveButton).toHaveAttribute('aria-pressed', 'true');
    await waitFor(() => expect(loadPantry().favorites).toHaveLength(1));
  });

  it('suggests unlocking ingredients when nothing matches', async () => {
    const { user } = renderWithProviders(<PantryKitchen onCookThis={onCookThis} />);

    await user.click(screen.getByRole('tab', { name: /^flavour$/i }));
    await user.click(screen.getByRole('button', { name: /^nutmeg$/i }));
    await user.click(screen.getByRole('tab', { name: /survival/i }));

    expect(await screen.findByText(/nothing matches yet/i)).toBeInTheDocument();
  });

  it('filters the ingredient picker by search', async () => {
    const { user } = renderWithProviders(<PantryKitchen onCookThis={onCookThis} />);

    await user.type(screen.getByRole('searchbox', { name: /search ingredients/i }), 'zzzz');

    expect(await screen.findByText(/nothing called/i)).toBeInTheDocument();
  });
});
