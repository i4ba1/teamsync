import { test, expect } from '@playwright/test';
import { login } from './fixtures';

test('redirects unauthenticated users to the login page', async ({ page }) => {
  await page.goto('/today');
  await page.waitForURL('**/login', { timeout: 20_000 });
  await expect(page).toHaveURL(/\/login/);
});

test('logs in with seeded credentials and lands on Today', async ({ page }) => {
  await login(page);

  await expect(page).toHaveURL(/\/today/);
  await expect(page.getByText('Demo Team').first()).toBeVisible();
});
