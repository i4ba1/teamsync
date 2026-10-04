import { test, expect } from '@playwright/test';
import { login } from './fixtures';

test('lists submitted standups in history', async ({ page }) => {
  await login(page);

  await page.goto('/history');
  await expect(page.getByRole('heading', { name: 'History' })).toBeVisible();
  await expect(page.getByText('Yesterday:').first()).toBeVisible({ timeout: 15_000 });
});
