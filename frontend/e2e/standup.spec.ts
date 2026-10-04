import { test, expect } from '@playwright/test';
import { login } from './fixtures';

test('writes and submits a standup', async ({ page }) => {
  await login(page);

  await page.fill('#yesterday', 'Fixed the login bug and deployed to staging');
  await page.fill('#today', 'Writing end to end tests for the standup flow');
  await page.fill('#blockers', 'None right now');

  await page.getByRole('button', { name: /submit standup/i }).click();

  await expect(page.getByText('Submitted').first()).toBeVisible({ timeout: 15_000 });
});
