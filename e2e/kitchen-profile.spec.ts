import { test, expect } from '@playwright/test';

/**
 * The Kitchen tab writes saved dishes and cook history; the Profile tab reads
 * them back. These specs cover that hand-off end to end.
 */
test.describe('Kitchen and Profile', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.getByRole('button', { name: 'Kitchen', exact: true }).click();
    await page.getByRole('button', { name: /fill it in/i }).click();
    await expect(page.getByRole('heading', { name: /you can cook/i })).toBeVisible();
  });

  const firstResult = (page: import('@playwright/test').Page) =>
    page.getByRole('region', { name: /you can cook/i }).getByRole('listitem').first();

  test('a saved dish shows up under Profile', async ({ page }) => {
    const card = firstResult(page);
    const title = await card.locator('article').getByRole('button').first().innerText();
    await card.getByRole('button', { name: /^save /i }).click();

    await page.getByRole('button', { name: 'Profile', exact: true }).click();
    await page.getByRole('button', { name: /^saved/i }).click();

    const panel = page.getByRole('dialog', { name: /saved recipes/i });
    await expect(panel.getByText(title.split('\n')[0], { exact: false }).first()).toBeVisible();
  });

  test('cooking a dish records it in history even though the view changes', async ({ page }) => {
    await firstResult(page).getByRole('button', { name: /^cook$/i }).click();
    await expect(page.getByRole('button', { name: /watch/i })).toBeVisible();

    await page.getByRole('button', { name: 'Profile', exact: true }).click();
    await page.getByRole('button', { name: /^history/i }).click();

    const panel = page.getByRole('dialog', { name: /recently cooked/i });
    await expect(panel.getByRole('article')).toHaveCount(1);
  });

  test('clearing history empties it in storage', async ({ page }) => {
    await firstResult(page).getByRole('button', { name: /^cook$/i }).click();

    await page.getByRole('button', { name: 'Profile', exact: true }).click();
    await page.getByRole('button', { name: /^history/i }).click();
    await page.getByRole('button', { name: /clear all/i }).click();

    await expect(page.getByText(/nothing cooked yet/i)).toBeVisible();
  });

  test('cooking again from Profile reopens the builder', async ({ page }) => {
    await firstResult(page).getByRole('button', { name: /^save /i }).click();

    await page.getByRole('button', { name: 'Profile', exact: true }).click();
    await page.getByRole('button', { name: /^saved/i }).click();
    await page.getByRole('dialog').getByRole('button', { name: /^cook$/i }).click();

    await expect(page.getByRole('button', { name: /watch/i })).toBeVisible();
  });

  test('the kitchen shelf is reachable without signing in', async ({ page }) => {
    await page.getByRole('button', { name: 'Profile', exact: true }).click();

    await expect(page.getByRole('button', { name: /continue with google/i })).toBeVisible();
    await expect(page.getByRole('heading', { name: /your kitchen/i })).toBeVisible();
    await expect(page.getByRole('button', { name: /^cookbook/i })).toBeVisible();
  });
});
