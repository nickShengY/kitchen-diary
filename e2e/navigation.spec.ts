import { test, expect } from '@playwright/test';

test.describe('Navigation', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('should load the app with Community view', async ({ page }) => {
    await expect(page.getByRole('heading', { name: 'Explore' })).toBeVisible();
  });

  test('should show navigation bar', async ({ page }) => {
    await expect(page.getByRole('button', { name: 'Explore', exact: true })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Build', exact: true })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Decide', exact: true })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Profile', exact: true })).toBeVisible();
  });

  test('should navigate to Decider view', async ({ page }) => {
    await page.getByRole('button', { name: 'Decide', exact: true }).click();
    await expect(page.getByText('Spin Cuisine')).toBeVisible();
  });

  test('should navigate to Profile view', async ({ page }) => {
    await page.getByRole('button', { name: 'Profile', exact: true }).click();
    await expect(page.getByText('CookToon')).toBeVisible();
    await expect(page.getByRole('button', { name: /continue with google/i })).toBeVisible();
  });

  test('should navigate back to Community view', async ({ page }) => {
    await page.getByRole('button', { name: 'Decide', exact: true }).click();
    await page.getByRole('button', { name: 'Explore', exact: true }).click();
    await expect(page.getByRole('heading', { name: 'Explore' })).toBeVisible();
  });

  test('should highlight active navigation item', async ({ page }) => {
    const homeButton = page.getByRole('button', { name: 'Explore', exact: true });
    await expect(homeButton).toHaveClass(/from-toon-primary/);
  });

  test('should navigate through all views', async ({ page }) => {
    // Start at Community
    await expect(page.getByRole('heading', { name: 'Explore' })).toBeVisible();

    // Go to Decider
    await page.getByRole('button', { name: 'Decide', exact: true }).click();
    await expect(page.getByText('Spin Cuisine')).toBeVisible();

    // Go to Profile
    await page.getByRole('button', { name: 'Profile', exact: true }).click();
    await expect(page.getByRole('button', { name: /continue with google/i })).toBeVisible();

    // Go back to Community
    await page.getByRole('button', { name: 'Explore', exact: true }).click();
    await expect(page.getByRole('heading', { name: 'Explore' })).toBeVisible();
  });
});
