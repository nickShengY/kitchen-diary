import { test, expect } from '@playwright/test';

test.describe('Recipe Builder', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.getByRole('button', { name: 'Build', exact: true }).click();
  });

  test('should display empty recipe state', async ({ page }) => {
    await expect(page.getByPlaceholder(/name your recipe/i)).toBeVisible();
  });

  test('should display recipe name input', async ({ page }) => {
    await expect(page.getByPlaceholder(/name your recipe/i)).toBeVisible();
  });

  test('should allow editing recipe name', async ({ page }) => {
    const nameInput = page.getByPlaceholder(/name your recipe/i);
    await nameInput.clear();
    await nameInput.fill('My Amazing Recipe');

    await expect(nameInput).toHaveValue('My Amazing Recipe');
  });

  test('should display step count', async ({ page }) => {
    await expect(page.getByText(/steps/)).toBeVisible();
  });

  test('should open step editor when add button clicked', async ({ page }) => {
    // Find and click the add step button
    await page.getByRole('button', { name: /add step/i }).click();

    await expect(page.getByText('Select Station')).toBeVisible();
  });

  test('should show station options', async ({ page }) => {
    await page.getByRole('button', { name: /add step/i }).click();

    await expect(page.getByText('Prep Station')).toBeVisible();
    await expect(page.getByText('Hot Station')).toBeVisible();
    await expect(page.getByText('Plating')).toBeVisible();
  });

  test('should navigate to tool selection after selecting station', async ({ page }) => {
    await page.getByRole('button', { name: /add step/i }).click();

    await page.getByText('Prep Station').click();

    await expect(page.getByText('Choose Tool')).toBeVisible();
    await expect(page.getByText('Chef Knife')).toBeVisible();
  });

  test('should show prep tools for prep station', async ({ page }) => {
    await page.getByRole('button', { name: /add step/i }).click();
    await page.getByText('Prep Station').click();

    await expect(page.getByText('Chef Knife')).toBeVisible();
    await expect(page.getByText('Mixing Bowl')).toBeVisible();
    await expect(page.getByText('Peeler')).toBeVisible();
  });

  test('should show cook tools for hot station', async ({ page }) => {
    await page.getByRole('button', { name: /add step/i }).click();
    await page.getByText('Hot Station').click();

    await expect(page.getByText('Frying Pan')).toBeVisible();
    await expect(page.getByText('Stock Pot')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Oven', exact: true })).toBeVisible();
    await expect(page.getByText('Grill')).toBeVisible();
  });

  test('should navigate to ingredient selection after selecting tool', async ({ page }) => {
    await page.getByRole('button', { name: /add step/i }).click();
    await page.getByText('Prep Station').click();
    await page.getByText('Chef Knife').click();

    await expect(page.getByText('Add Ingredients')).toBeVisible();
  });

  test('should display ingredients grid', async ({ page }) => {
    await page.getByRole('button', { name: /add step/i }).click();
    await page.getByText('Prep Station').click();
    await page.getByText('Chef Knife').click();

    await expect(page.getByText('Tomato')).toBeVisible();
    await expect(page.getByText('Carrot')).toBeVisible();
    await expect(page.getByText('Onion')).toBeVisible();
    await expect(page.getByText('Garlic')).toBeVisible();
  });

  test('should select ingredient', async ({ page }) => {
    await page.getByRole('button', { name: /add step/i }).click();
    await page.getByText('Prep Station').click();
    await page.getByText('Chef Knife').click();
    await page.getByText('Tomato').click();

    // Ingredient should appear in selection area
    await expect(page.locator('.bg-toon-primary').getByText('Tomato')).toBeVisible();
  });

  test('should enable Done button when ingredient selected', async ({ page }) => {
    await page.getByRole('button', { name: /add step/i }).click();
    await page.getByText('Prep Station').click();
    await page.getByText('Chef Knife').click();

    const doneButton = page.getByText('Done with Ingredients');
    await expect(doneButton).toBeDisabled();

    await page.getByText('Tomato').click();
    await expect(doneButton).toBeEnabled();
  });

  test('should navigate to action selection after ingredients', async ({ page }) => {
    await page.getByRole('button', { name: /add step/i }).click();
    await page.getByText('Prep Station').click();
    await page.getByText('Chef Knife').click();
    await page.getByText('Tomato').click();
    await page.getByText('Done with Ingredients').click({ force: true });

    await expect(page.getByText('Process')).toBeVisible();
    await expect(page.getByText('Chop')).toBeVisible();
  });

  test('should show compatible actions for selected ingredients', async ({ page }) => {
    await page.getByRole('button', { name: /add step/i }).click();
    await page.getByText('Prep Station').click();
    await page.getByText('Chef Knife').click();
    await page.getByText('Tomato').click();
    await page.getByText('Done with Ingredients').click({ force: true });

    // Knife actions for choppable ingredients
    await expect(page.getByText('Chop')).toBeVisible();
    await expect(page.getByText('Dice')).toBeVisible();
    await expect(page.getByText('Slice')).toBeVisible();
    await expect(page.getByText('Mince')).toBeVisible();
  });

  test('should navigate to details after action selection', async ({ page }) => {
    await page.getByRole('button', { name: /add step/i }).click();
    await page.getByText('Prep Station').click();
    await page.getByText('Chef Knife').click();
    await page.getByText('Tomato').click();
    await page.getByText('Done with Ingredients').click();
    await page.getByText('Chop').click();

    await expect(page.getByText('Cooking Details')).toBeVisible();
    await expect(page.getByText('Duration')).toBeVisible();
  });

  test('should show temperature options for cooking actions', async ({ page }) => {
    await page.getByRole('button', { name: /add step/i }).click();
    await page.getByText('Hot Station').click();
    await page.getByText('Frying Pan').click();
    await page.getByText('Chicken').click();
    await page.getByText('Done with Ingredients').click({ force: true });
    await page.getByText('Stir Fry').click();

    await expect(page.getByText('Heat Level')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Low', exact: true })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Medium', exact: true })).toBeVisible();
    await expect(page.getByRole('button', { name: 'High', exact: true })).toBeVisible();
  });

  test('should complete full recipe step creation', async ({ page }) => {
    await page.getByRole('button', { name: /add step/i }).click();
    await page.getByText('Prep Station').click();
    await page.getByText('Chef Knife').click();
    await page.getByText('Tomato').click();
    await page.getByText('Done with Ingredients').click({ force: true });
    await page.getByText('Chop').click();
    await page.getByRole('button', { name: '5 mins', exact: true }).click();
    await page.getByText('Add Step to Recipe').click({ force: true });

    // Should return to list view with step
    await expect(page.getByText('Chopped')).toBeVisible();
    await expect(page.getByText(/steps/)).toBeVisible();
  });

  test('should show step timeline after adding steps', async ({ page }) => {
    await page.getByRole('button', { name: /add step/i }).click();
    await page.getByText('Prep Station').click();
    await page.getByText('Chef Knife').click();
    await page.getByText('Tomato').click();
    await page.getByText('Done with Ingredients').click({ force: true });
    await page.getByText('Chop').click();
    await page.getByRole('button', { name: '5 mins', exact: true }).click();
    await page.getByText('Add Step to Recipe').click({ force: true });

    // Step should appear with details
    await expect(page.getByText('Chopped')).toBeVisible();
    await expect(page.getByText('using Chef Knife')).toBeVisible();
    await expect(page.getByText('using Chef Knife')).toBeVisible();
  });

  test('should show progress bar in editor', async ({ page }) => {
    await page.getByRole('button', { name: /add step/i }).click();

    await expect(page.getByRole('progressbar', { name: /step editor progress/i })).toBeVisible();
  });

  test('should allow going back in editor', async ({ page }) => {
    await page.getByRole('button', { name: /add step/i }).click();
    await page.getByText('Prep Station').click();

    // Back returns to the previous wizard stage first
    await page.getByRole('button', { name: /go back a step/i }).click();
    await expect(page.getByText('Select Station')).toBeVisible();

    // Backing out of the first stage closes the editor
    await page.getByRole('button', { name: /close step editor/i }).click();
    await expect(page.getByPlaceholder(/name your recipe/i)).toBeVisible();
  });
});
