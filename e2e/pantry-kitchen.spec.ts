import { test, expect } from '@playwright/test';

test.describe('Pantry Kitchen', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.getByRole('button', { name: 'Kitchen', exact: true }).click();
    await expect(page.getByRole('heading', { name: 'Kitchen', level: 1 })).toBeVisible();
  });

  test('shows the pantry, cookware, and strictness sections', async ({ page }) => {
    await expect(page.getByRole('heading', { name: /in your kitchen/i })).toBeVisible();
    await expect(page.getByRole('heading', { name: /what can you cook with/i })).toBeVisible();
    await expect(page.getByRole('heading', { name: /how strict should we be/i })).toBeVisible();
  });

  test('suggests dishes before anything is selected', async ({ page }) => {
    await expect(page.getByRole('heading', { name: /ideas to get you started/i })).toBeVisible();
  });

  test('matches dishes once the kitchen is stocked', async ({ page }) => {
    await page.getByRole('button', { name: /fill it in/i }).click();

    await expect(page.getByRole('heading', { name: /you can cook/i })).toBeVisible();
    await expect(page.getByText(/all the essentials are in your kitchen/i).first()).toBeVisible();
  });

  test('keeps the pantry after a reload', async ({ page }) => {
    await page.getByRole('button', { name: /fill it in/i }).click();
    await expect(page.getByRole('button', { name: /remove egg from your kitchen/i })).toBeVisible();

    await page.reload();
    await page.getByRole('button', { name: 'Kitchen', exact: true }).click();

    await expect(page.getByRole('button', { name: /remove egg from your kitchen/i })).toBeVisible();
  });

  test('narrows results with survival mode', async ({ page }) => {
    await page.getByRole('button', { name: /fill it in/i }).click();
    const flexibleCount = await page.getByRole('listitem').count();

    await page.getByRole('tab', { name: /survival/i }).click();
    await expect(page.getByRole('tab', { name: /survival/i })).toHaveAttribute('aria-selected', 'true');

    expect(await page.getByRole('listitem').count()).toBeLessThan(flexibleCount);
  });

  test('rolls a balanced menu with a shopping list', async ({ page }) => {
    await page.getByRole('button', { name: /fill it in/i }).click();
    await page.getByRole('button', { name: /roll tonight's menu/i }).click();

    const menu = page.getByRole('region', { name: /tonight's menu/i });
    await expect(menu.getByRole('listitem')).toHaveCount(3);
    await expect(menu.getByRole('button', { name: /shopping list/i })).toBeVisible();
  });

  test('opens a recipe and sends it to the builder', async ({ page }) => {
    await page.getByRole('button', { name: /fill it in/i }).click();

    const results = page.getByRole('region', { name: /you can cook/i });
    await results.getByRole('listitem').first().getByRole('button').first().click();

    const sheet = page.getByRole('dialog');
    await expect(sheet.getByRole('heading', { name: /how it goes/i })).toBeVisible();

    await sheet.getByRole('button', { name: /open in the builder/i }).click();

    await expect(page.getByRole('button', { name: /watch/i })).toBeVisible();
  });
});
