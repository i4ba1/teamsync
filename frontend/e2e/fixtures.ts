import { Page } from '@playwright/test';

export const DEMO_EMAIL = process.env.DEMO_EMAIL || 'admin@teamsync.app';
export const DEMO_PASSWORD = process.env.DEMO_PASSWORD || 'password123';

export async function login(
  page: Page,
  email: string = DEMO_EMAIL,
  password: string = DEMO_PASSWORD,
): Promise<void> {
  await page.goto('/login');
  await page.fill('#email', email);
  await page.fill('#password', password);
  await page.click('button[type="submit"]');
  await page.waitForURL('**/today', { timeout: 20_000 });
}
