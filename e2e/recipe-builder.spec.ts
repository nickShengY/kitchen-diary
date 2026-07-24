import { test, expect, Page } from '@playwright/test';

const openEditor = async (page: Page) => {
  await page.getByRole('button', { name: /add step/i }).click();
  await expect(page.getByText("What's cooking?")).toBeVisible();
};

const pickIngredientAndAdvance = async (page: Page, ingredientName: string) => {
  await page.getByRole('button', { name: ingredientName, exact: true }).click();
  await page.getByRole('button', { name: /cook with/i }).click({ force: true });
  await expect(page.getByText('How do you cook it?')).toBeVisible();
};

test.describe('Recipe Builder', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.getByRole('button', { name: 'Build', exact: true }).click();
  });

  test('should display empty recipe state', async ({ page }) => {
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

  test('should open the step editor on ingredient picking', async ({ page }) => {
    await openEditor(page);

    await expect(page.getByPlaceholder(/search ingredients/i)).toBeVisible();
    await expect(page.getByRole('button', { name: 'Tomato', exact: true })).toBeVisible();
  });

  test('should filter ingredients by search', async ({ page }) => {
    await openEditor(page);

    await page.getByPlaceholder(/search ingredients/i).fill('tomato');

    await expect(page.getByRole('button', { name: 'Tomato', exact: true })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Chicken', exact: true })).toBeHidden();
  });

  test('should filter ingredients by category', async ({ page }) => {
    await openEditor(page);

    await page.getByRole('button', { name: 'meat', exact: true }).click();

    await expect(page.getByRole('button', { name: 'Chicken', exact: true })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Tomato', exact: true })).toBeHidden();
  });

  test('should select ingredient', async ({ page }) => {
    await openEditor(page);

    await page.getByRole('button', { name: 'Tomato', exact: true }).click();

    await expect(page.locator('.bg-toon-primary').getByText('Tomato')).toBeVisible();
  });

  test('should keep continue disabled until an ingredient is picked', async ({ page }) => {
    await openEditor(page);

    await expect(page.getByRole('button', { name: /pick your ingredients/i })).toBeDisabled();

    await page.getByRole('button', { name: 'Tomato', exact: true }).click();

    await expect(page.getByRole('button', { name: /cook with/i })).toBeEnabled();
  });

  test('should pair each technique with its tool on one card', async ({ page }) => {
    await openEditor(page);
    await pickIngredientAndAdvance(page, 'Tomato');

    await expect(page.getByText('Chop', { exact: true })).toBeVisible();
    await expect(page.getByText(/with Chef Knife/i).first()).toBeVisible();
  });

  test('should hide techniques the ingredients cannot do', async ({ page }) => {
    await openEditor(page);
    await pickIngredientAndAdvance(page, 'Chicken');

    await expect(page.getByText('Peel', { exact: true })).toBeHidden();
  });

  test('should filter techniques by cooking style', async ({ page }) => {
    await openEditor(page);
    await pickIngredientAndAdvance(page, 'Tomato');

    await page.getByRole('tab', { name: /heat/i }).click();

    await expect(page.getByText('Chop', { exact: true })).toBeHidden();
  });

  test('should show heat and duration details for cooking actions', async ({ page }) => {
    await openEditor(page);
    await pickIngredientAndAdvance(page, 'Chicken');
    await page.getByText('Stir Fry', { exact: true }).click();

    await expect(page.getByText('Heat Level')).toBeVisible();
    await expect(page.getByText('Duration')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Low', exact: true })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Medium', exact: true })).toBeVisible();
    await expect(page.getByRole('button', { name: 'High', exact: true })).toBeVisible();
  });

  test('should show matching cut shape for prep actions', async ({ page }) => {
    await openEditor(page);
    await pickIngredientAndAdvance(page, 'Tomato');
    await page.getByText('Chop', { exact: true }).click();

    await expect(page.getByRole('button', { name: /chopped/i })).toBeVisible();
    await expect(page.getByRole('button', { name: /diced/i })).toBeHidden();
  });

  test('should complete full recipe step creation', async ({ page }) => {
    await openEditor(page);
    await pickIngredientAndAdvance(page, 'Chicken');
    await page.getByText('Stir Fry', { exact: true }).click();
    // Include a temperature so the timeline's full settings-chip row renders.
    await page.getByRole('button', { name: 'High', exact: true }).click();
    await page.getByRole('button', { name: '5 mins', exact: true }).click();
    await page.getByText('Add Step to Recipe').click({ force: true });

    await expect(page.getByText('Stir Fried')).toBeVisible();
    await expect(page.getByText(/1 steps/)).toBeVisible();
    await expect(page.getByText('using Frying Pan')).toBeVisible();
    await expect(page.getByText('High')).toBeVisible();
    await expect(page.getByText('5 mins', { exact: true })).toBeVisible();
  });

  test('should edit an existing step in place', async ({ page }) => {
    await openEditor(page);
    await pickIngredientAndAdvance(page, 'Tomato');
    await page.getByText('Chop', { exact: true }).click();
    await page.getByText('Add Step to Recipe').click({ force: true });
    await expect(page.getByText(/1 steps/)).toBeVisible();

    await page.getByRole('button', { name: 'Edit step 1', exact: true }).click();
    await page.getByRole('button', { name: /cook with/i }).click({ force: true });
    await page.getByText('Dice', { exact: true }).click();
    await page.getByRole('button', { name: /save step/i }).click({ force: true });

    await expect(page.getByText('Diced')).toBeVisible();
    await expect(page.getByText(/1 steps/)).toBeVisible();
  });

  test('should delete a step from the timeline', async ({ page }) => {
    await openEditor(page);
    await pickIngredientAndAdvance(page, 'Tomato');
    await page.getByText('Chop', { exact: true }).click();
    await page.getByText('Add Step to Recipe').click({ force: true });
    await expect(page.getByText(/1 steps/)).toBeVisible();

    await page.getByRole('button', { name: 'Delete step 1', exact: true }).click();

    await expect(page.getByText(/0 steps/)).toBeVisible();
  });

  test('should show wizard progress', async ({ page }) => {
    await openEditor(page);

    const progress = page.getByRole('progressbar', { name: /step editor progress/i });
    await expect(progress).toBeVisible();
    await expect(progress).toHaveAttribute('aria-valuenow', '1');
    await expect(progress).toHaveAttribute('aria-valuemax', '3');
  });

  test('should allow going back in editor', async ({ page }) => {
    await openEditor(page);
    await pickIngredientAndAdvance(page, 'Tomato');

    // Back returns to the previous wizard stage first
    await page.getByRole('button', { name: /go back a step/i }).click();
    await expect(page.getByText("What's cooking?")).toBeVisible();

    // Backing out of the first stage closes the editor
    await page.getByRole('button', { name: /close step editor/i }).click();
    await expect(page.getByPlaceholder(/name your recipe/i)).toBeVisible();
  });

  test('should never expose internal asset wording', async ({ page }) => {
    await openEditor(page);
    await pickIngredientAndAdvance(page, 'Tomato');
    await page.getByText('Chop', { exact: true }).click();

    await expect(page.getByText(/generic representation/i)).toHaveCount(0);
    await expect(page.getByText(/gif-ready/i)).toHaveCount(0);
    await expect(page.getByText(/art loaded/i)).toHaveCount(0);
  });
});
