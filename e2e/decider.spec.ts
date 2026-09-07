import { test, expect, Page } from '@playwright/test';

const waitForLiveCuisines = async (page: Page) => {
  const error = page.getByText('Unable to load live cuisine categories.');
  const loading = page.getByText('Loading cuisines...');

  await Promise.race([
    loading.waitFor({ state: 'hidden', timeout: 15000 }),
    error.waitFor({ state: 'visible', timeout: 15000 }),
  ]).catch(() => undefined);

  const hasError = await error.isVisible().catch(() => false);
  test.skip(hasError, 'Live cuisine API is unavailable in this run.');
  await expect(page.getByRole('button', { name: /spin cuisine/i })).toBeEnabled();
};

const ensureDishPhaseWithDishes = async (page: Page) => {
  for (let attempt = 0; attempt < 4; attempt += 1) {
    await page.getByRole('button', { name: /spin cuisine/i }).click();
    await page.waitForTimeout(3500);
    await page.getByRole('button', { name: /find a dish/i }).click();

    const spinDishButton = page.getByRole('button', { name: /spin dish/i });
    if (await spinDishButton.isEnabled()) {
      return;
    }

    await page.getByRole('button', { name: /back to cuisines/i }).click();
  }

  throw new Error('Could not find a cuisine with at least one dish after multiple attempts.');
};

test.describe('Decider Wheel', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.getByRole('button', { name: 'Decide', exact: true }).click();
    await waitForLiveCuisines(page);
  });

  test('should display decider header', async ({ page }) => {
    await expect(page.getByRole('heading', { name: 'Decide' })).toBeVisible();
  });

  test('should display mode toggle', async ({ page }) => {
    await expect(page.getByRole('button', { name: 'Wheel', exact: true })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Scan', exact: true })).toBeVisible();
  });

  test('should have wheel mode active by default', async ({ page }) => {
    const wheelButton = page.getByRole('button', { name: 'Wheel', exact: true });
    await expect(wheelButton).toHaveClass(/bg-toon-dark/);
  });

  test('should display phase indicator', async ({ page }) => {
    await expect(page.getByText('1. Cuisine')).toBeVisible();
    await expect(page.getByText('2. Dish')).toBeVisible();
  });

  test('should display spin button', async ({ page }) => {
    await expect(page.getByRole('button', { name: /spin cuisine/i })).toBeVisible();
  });

  test('should display customize wheel button', async ({ page }) => {
    await expect(page.getByText('Customize Wheel')).toBeVisible();
  });

  test('should display live cuisines', async ({ page }) => {
    const cuisineTiles = page.locator('div.bg-orange-50.rounded-xl.p-3.text-center.border');
    expect(await cuisineTiles.count()).toBeGreaterThan(0);
    await expect(cuisineTiles.first().locator('div').nth(1)).toBeVisible();
  });

  test('should display cuisine emojis', async ({ page }) => {
    const firstTileEmoji = page.locator('div.bg-orange-50.rounded-xl.p-3.text-center.border').first().locator('div').first();
    await expect(firstTileEmoji).toBeVisible();
    await expect(firstTileEmoji).not.toHaveText('');
  });

  test('should spin when button clicked', async ({ page }) => {
    await page.getByRole('button', { name: /spin cuisine/i }).click();
    await expect(page.getByText('Rolling...')).toBeVisible();
  });

  test('should disable spin button while spinning', async ({ page }) => {
    const spinButton = page.getByRole('button', { name: /spin cuisine/i });
    await spinButton.click();
    await expect(page.getByRole('button', { name: /rolling/i })).toBeDisabled();
  });

  test('should select cuisine after spinning', async ({ page }) => {
    await page.getByRole('button', { name: /spin cuisine/i }).click();
    await page.waitForTimeout(3500);
    await expect(page.getByRole('button', { name: /find a dish/i })).toBeVisible();
  });

  test('should advance to dish phase', async ({ page }) => {
    await page.getByRole('button', { name: /spin cuisine/i }).click();
    await page.waitForTimeout(3500);
    await page.getByRole('button', { name: /find a dish/i }).click();
    await expect(page.getByRole('button', { name: /spin dish/i })).toBeVisible();
  });

  test('should show back button in dish phase', async ({ page }) => {
    await page.getByRole('button', { name: /spin cuisine/i }).click();
    await page.waitForTimeout(3500);
    await page.getByRole('button', { name: /find a dish/i }).click();
    await expect(page.getByRole('button', { name: /back to cuisines/i })).toBeVisible();
  });

  test('should return to cuisine phase when back clicked', async ({ page }) => {
    await page.getByRole('button', { name: /spin cuisine/i }).click();
    await page.waitForTimeout(3500);
    await page.getByRole('button', { name: /find a dish/i }).click();
    await page.getByRole('button', { name: /back to cuisines/i }).click();
    await expect(page.getByRole('button', { name: /spin cuisine/i })).toBeVisible();
  });

  test('should open edit modal', async ({ page }) => {
    await page.getByText('Customize Wheel').click();
    await expect(page.getByText('Edit Cuisines')).toBeVisible();
  });

  test('should show cuisine list in edit modal', async ({ page }) => {
    await page.getByText('Customize Wheel').click();
    await expect(page.getByText(/\d+ dishes/).first()).toBeVisible();
  });

  test('should add new cuisine', async ({ page }) => {
    await page.getByText('Customize Wheel').click();

    const input = page.getByPlaceholder('Add new cuisine...');
    await input.fill('Korean');
    await input.press('Enter');

    const cuisineList = page.locator('div.fixed.inset-0').locator('.overflow-y-auto');
    await expect(cuisineList).toContainText('Korean');
  });

  test('should show dish editor when cuisine clicked', async ({ page }) => {
    await page.getByText('Customize Wheel').click();
    await page.locator('.cursor-pointer').first().click();
    await expect(page.getByRole('heading', { name: /edit /i })).toBeVisible();
  });

  test('should add dish to cuisine', async ({ page }) => {
    await page.getByText('Customize Wheel').click();
    await page.locator('.cursor-pointer').first().click();

    const input = page.getByPlaceholder('Add a new dish...');
    await input.fill('E2E Test Dish');
    await input.press('Enter');

    await expect(page.getByText('E2E Test Dish')).toBeVisible();
  });

  test('should switch to scan mode', async ({ page }) => {
    await page.getByRole('button', { name: 'Scan', exact: true }).click();
    await expect(page.getByText('Snap a Menu')).toBeVisible();
  });

  test('should show camera upload in scan mode', async ({ page }) => {
    await page.getByRole('button', { name: 'Scan', exact: true }).click();
    await expect(page.getByText('Snap a Menu')).toBeVisible();
    await expect(page.getByText(/Upload a menu photo and we.?ll pick a dish/i)).toBeVisible();
  });

  test('should have file input in scan mode', async ({ page }) => {
    await page.getByRole('button', { name: 'Scan', exact: true }).click();
    await expect(page.locator('input[type="file"]')).toBeHidden();
  });

  test('should switch back to wheel mode', async ({ page }) => {
    await page.getByRole('button', { name: 'Scan', exact: true }).click();
    await page.getByRole('button', { name: 'Wheel', exact: true }).click();
    await expect(page.getByRole('button', { name: /spin cuisine/i })).toBeVisible();
  });

  test('should complete full spin flow', async ({ page }) => {
    await ensureDishPhaseWithDishes(page);
    await page.getByRole('button', { name: /spin dish/i }).click();
    await page.waitForTimeout(3500);
    await expect(page.getByText(/Bon App/i)).toBeVisible();
  });

  test('should show respin options after final selection', async ({ page, browserName }) => {
    test.skip(browserName === 'webkit', 'Flaky in WebKit');
    await ensureDishPhaseWithDishes(page);
    await page.getByRole('button', { name: /spin dish/i }).click();
    await page.waitForTimeout(3500);

    await expect(page.getByRole('button', { name: 'Respin Dish' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'New Cuisine' })).toBeVisible();
  });

  test('should reset when New Cuisine clicked', async ({ page }) => {
    await ensureDishPhaseWithDishes(page);
    await page.getByRole('button', { name: /spin dish/i }).click();
    await page.waitForTimeout(3500);
    await page.getByRole('button', { name: 'New Cuisine', exact: true }).click();
    await expect(page.getByRole('button', { name: /spin cuisine/i })).toBeVisible();
  });
});
