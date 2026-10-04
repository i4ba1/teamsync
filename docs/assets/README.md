# docs/assets

Images referenced by the root `README.md` and the guides.

| File | What it is |
| --- | --- |
| `architecture.svg` | Backend layer/flow diagram (hand-authored) |
| `screenshot-login.png` | Login screen — real capture |
| `screenshot-today.png` | Today / standup editor — real capture |
| `screenshot-history.png` | Standup history — real capture |
| `screenshot-team.png` | Team management / members — real capture |
| `demo.gif` | Headed Playwright recording of the capture flow |

## Regenerating the screenshots and GIF

The captures come from the Dockerized stack + the headed Playwright `e2e`
container (the frontend app, not a mock).

```bash
# 1. Build and start the stack (db, redis, api, web)
docker compose up -d --build

# 2. Run the headed E2E suite + capture (screenshots -> docs/assets,
#    videos/traces -> .playwright-output)
docker compose run --rm e2e xvfb-run -a npx playwright test --headed

# 3. Convert the capture video to the README GIF
ffmpeg -y -i .playwright-output/capture-captures-product-screenshots-chromium/video.webm \
  -vf "fps=10,scale=960:-1:flags=lanczos" docs/assets/demo.gif
```

The screenshots are written by `frontend/e2e/capture.spec.ts` to
`CAPTURE_DIR` (mounted from `docs/assets`). Playwright's own `outputDir`
(videos, traces, failure shots) is written to `.playwright-output/` so it
does not wipe the committed assets.

### Notes

- The `e2e` service runs as root so it can write the bind-mounted output
  directories; `chown` them back afterwards if needed.
- Demo login: `admin@teamsync.app` / `password123` (created by
  `backend/db/seeds.rb`).
- The API is published on host port `13000` (port 3000 is commonly taken);
  the frontend is built with `NEXT_PUBLIC_API_URL=http://localhost:13000`.
