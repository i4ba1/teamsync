import { test, expect } from '@playwright/test';
import { login } from './fixtures';

test('shows the team and its members', async ({ page }) => {
  await login(page);

  await page.goto('/teams/demo-team');
  await expect(page.getByRole('heading', { name: 'Demo Team' })).toBeVisible();

  await page.getByRole('tab', { name: /members/i }).click();
  await expect(page.getByText('Grace Hopper')).toBeVisible();
  await expect(page.getByText('Ada Lovelace')).toBeVisible();
});
