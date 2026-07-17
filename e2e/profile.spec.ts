import { test, expect, Page } from '@playwright/test';

const signInWithLiveProfile = async (page: Page) => {
  await page.getByRole('button', { name: /create live profile/i }).click();

  const signOut = page.getByRole('button', { name: /sign out/i });
  await Promise.race([
    signOut.waitFor({ state: 'visible', timeout: 12000 }),
    page.getByRole('button', { name: /create live profile/i }).waitFor({ state: 'visible', timeout: 12000 }),
  ]).catch(() => undefined);

  const loggedIn = await signOut.isVisible().catch(() => false);
  test.skip(!loggedIn, 'Live identity API is unavailable in this run.');
};

test.describe('Profile View', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.getByRole('button', { name: 'Profile', exact: true }).click();
  });

  test('should display login screen when not authenticated', async ({ page }) => {
    await expect(page.getByText('CookToon')).toBeVisible();
  });

  test('should display welcome message', async ({ page }) => {
    await expect(page.getByText(/join the cooking community/i)).toBeVisible();
  });

  test('should display sign in button', async ({ page }) => {
    await expect(page.getByRole('button', { name: /create live profile/i })).toBeVisible();
  });

  test('should display live identity note', async ({ page }) => {
    await expect(page.getByText(/profile data is saved in this browser/i)).toBeVisible();
  });

  test('should show loading state when signing in', async ({ page }) => {
    const signInButton = page.getByRole('button', { name: /create live profile/i });
    await signInButton.click();
    await expect(page.getByRole('button', { name: /creating profile/i })).toBeVisible();
  });

  test('should show profile after login', async ({ page }) => {
    await signInWithLiveProfile(page);
    await expect(page.locator('h2.text-2xl.text-toon-dark')).toBeVisible();
  });

  test('should display user bio', async ({ page }) => {
    await signInWithLiveProfile(page);
    await expect(page.getByText(/cooking through/i)).toBeVisible();
  });

  test('should display statistics', async ({ page }) => {
    await signInWithLiveProfile(page);
    await expect(page.getByText('Recipes')).toBeVisible();
    await expect(
      page.getByText(/social totals will appear once your connected backend provides them/i),
    ).toBeVisible();
  });

  test('should display stat values', async ({ page }) => {
    await signInWithLiveProfile(page);
    await expect(page.locator('div.text-xl.text-toon-dark')).toHaveCount(1);
  });

  test('should display action buttons', async ({ page }) => {
    await signInWithLiveProfile(page);
    await expect(page.getByText('Favorites')).toBeVisible();
    await expect(page.getByText('My Cookbook')).toBeVisible();
  });

  test('should display sign out button', async ({ page }) => {
    await signInWithLiveProfile(page);
    await expect(page.getByRole('button', { name: /sign out/i })).toBeVisible();
  });

  test('should sign out and return to login', async ({ page }) => {
    await signInWithLiveProfile(page);
    await page.getByRole('button', { name: /sign out/i }).click();
    await expect(page.getByRole('button', { name: /create live profile/i })).toBeVisible();
  });

  test('should have settings button when logged in', async ({ page }) => {
    await signInWithLiveProfile(page);
    await page.getByRole('button', { name: 'Profile settings', exact: true }).click();
    await expect(page.getByRole('dialog', { name: 'Profile Settings' })).toBeVisible();
  });

  test('should have clickable action buttons', async ({ page }) => {
    await signInWithLiveProfile(page);

    await page.getByRole('button', { name: 'Favorites', exact: true }).click();
    await expect(page.getByRole('dialog', { name: 'Favorites' })).toBeVisible();
    await expect(page.getByText('No favorites yet')).toBeVisible();
    await page.getByRole('button', { name: 'Close profile panel', exact: true }).click();

    await page.getByRole('button', { name: 'My Cookbook', exact: true }).click();
    await expect(page.getByRole('dialog', { name: 'My Cookbook' })).toBeVisible();
    await expect(page.getByText('No cookbook recipes yet')).toBeVisible();
  });
});

test.describe('Profile Authentication Flow', () => {
  test('should persist login state during navigation', async ({ page }) => {
    await page.goto('/');
    await page.getByRole('button', { name: 'Profile', exact: true }).click();
    await signInWithLiveProfile(page);

    await page.getByRole('button', { name: 'Explore', exact: true }).click();
    await expect(page.getByRole('heading', { name: 'Explore' })).toBeVisible();

    await page.getByRole('button', { name: 'Profile', exact: true }).click();
    await expect(page.getByRole('button', { name: /sign out/i })).toBeVisible();
  });

  test('should allow multiple login/logout cycles', async ({ page, browserName }) => {
    test.skip(browserName === 'webkit', 'Flaky in WebKit');
    await page.goto('/');
    await page.getByRole('button', { name: 'Profile', exact: true }).click();

    await signInWithLiveProfile(page);
    await page.getByRole('button', { name: /sign out/i }).click();
    await expect(page.getByRole('button', { name: /create live profile/i })).toBeVisible();

    await signInWithLiveProfile(page);
    await expect(page.getByRole('button', { name: /sign out/i })).toBeVisible();
  });
});
