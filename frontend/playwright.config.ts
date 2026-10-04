import { defineConfig, devices } from "@playwright/test";

const baseURL = process.env.APP_URL || "http://localhost:3001";

// When running against an already-running stack (Docker), set
// PLAYWRIGHT_NO_SERVER=1 to skip the managed dev server.
const useManagedServer = process.env.PLAYWRIGHT_NO_SERVER !== "1";

export default defineConfig({
  testDir: "./e2e",
  outputDir: process.env.PLAYWRIGHT_OUTPUT_DIR || "test-results",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: process.env.CI ? "list" : "html",
  use: {
    baseURL,
    trace: "on-first-retry",
    video: "on",
    screenshot: "only-on-failure",
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
  webServer: useManagedServer
    ? {
        command: "npm run dev",
        url: "http://localhost:3001",
        reuseExistingServer: !process.env.CI,
        timeout: 120_000,
      }
    : undefined,
});
