import { test, expect, Page } from '@playwright/test';

const recipeCards = (page: Page) =>
  page.locator('article.break-inside-avoid').filter({
    has: page.getByRole('button', { name: 'Like post', exact: true }),
  });

const waitForLiveFeed = async (page: Page) => {
  const feedError = page.getByText('Unable to load community recipes right now.');
  try {
    await Promise.race([
      recipeCards(page).first().waitFor({ state: 'visible', timeout: 15000 }),
      feedError.waitFor({ state: 'visible', timeout: 15000 }),
    ]);
  } catch {
    // Allow assertion below to provide failure details.
  }

  const hasError = await feedError.isVisible().catch(() => false);
  test.skip(hasError, 'Live community feed API is unavailable in this run.');
  await expect(recipeCards(page).first()).toBeVisible();
};

test.describe('Community View', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await waitForLiveFeed(page);
  });

  test('should display explore header', async ({ page }) => {
    await expect(page.getByRole('heading', { name: 'Explore' })).toBeVisible();
  });

  test('should display search input', async ({ page }) => {
    await expect(page.getByPlaceholder(/find recipes/i)).toBeVisible();
  });

  test('should display tabs', async ({ page }) => {
    await expect(page.getByText('Popular')).toBeVisible();
    await expect(page.getByText('Recent')).toBeVisible();
    await expect(page.getByText('Saved')).toBeVisible();
  });

  test('should display tag filters', async ({ page }) => {
    await expect(page.getByRole('button', { name: 'All', exact: true })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Breakfast', exact: true })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Lunch', exact: true })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Dinner', exact: true })).toBeVisible();
  });

  test('should display live recipe posts', async ({ page }) => {
    expect(await recipeCards(page).count()).toBeGreaterThan(0);
    await expect(recipeCards(page).first().locator('h3').first()).toBeVisible();
  });

  test('should display Daily Wish card', async ({ page }) => {
    await expect(page.getByText('Daily Wish')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Make a Wish' })).toBeVisible();
  });

  test('should filter posts by tag', async ({ page }) => {
    const breakfastTag = page.getByRole('button', { name: 'Breakfast', exact: true });
    await breakfastTag.click();
    await expect(breakfastTag).toHaveClass(/bg-toon-dark/);
  });

  test('should switch between tabs', async ({ page }) => {
    const recentTab = page.getByText('Recent');
    await recentTab.click();
    await expect(recentTab).toHaveClass(/text-toon-primary/);
  });

  test('should search for recipes using live content', async ({ page }) => {
    const firstTitle = ((await recipeCards(page).first().locator('h3').first().textContent()) ?? '').trim();
    expect(firstTitle.length).toBeGreaterThan(0);
    const query = firstTitle.split(/\s+/).find((word) => word.length > 3) ?? firstTitle;

    const searchInput = page.getByPlaceholder(/find recipes/i);
    await searchInput.fill(query);
    await searchInput.press('Enter');

    await expect(page.getByText(firstTitle).first()).toBeVisible();
  });

  test('should show author information on posts', async ({ page }) => {
    const authorLabel = recipeCards(page).first().locator('span.text-\\[10px\\].text-gray-500.font-bold.truncate');
    await expect(authorLabel).toBeVisible();
    await expect(authorLabel).not.toHaveText('');
  });

  test('should display like counters', async ({ page }) => {
    await expect(recipeCards(page).first().getByText('Live')).toBeVisible();
  });

  test('should display comment counters', async ({ page }) => {
    const firstPost = recipeCards(page).first();
    await expect(firstPost.getByLabel('Comment count')).toBeVisible();
  });

  test('should have Cook This button on posts', async ({ page }) => {
    await expect(recipeCards(page).first().getByRole('button', { name: 'Cook This' })).toBeAttached();
  });

  test('should toggle like on a post', async ({ page }) => {
    const postCard = recipeCards(page).first();
    const likeButton = postCard.getByRole('button', { name: 'Like post' });
    await likeButton.click();
    await expect(likeButton).toHaveClass(/text-pink-500/);

    await likeButton.click();
    await expect(likeButton).not.toHaveClass(/text-pink-500/);
  });

  test('should combine tag and search filters', async ({ page }) => {
    const allTag = page.getByRole('button', { name: 'All', exact: true });
    await allTag.click();

    const firstTitle = ((await recipeCards(page).first().locator('h3').first().textContent()) ?? '').trim();
    const query = firstTitle.split(/\s+/).find((word) => word.length > 3) ?? firstTitle;

    const searchInput = page.getByPlaceholder(/find recipes/i);
    await searchInput.fill(query);
    await searchInput.press('Enter');

    await expect(page.getByText(firstTitle).first()).toBeVisible();
  });
});
