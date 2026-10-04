# Design: Restore TeamSync frontend core, seed data, Docker, and headed E2E captures

Date: 2026-10-04
Status: Approved (plan)
Owner: engineering

## 1. Context

The repository contains a Rails 7.1 API (`backend/`, just refactored into
controller/service/repository layers, 91 specs green) and a Next.js 14 frontend
(`frontend/`). During generation, parts of the frontend were corrupted:

- Hard-broken: `tailwind.config.ts` (truncated), `playwright.config.ts`
  (truncated strings).
- Silently damaged (valid syntax, missing content, detectable via unused
  imports): `today/page.tsx`, `teams/[slug]/page.tsx`, `history/page.tsx`,
  `components/standups/standup-form.tsx`, `components/layout/header.tsx`,
  `components/layout/sidebar.tsx`, and `lib/utils.ts` (uses `Team` without
  importing it).

Additionally, the frontend never deserializes JSON:API: `lib/api.ts` returns
raw JSON:API documents while components read camelCase models, so pages render
empty even once repaired.

The README currently ships placeholder screenshots. The goal is real,
reproducible captures.

## 2. Goals

1. Restore a working frontend core (auth, dashboard shell, Today, Teams,
   History) per the "skip extras" scope.
2. Introduce a JSON:API → app-model deserialization boundary (Approach A).
3. Seed realistic demo data (multi-user, multi-day standups).
4. Dockerize db + redis + api + sidekiq + web, plus a headed Playwright `e2e`
   service.
5. Run headed Playwright E2E against the Dockerized stack and replace
   `docs/assets/screenshot-*.png` and `demo.gif` with real captures.

## 3. Non-goals

- Calendar heatmap, invite modal polish, settings sections beyond a basic form,
  presence UI, password reset, notifications inbox page.
- Production hardening beyond what already exists.
- Changing the backend architecture delivered earlier.

## 4. Architecture: the data boundary

`frontend/src/lib/deserialize.ts` owns translation from JSON:API to app types.

```ts
camelize(key: string): string
deserializeResource(resource, includedById): Record<string, unknown>
deserializeCollection(doc): Model[]
deserializeDoc(doc): { data: Model | Model[], meta?: unknown }
```

- `deserializeResource` camelizes `attributes` and resolves each
  `relationships[key].data` (object or array of `{ id, type }`) against the
  `included` lookup. Missing linkage stays as an `{ id, type }` stub.
- `meta` keys are camelized (e.g. `current_page` → `currentPage`).
- Unknown attributes pass through camelized so new serializer fields work.

`frontend/src/lib/api.ts` methods normalize at the boundary:

| Method | Returns |
| --- | --- |
| `getTeams` | `{ data: Team[] }` |
| `getTeam`, `createTeam`, `updateTeam`, `joinTeam` | `{ data: Team }` |
| `getTeamMembers` | `{ data: TeamMembership[] }` |
| `getStandups` | `{ data: Standup[], meta: PaginationMeta }` |
| `getTodayStandup`, `getStandup` | `{ data: Standup }` |
| `createStandup`, `updateStandup` | `{ data: Standup }` |
| `getNotifications`, `getNotification`, `markNotificationAsRead` | `{ data, meta? }` |
| `login`, `signup`, `getCurrentUser`, `updateProfile` | `{ data: User & token fields }` |

Auth note: the backend returns flat snake_case attributes for login/signup/me.
These are camelized to `User`; token fields (`token`, `refresh_token`,
`expires_in`) are passed through unchanged so `auth-store.setTokens` keeps
working. `User.fullName`/`initials` are derived client-side if absent.

Relationship inclusion required from the backend (small changes):

- `team_members#index` → `include: [:user]`
- `standups#index` → `include: [:user, :standup_items]`
- `notifications#index` → `include: [:team]`

## 5. File inventory

New:

- `frontend/src/lib/deserialize.ts`
- `frontend/Dockerfile`
- `frontend/.dockerignore`
- `docker-compose.yml` (repo root)
- `frontend/e2e/auth.spec.ts`, `standup.spec.ts`, `team.spec.ts`,
  `history.spec.ts`, `capture.spec.ts`
- `frontend/e2e/fixtures.ts` (shared login helper)
- `docs/superpowers/specs/` (this file), `docs/superpowers/plans/` (plan)

Modified — frontend:

- `src/lib/api.ts`, `src/lib/utils.ts`, `src/types/index.ts`
- `tailwind.config.ts`, `playwright.config.ts`
- `src/components/standups/standup-form.tsx`
- `src/components/layout/header.tsx`, `src/components/layout/sidebar.tsx`
- `src/app/(dashboard)/today/page.tsx`
- `src/app/(dashboard)/teams/[slug]/page.tsx`
- `src/app/(dashboard)/history/page.tsx`

Modified — backend:

- `app/controllers/api/v1/team_members_controller.rb`
- `app/controllers/api/v1/standups_controller.rb`
- `app/controllers/api/v1/notifications_controller.rb`
- `db/seeds.rb`
- `config/credentials.yml.enc` (regenerated against committed `master.key`)

## 6. Seed data

Idempotent `db/seeds.rb`:

- Owner: `admin@teamsync.app` / `password123`.
- Members: Grace Hopper, Alan Turing, Ada Lovelace, Margaret Hamilton,
  Linus Torvalds, with timezones `UTC`, `America/New_York`, `Europe/London`,
  `Asia/Jakarta`, `Asia/Tokyo`.
- Team `Demo Team` (`demo-team`), Mon–Fri, 09:00 `UTC`.
- Memberships: admin owner, one admin, rest members.
- ~10 business days of standups per member with `yesterday`/`today`/`blockers`
  items; statuses mixed (mostly submitted, some missed/draft); today has one
  submitted and one draft.
- A handful of notifications for the admin.

## 7. Dockerization

`docker-compose.yml` services:

- `db` — `postgres:15`, healthcheck `pg_isready`.
- `redis` — `redis:7`, healthcheck `redis-cli ping`.
- `api` — build `backend/`; command waits for db, `bin/rails db:prepare db:seed`,
  then `rails s -b 0.0.0.0`; exposes 3000.
- `sidekiq` — build `backend/`; `bundle exec sidekiq`.
- `web` — build `frontend/`; exposes 3001; `NEXT_PUBLIC_API_URL` and
  `NEXT_PUBLIC_WS_URL` point at `localhost:3000` (browser-reachable).
- `e2e` — `mcr.microsoft.com/playwright:v1.42.1-jammy`; `xvfb-run` headed run;
  depends on `web`; mounts the repo for screenshots.

Environment: `DATABASE_URL`, `REDIS_URL`, `PASETO_SECRET_KEY`,
`SECRET_KEY_BASE`, `RAILS_MASTER_KEY`.

Frontend image: multi-stage `node:22-alpine` — `npm ci`, `next build`, `next start`.
`NEXT_PUBLIC_API_URL` passed as a build arg to bake it into the client bundle.

## 8. E2E and captures

- `e2e/fixtures.ts`: `login(page, email, password)` helper.
- `auth.spec.ts`: unauthenticated `/today` redirects to `/login`; login succeeds
  and lands on `/today`.
- `standup.spec.ts`: write yesterday/today/blockers, submit, assert the
  Submitted badge; reload shows persisted content.
- `team.spec.ts`: open `/teams/demo-team`, assert member names render, open the
  Members tab.
- `history.spec.ts`: `/history` lists submitted standups.
- `capture.spec.ts`: navigate login → today → history → team, screenshot each
  into `docs/assets/`, record video, and (via ffmpeg in the runner) convert to
  `docs/assets/demo.gif`.

Headed execution: `xvfb-run -a npx playwright test --headed`.

## 9. Testing

- Backend: `bundle exec rspec` stays green after the include changes.
- Frontend: `npx tsc --noEmit` and `npm run lint` clean for touched files.
- E2E: the Playwright specs above pass against the Dockerized stack.
- Captures: screenshots and `demo.gif` visually verified.

## 10. Risks

- Corrupted files were reconstructed by inference; may need iteration against
  live API shapes.
- Headed Chromium requires a virtual display (`xvfb`), handled by the runner.
- First run downloads npm packages (~hundreds) and a Chromium build.
- Credentials regeneration changes a tracked encrypted file.

## 11. Success criteria

1. `docker compose up --build` brings the full stack up healthy.
2. `bundle exec rspec` → 0 failures.
3. Playwright E2E suite passes headed in the `e2e` service.
4. `docs/assets/screenshot-{login,today,history,team}.png` and `demo.gif` are
   real captures of the seeded app.
5. README/asset docs no longer claim screenshots are placeholders.
