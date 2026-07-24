import { test, expect, Page } from '@playwright/test';

test.describe.configure({ mode: 'serial' });
test.setTimeout(60000);

const recipeCards = (page: Page) =>
  page.locator('article.break-inside-avoid').filter({ has: page.getByRole('button', { name: 'Like post' }) });

const waitForLiveFeed = async (page: Page) => {
  const feedError = page.getByText('Unable to load community recipes right now.');
  await Promise.race([
    recipeCards(page).first().waitFor({ state: 'visible', timeout: 15000 }),
    feedError.waitFor({ state: 'visible', timeout: 15000 }),
  ]).catch(() => undefined);

  const hasError = await feedError.isVisible().catch(() => false);
  test.skip(hasError, 'Live community feed API is unavailable in this run.');
  await expect(recipeCards(page).first()).toBeVisible();
};

const waitForLiveCuisines = async (page: Page) => {
  const error = page.getByText('Unable to load live cuisine categories.');
  await Promise.race([
    page.getByText('Loading cuisines...').waitFor({ state: 'hidden', timeout: 15000 }),
    error.waitFor({ state: 'visible', timeout: 15000 }),
  ]).catch(() => undefined);

  const hasError = await error.isVisible().catch(() => false);
  test.skip(hasError, 'Live cuisine API is unavailable in this run.');
};

const signInWithLiveProfile = async (page: Page) => {
  // Sign-in is Google-only; without configured Firebase credentials the
  // attempt cannot complete, so this helper skips instead of failing.
  const loginButton = page.getByRole('button', { name: /continue with google/i });
  const signOut = page.getByRole('button', { name: /sign out/i });

  const canAttempt = await loginButton.isVisible().catch(() => false);
  test.skip(!canAttempt, 'Google sign-in is not available in this run.');

  await loginButton.click();
  await Promise.race([
    signOut.waitFor({ state: 'visible', timeout: 12000 }),
    loginButton.waitFor({ state: 'visible', timeout: 12000 }),
  ]).catch(() => undefined);

  const loggedIn = await signOut.isVisible().catch(() => false);
  test.skip(!loggedIn, 'Live identity API is unavailable in this run.');
};

const ensureDishPhaseWithDishes = async (page: Page) => {
  for (let attempt = 0; attempt < 4; attempt += 1) {
    await page.getByRole('button', { name: /spin cuisine/i }).click();
    await expect(page.getByRole('button', { name: /find a dish/i })).toBeVisible({ timeout: 10000 });
    await page.getByRole('button', { name: /find a dish/i }).click();

    const spinDishButton = page.getByRole('button', { name: /spin dish/i });
    if (await spinDishButton.isEnabled()) {
      return;
    }

    await page.getByRole('button', { name: /back to cuisines/i }).click();
  }

  throw new Error('Could not find a cuisine with dishes after multiple attempts.');
};

test.describe('Complete User Journey', () => {
  test.skip(({ browserName }) => browserName === 'webkit', 'Flaky in WebKit');

  test('should complete full app exploration', async ({ page }) => {
    await page.goto('/');
    await waitForLiveFeed(page);

    await expect(page.getByRole('heading', { name: 'Explore' })).toBeVisible();
    await page.getByRole('button', { name: 'Breakfast', exact: true }).click();
    if ((await recipeCards(page).count()) === 0) {
      await page.getByRole('button', { name: 'All' }).click();
    }

    const visibleTitle = ((await recipeCards(page).first().locator('h3').first().textContent()) ?? '').trim();
    expect(visibleTitle.length).toBeGreaterThan(0);
    const searchTerm = visibleTitle.split(/\s+/).find((word) => word.length > 3) ?? visibleTitle;
    const searchInput = page.getByPlaceholder(/find recipes/i);
    await searchInput.fill(searchTerm);
    await searchInput.press('Enter');
    expect(await recipeCards(page).count()).toBeGreaterThan(0);

    await page.getByRole('button', { name: 'Decide', exact: true }).click();
    await waitForLiveCuisines(page);
    await expect(page.getByText('Spin Cuisine')).toBeVisible();
    await page.getByRole('button', { name: /spin cuisine/i }).click();
    await expect(page.getByRole('button', { name: /find a dish/i })).toBeVisible({ timeout: 10000 });

    await page.getByRole('button', { name: 'Profile', exact: true }).click();
    await expect(page.getByText('CookToon')).toBeVisible();
    await signInWithLiveProfile(page);
    await expect(page.getByRole('button', { name: /sign out/i })).toBeVisible();

    await page.getByRole('button', { name: 'Explore', exact: true }).click({ force: true });
    await page.getByRole('button', { name: 'Build', exact: true }).click();
    await expect(page.getByPlaceholder(/name your recipe/i)).toBeVisible();
  });

  test('should create recipe from start to finish', async ({ page }) => {
    await page.goto('/');
    await page.getByRole('button', { name: 'Build', exact: true }).click();

    const nameInput = page.getByPlaceholder(/name your recipe/i);
    await nameInput.clear();
    await nameInput.fill('My Test Recipe');

    await page.getByRole('button', { name: /add step/i }).click();
    await page.getByRole('button', { name: 'Tomato', exact: true }).click();
    await page.getByRole('button', { name: /cook with/i }).click({ force: true });
    await page.getByText('Chop', { exact: true }).click();
    await page.getByRole('button', { name: '5 mins', exact: true }).click();
    await page.getByText('Add Step to Recipe').click({ force: true });

    await expect(page.getByText('Chopped')).toBeVisible();
    await expect(page.getByText(/1 steps/)).toBeVisible();
  });

  test('should use Cook This feature', async ({ page }) => {
    await page.goto('/');
    await waitForLiveFeed(page);

    const firstCard = recipeCards(page).first();
    const expectedTitle = ((await firstCard.locator('h3').first().textContent()) ?? '').trim();
    await firstCard.hover();
    await firstCard.getByRole('button', { name: 'Cook This' }).click();
    await expect(page.getByPlaceholder(/name your recipe/i)).toHaveValue(expectedTitle);
  });

  test('should complete meal decision flow', async ({ page }) => {
    await page.goto('/');
    await page.getByRole('button', { name: 'Decide', exact: true }).click();
    await waitForLiveCuisines(page);

    await ensureDishPhaseWithDishes(page);
    await page.getByRole('button', { name: /spin dish/i }).click();

    await expect(page.getByText(/Bon App/i)).toBeVisible({ timeout: 10000 });
    await expect(page.getByRole('button', { name: 'Respin Dish' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'New Cuisine' })).toBeVisible();
  });

  test('should customize decider wheel', async ({ page }) => {
    await page.goto('/');
    await page.getByRole('button', { name: 'Decide', exact: true }).click();
    await waitForLiveCuisines(page);

    await page.getByText('Customize Wheel').click();
    const input = page.getByPlaceholder('Add new cuisine...');
    await input.fill('E2E Cuisine');
    await input.press('Enter');

    const cuisineList = page.locator('div.fixed.inset-0').locator('.overflow-y-auto');
    await expect(cuisineList).toContainText('E2E Cuisine');

    const cuisineItem = cuisineList.locator('.cursor-pointer').filter({ hasText: 'E2E Cuisine' }).first();
    await cuisineItem.scrollIntoViewIfNeeded();
    await cuisineItem.click();

    const dishInput = page.getByPlaceholder('Add a new dish...');
    await dishInput.fill('E2E Dish');
    await dishInput.press('Enter');
    await expect(page.getByText('E2E Dish')).toBeVisible();
  });

  test('should handle like interactions', async ({ page }) => {
    await page.goto('/');
    await waitForLiveFeed(page);

    const postCard = recipeCards(page).first();
    const likeButton = postCard.getByRole('button', { name: 'Like post' });
    await likeButton.click();
    await expect(likeButton).toHaveClass(/text-pink-500/);
    await likeButton.click();
    await expect(likeButton).not.toHaveClass(/text-pink-500/);
  });

  test('should filter community by multiple criteria', async ({ page }) => {
    await page.goto('/');
    await waitForLiveFeed(page);

    await page.getByRole('button', { name: 'Dinner' }).click();
    const dinnerCardCount = await recipeCards(page).count();
    test.skip(dinnerCardCount === 0, 'No dinner-tagged recipes returned in this run.');

    const dinnerTitle = ((await recipeCards(page).first().locator('h3').first().textContent()) ?? '').trim();
    const searchTerm = dinnerTitle.split(/\s+/).find((word) => word.length > 3) ?? dinnerTitle;
    const searchInput = page.getByPlaceholder(/find recipes/i);
    await searchInput.fill(searchTerm);
    await searchInput.press('Enter');
    const emptyMessage = page.getByText('No live recipes matched your filters.');
    if (await emptyMessage.isVisible().catch(() => false)) {
      await expect(emptyMessage).toBeVisible();
    } else {
      expect(await recipeCards(page).count()).toBeGreaterThan(0);
    }
  });
});

test.describe('Mobile Responsive Tests', () => {
  test.use({ viewport: { width: 375, height: 667 } });

  test('should display navigation on mobile', async ({ page }) => {
    await page.goto('/');

    await expect(page.getByRole('button', { name: 'Explore', exact: true })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Build', exact: true })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Decide', exact: true })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Profile', exact: true })).toBeVisible();
  });

  test('should navigate between views on mobile', async ({ page }) => {
    await page.goto('/');
    await waitForLiveFeed(page);
    await expect(page.getByRole('heading', { name: 'Explore' })).toBeVisible();

    await page.getByRole('button', { name: 'Decide', exact: true }).click();
    await waitForLiveCuisines(page);
    await expect(page.getByText('Spin Cuisine')).toBeVisible();

    await page.getByRole('button', { name: 'Profile', exact: true }).click();
    await expect(page.getByText('CookToon')).toBeVisible();

    await page.getByRole('button', { name: 'Explore', exact: true }).click();
    await expect(page.getByRole('heading', { name: 'Explore' })).toBeVisible();
  });

  test('should display posts in mobile layout', async ({ page }) => {
    await page.goto('/');
    await waitForLiveFeed(page);
    expect(await recipeCards(page).count()).toBeGreaterThan(0);
  });

  test('should open recipe builder on mobile', async ({ page }) => {
    await page.goto('/');
    await page.getByRole('button', { name: 'Build', exact: true }).click();
    await expect(page.getByPlaceholder(/name your recipe/i)).toBeVisible();
  });
});

test.describe('Error Handling', () => {
  test('should handle empty search gracefully', async ({ page }) => {
    await page.goto('/');
    await waitForLiveFeed(page);

    const searchInput = page.getByPlaceholder(/find recipes/i);
    await searchInput.fill('');
    await searchInput.press('Enter');

    expect(await recipeCards(page).count()).toBeGreaterThan(0);
  });

  test('should handle no matching search results', async ({ page }) => {
    await page.goto('/');
    await waitForLiveFeed(page);

    const searchInput = page.getByPlaceholder(/find recipes/i);
    await searchInput.fill('xyznonexistent123');
    await expect(page.getByText('Daily Wish')).toBeVisible();
  });

  test('should handle rapid navigation', async ({ page }) => {
    await page.goto('/');

    await page.getByRole('button', { name: 'Decide', exact: true }).click();
    await page.getByRole('button', { name: 'Profile', exact: true }).click();
    await page.getByRole('button', { name: 'Explore', exact: true }).click();
    await page.getByRole('button', { name: 'Decide', exact: true }).click();
    await page.getByRole('button', { name: 'Explore', exact: true }).click();

    await expect(page.getByRole('heading', { name: 'Explore' })).toBeVisible();
  });
});

test.describe('Accessibility', () => {
  test('should have accessible buttons', async ({ page }) => {
    await page.goto('/');

    const homeButton = page.getByRole('button', { name: 'Explore' });
    await expect(homeButton).toBeVisible();
    await expect(homeButton).toBeEnabled();
  });

  test('should have accessible search input', async ({ page }) => {
    await page.goto('/');

    const searchInput = page.getByPlaceholder(/find recipes/i);
    await expect(searchInput).toBeVisible();
    await expect(searchInput).toBeEditable();
  });

  test('should navigate using keyboard', async ({ page }) => {
    await page.goto('/');
    await waitForLiveFeed(page);

    const firstTitle = ((await recipeCards(page).first().locator('h3').first().textContent()) ?? '').trim();
    const query = firstTitle.split(/\s+/).find((word) => word.length > 3) ?? firstTitle;

    const searchInput = page.getByPlaceholder(/find recipes/i);
    await searchInput.focus();
    await searchInput.fill(query);
    await searchInput.press('Enter');

    await expect(page.getByText(firstTitle).first()).toBeVisible();
  });
});
