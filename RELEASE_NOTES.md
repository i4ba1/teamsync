# TeamSync v1.0.0

Real-time asynchronous standups for remote, multi-timezone teams.

## Highlights

- **Async standups** — write yesterday / today / blockers / notes; save as a draft or submit.
- **Timezone-first** — every time renders in the viewer's timezone.
- **Real-time** — standups, notifications and presence stream over Action Cable.
- **Teams & roles** — owner / admin / member, invite by email.
- **Standup history** — filterable list by date, member and status.
- **Scheduled jobs** — standup reminders, missed-standup marking, daily summaries, token cleanup.
- **PASETO auth** — stateless access tokens with rotating refresh tokens.
- **Dockerized** — db, redis, api, sidekiq, web, and a headed Playwright E2E service.

## Backend

- Rails 7.1 API with explicit **Controller → Service → Repository** layers.
- `dry-validation` contracts, typed `Errors::*` mapped centrally to HTTP status.
- PostgreSQL 15 (UUID keys), Sidekiq + sidekiq-scheduler, Redis.
- Idempotent seed data (demo team, 6 members, ~10 business days of standups).
- RSpec suite: request + service + repository + contract specs.

## Frontend

- Next.js 14 (App Router), TypeScript, Tailwind, Radix UI.
- Zustand (client state) + React Query (server state).
- JSON:API → camelCase deserialization boundary.
- Login, Today (standup editor), History, Team management, Settings.

## Verification

- `bundle exec rspec` → 93 examples, 0 failures
- `npx vitest run` → 19 tests
- `npx tsc --noEmit` → clean
- `next build` → 8 routes
- Headed Playwright E2E (Docker) → 6/6

## Getting started

```bash
cp .env.example .env
docker compose up -d --build
```

Web: http://localhost:3001 · API: http://localhost:13000 · Demo: `admin@teamsync.app` / `password123`
