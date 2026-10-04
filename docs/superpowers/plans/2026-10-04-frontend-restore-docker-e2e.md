# Frontend Restore + Docker + Headed E2E Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore TeamSync's frontend core, add a JSON:API deserialization boundary, seed demo data, Dockerize the stack, and replace placeholder assets with real headed-Playwright captures.

**Architecture:** The frontend translates JSON:API into camelCase app models in a single `lib/deserialize.ts` boundary used by `lib/api.ts`. Damaged pages/components are reconstructed against those models. A root Docker Compose runs db, redis, api, sidekiq, web, and an `e2e` container that drives headed Chromium under Xvfb and writes captures to `docs/assets/`.

**Tech Stack:** Next.js 14, TypeScript, Tailwind, React Query, Zustand, Vitest + Testing Library, Playwright, Rails 7.1, PostgreSQL 15, Redis 7, Docker Compose.

**Spec:** `docs/superpowers/specs/2026-10-04-frontend-restore-docker-e2e-design.md`

## Global Constraints

- Node 22; Next.js 14.1; TypeScript strict.
- A backend serializer field is snake_case in JSON:API; app models are camelCase.
- `localStorage` keys are `access_token` and `refresh_token`.
- Route params: team routes use `:slug`; nested use `:team_slug`.
- Backend enums are prefixed: `role_owner?`, `status_submitted?`, `status_active?`.
- Never fabricate captures; `docs/assets/screenshot-*.png` and `demo.gif` must come from a real run.
- Backend request specs must stay green (`bundle exec rspec`).
- No new runtime dependency without need (YAGNI).

## Review Focus

- A team with zero standups must render an empty state, not crash (`history`, `today`).
- A `standup_items` relation absent from `included` must degrade to empty, not throw.
- `meta` may be absent on some endpoints; pagination code must tolerate it.
- Auth refresh must not loop when `refresh_token` is missing.
- Headed capture must fail loudly if the API is unreachable, not write blank images.

---

### Task 1: Deserialization library

**Files:**
- Create: `frontend/src/lib/deserialize.ts`
- Test: `frontend/src/lib/deserialize.test.ts`

**Interfaces:**
- Produces:
  - `camelize(key: string): string`
  - `deserializeResource(resource: JsonApiResource, included: Map<string, any>): any`
  - `deserializeCollection(doc: JsonApiDoc): any[]`
  - `deserializeDoc(doc: JsonApiDoc): { data: any; meta?: any }`
  - `keyFor(type: string, id: string): string` (`` `${type}:${id}` ``)

- [ ] **Step 1: Write failing tests**

Assertions: `camelize("today_stats") === "todayStats"`;
`deserializeCollection` on a doc with one team resource plus an `included`
`user` resolves `createdBy.fullName`; snake_case attributes become camelCase;
`meta.current_page` becomes `meta.currentPage`; an unresolved relationship
remains `{ id, type }`.

- [ ] **Step 2: Run `npx vitest run src/lib/deserialize.test.ts`** — expect failure (module missing).

- [ ] **Step 3: Implement** `deserialize.ts` per the interfaces; build the `included` map from `doc.included` keyed by `keyFor(type, id)`; deep-resolve relationships one level.

- [ ] **Step 4: Run vitest** — expect pass.

- [ ] **Step 5: Commit** `feat(frontend): add JSON:API deserializer`.

---

### Task 2: Test tooling

**Files:**
- Modify: `frontend/package.json` (add devDependency `@testing-library/jest-dom`)

- [ ] **Step 1:** Add `@testing-library/jest-dom` to `devDependencies`.
- [ ] **Step 2:** `npm install`.
- [ ] **Step 3:** `npx vitest run` — existing + new tests pass.
- [ ] **Step 4: Commit** `chore(frontend): add jest-dom matchers`.

---

### Task 3: API boundary rewrite

**Files:**
- Modify: `frontend/src/lib/api.ts`
- Test: `frontend/src/lib/api.test.ts` (uses `axios-mock-adapter`-free approach: stub `axios.create` via module mock)

**Interfaces:**
- Produces return shapes exactly as the spec table (section 4).
- Consumes `deserializeDoc`/`deserializeCollection` from Task 1.

- [ ] **Step 1: Write failing tests** mocking `axios` so `getTeams` resolves a JSON:API doc and returns `{ data: Team[] }`; `getTodayStandup` returns `{ data: Standup }` with `standupItems`; `login` returns `{ data: User & { token, refresh_token, expires_in } }`.
- [ ] **Step 2: Run vitest** — expect failure.
- [ ] **Step 3: Implement** each method's normalization.
- [ ] **Step 4: Run vitest** — pass.
- [ ] **Step 5: Commit** `refactor(frontend): normalize JSON:API at the API boundary`.

---

### Task 4: Types and utils repair

**Files:**
- Modify: `frontend/src/types/index.ts` (make `Team.createdBy?`, `Team.todayStats?`, `Team.memberCount?`; add `id` to `PaginationMeta` mapping optional)
- Modify: `frontend/src/lib/utils.ts` (import `Team` from `@/types`)

- [ ] **Step 1:** `npx tsc --noEmit` — capture current errors.
- [ ] **Step 2:** Apply edits.
- [ ] **Step 3:** `npx tsc --noEmit` — no errors in these files.
- [ ] **Step 4: Commit** `fix(frontend): repair types and utils import`.

---

### Task 5: Backend relationship includes

**Files:**
- Modify: `backend/app/controllers/api/v1/team_members_controller.rb` (`include: [:user]`)
- Modify: `backend/app/controllers/api/v1/standups_controller.rb#index` (`include: [:user, :standup_items]`)
- Modify: `backend/app/controllers/api/v1/notifications_controller.rb#index` (`include: [:team]`)
- Test: `backend/spec/requests/teams_spec.rb` and `auth_spec.rb` (existing) plus new assertions

- [ ] **Step 1: Write failing request assertions** that `GET /teams/:slug/standups` returns an `included` array containing a `user` and `standup_items`.
- [ ] **Step 2:** `bundle exec rspec spec/requests` — expect the new assertion to fail.
- [ ] **Step 3:** Add the `include:` options and pass them through the serializers.
- [ ] **Step 4:** `bundle exec rspec` — all green.
- [ ] **Step 5: Commit** `feat(backend): include related records the frontend needs`.

---

### Task 6: Regenerate credentials

**Files:** `backend/config/credentials.yml.enc`, `backend/config/master.key` (unchanged).

- [ ] **Step 1:** Temporarily move credentials aside, boot `RAILS_ENV=development`, run `EDITOR=true bundle exec rails credentials:edit` to create a fresh file decryptable by the existing `master.key`.
- [ ] **Step 2:** `RAILS_ENV=test bundle exec rails runner "puts Rails.application.credentials"` boots without error.
- [ ] **Step 3:** `bundle exec rspec` — green.
- [ ] **Step 4: Commit** `chore(backend): make credentials consistent with master key`.

---

### Task 7: Seed demo data

**Files:** `backend/db/seeds.rb`

- [ ] **Step 1:** Write seeds creating 6 users (owner + members with the spec's timezones), `demo-team`, memberships, ~10 business days of standups with items, and admin notifications. Idempotent.
- [ ] **Step 2:** `RAILS_ENV=development bundle exec rails db:seed` twice; second run changes nothing.
- [ ] **Step 3:** `RAILS_ENV=development bundle exec rails runner "puts Team.find_by(slug: 'demo-team').standups.count"` → > 0.
- [ ] **Step 4: Commit** `feat(backend): seed multi-user standup demo data`.

---

### Task 8: Tailwind config

**Files:** `frontend/tailwind.config.ts`

- [ ] **Step 1:** Implement full shadcn config: `darkMode: ["class"]`, `content: ["./src/**/*.{ts,tsx}"]`, `theme.extend.colors` bound to the CSS variables already in `globals.css`, `borderRadius`, `keyframes`/`animation`, plugins `tailwindcss-animate`.
- [ ] **Step 2:** `npx tsc --noEmit` and `npm run build` succeed.
- [ ] **Step 3: Commit** `fix(frontend): restore tailwind config`.

---

### Task 9: Standup form

**Files:** `frontend/src/components/standups/standup-form.tsx`
**Test:** `frontend/src/components/standups/standup-form.test.tsx`

**Interfaces:**
- Consumes `useCreateStandup`, `useUpdateStandup`, `useStandupStore`.
- Renders fields `yesterday` (min 10), `today` (min 10), `blockers` (optional); buttons "Save Draft" and "Submit Standup".

- [ ] **Step 1: Failing test:** render `<StandupForm teamSlug="demo-team" />`; assert three labeled textareas and both buttons; assert validation message when submitting empty.
- [ ] **Step 2:** Run vitest — fail (fields missing).
- [ ] **Step 3:** Implement the full form and footer; disable buttons while pending.
- [ ] **Step 4:** Run vitest — pass.
- [ ] **Step 5: Commit** `fix(frontend): restore standup form`.

---

### Task 10: Today page

**Files:** `frontend/src/app/(dashboard)/today/page.tsx`

- [ ] **Step 1:** Two-column grid: left `StandupForm`; right "Your Status" (badge) and "Team Activity" (list or empty state). Keep it crash-proof when `todayStandup`/`standupItems` are absent.
- [ ] **Step 2:** `npx tsc --noEmit`; `npm run build`.
- [ ] **Step 3: Commit** `fix(frontend): restore today page layout`.

---

### Task 11: Team page

**Files:** `frontend/src/app/(dashboard)/teams/[slug]/page.tsx`

- [ ] **Step 1:** Header with name + `memberCount` + invite form; Overview stats from `todayStats` with fallbacks; Members list from `getTeamMembers` (names via included `user`) and empty state; Settings tab with name/timezone/standup time.
- [ ] **Step 2:** `npx tsc --noEmit`; `npm run build`.
- [ ] **Step 3: Commit** `fix(frontend): restore team page`.

---

### Task 12: History page (list only)

**Files:** `frontend/src/app/(dashboard)/history/page.tsx`

- [ ] **Step 1:** Remove the broken calendar branch; list standups with author, date, status badge, and an item summary; add a status filter calling `useStandups` with `status`. Empty state when none.
- [ ] **Step 2:** `npx tsc --noEmit`; `npm run build`.
- [ ] **Step 3: Commit** `fix(frontend): restore history list`.

---

### Task 13: Header and sidebar

**Files:** `frontend/src/components/layout/header.tsx`, `frontend/src/components/layout/sidebar.tsx`

- [ ] **Step 1:** Header: notification bell with unread badge (from `getNotifications` meta) and existing user menu. Sidebar: team switcher list with active state and create-team link, plus Today/History/Settings nav.
- [ ] **Step 2:** `npx tsc --noEmit`; `npm run build`.
- [ ] **Step 3: Commit** `fix(frontend): restore header and sidebar`.

---

### Task 14: Frontend image

**Files:** `frontend/Dockerfile`, `frontend/.dockerignore`

- [ ] **Step 1:** Multi-stage build: `node:22-alpine`, `npm ci`, `ARG NEXT_PUBLIC_API_URL`, `npm run build`, run `next start -p 3001`.
- [ ] **Step 2:** `docker build --build-arg NEXT_PUBLIC_API_URL=http://localhost:3000 -t teamsync-web frontend` succeeds.
- [ ] **Step 3: Commit** `build(frontend): add Dockerfile`.

---

### Task 15: Root Compose

**Files:** `docker-compose.yml` (repo root)

- [ ] **Step 1:** Define `db`, `redis`, `api` (migrate + seed + server), `sidekiq`, `web`, `e2e` with healthchecks and env from the spec.
- [ ] **Step 2:** `docker compose up -d --build db redis api web`; wait for health; `curl -fsS http://localhost:3000/health` and `curl -fsS http://localhost:3001/login`.
- [ ] **Step 3: Commit** `build: add root docker compose stack`.

---

### Task 16: Playwright config and E2E specs

**Files:** `frontend/playwright.config.ts`, `frontend/e2e/fixtures.ts`, `frontend/e2e/auth.spec.ts`, `frontend/e2e/standup.spec.ts`, `frontend/e2e/team.spec.ts`, `frontend/e2e/history.spec.ts`

- [ ] **Step 1:** Config: `testDir ./e2e`, `baseURL http://localhost:3001`, Chromium project, `trace: on-first-retry`, `video: on` for the capture project.
- [ ] **Step 2:** Write the specs (login helper; standup submit; team members; history list) using seeded credentials.
- [ ] **Step 3:** Run in the `e2e` service: `docker compose run --rm e2e xvfb-run -a npx playwright test --headed`. All pass.
- [ ] **Step 4: Commit** `test(e2e): headed playwright suite`.

---

### Task 17: Captures

**Files:** `frontend/e2e/capture.spec.ts`, `docs/assets/screenshot-*.png`, `docs/assets/demo.gif`

- [ ] **Step 1:** Add a capture project that navigates login → today → history → team and screenshots each into `/work/docs/assets/`.
- [ ] **Step 2:** Record the session; convert webm → gif with ffmpeg in the `e2e` service.
- [ ] **Step 3:** Visually verify all five assets are non-blank and show seeded data.
- [ ] **Step 4: Commit** `docs: real screenshots and demo gif`.

---

### Task 18: Verify and update docs

**Files:** `README.md`, `docs/assets/README.md`, `docs/assets/capture-screenshots.mjs` (optional removal)

- [ ] **Step 1:** `docker compose up -d --build`; backend `bundle exec rspec` → 0 failures; e2e headed suite green.
- [ ] **Step 2:** Remove the placeholder disclaimer from `README.md`; update `docs/assets/README.md` to describe the Docker/E2E regeneration path.
- [ ] **Step 3: Commit** `docs: update assets and readme after real captures`.
