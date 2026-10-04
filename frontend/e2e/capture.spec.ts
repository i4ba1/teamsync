import { test, Page } from '@playwright/test';
import path from 'path';
import { login } from './fixtures';

const CAPTURE_DIR = process.env.CAPTURE_DIR || '/work/output';

async function shot(page: Page, name: string): Promise<void> {
  await page.screenshot({ path: path.join(CAPTURE_DIR, name), fullPage: true });
}

test('captures product screenshots', async ({ page }) => {
  await page.goto('/login');
  await shot(page, 'screenshot-login.png');

  await login(page);
  await page.waitForTimeout(1500);
  await shot(page, 'screenshot-today.png');

  await page.goto('/history');
  await expectReady(page);
  await shot(page, 'screenshot-history.png');

  await page.goto('/teams/demo-team');
  await expectReady(page);
  await page.getByRole('tab', { name: /members/i }).click();
  await page.waitForTimeout(800);
  await shot(page, 'screenshot-team.png');
});

async function expectReady(page: Page): Promise<void> {
  await page.waitForLoadState('networkidle').catch(() => {});
  await page.waitForTimeout(800);
}
