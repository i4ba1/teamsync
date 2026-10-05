# TeamSync — Developer Guide

Everything you need to set up, run, extend and test TeamSync.

---

## 1. Prerequisites

| Tool | Version |
| --- | --- |
| Ruby | 3.2.2 |
| Rails | 7.1 |
| PostgreSQL | 15+ |
| Redis | 7+ |
| Node.js | 18+ (frontend) |
| Docker + Compose | optional, for the quickest setup |

---

## 2. Backend setup

### Option A — Docker Compose (fastest)

```bash
cd backend
cp .env.example .env
# generate a PASETO secret
openssl rand -base64 32          # paste into PASETO_SECRET_KEY
docker compose up --build        # starts api + postgres + redis + sidekiq
docker compose exec api rails db:create db:migrate db:seed
```

API at `http://localhost:3000`, docs at `http://localhost:3000/api-docs`,
Sidekiq UI at `http://localhost:3000/sidekiq`.

### Option B — Local

```bash
cd backend
bundle install
cp .env.example .env             # set DATABASE_URL, REDIS_URL, PASETO_SECRET_KEY
bin/rails db:create db:migrate db:seed
redis-server                     # in a second terminal
bundle exec sidekiq              # in a third terminal
bundle exec rails server         # in a fourth terminal
```

> **Credentials note:** `config/credentials.yml.enc` must decrypt with
> `config/master.key`. If it doesn't, boot fails with
> `ActiveSupport::MessageEncryptor::InvalidMessage`. Either restore the matching
> `master.key`, regenerate credentials (`bin/rails credentials:edit`), or set a
> valid `RAILS_MASTER_KEY`. `PASETO_SECRET_KEY` is read from ENV first, so
> credentials are only needed for the Rails secret key base.

### Environment variables

| Variable | Purpose |
| --- | --- |
| `DATABASE_URL` | PostgreSQL connection |
| `REDIS_URL` | Redis for Sidekiq + cache |
| `PASETO_SECRET_KEY` | Signs access tokens (32+ bytes) |
| `SECRET_KEY_BASE` | Rails secret (ENV or credentials) |
| `FRONTEND_URL` | Allowed CORS origin |
| `ACTION_CABLE_ALLOWED_REQUEST_ORIGINS` | Comma-separated WebSocket origins |

---

## 3. Frontend setup

```bash
cd frontend
npm install
cp .env.example .env.local       # NEXT_PUBLIC_API_URL=http://localhost:3000
npm run dev                      # http://localhost:3001
```

---

## 4. Running the test suite

```bash
cd backend
bundle exec rspec                              # full suite
bundle exec rspec spec/services                # services only
bundle exec rspec spec/requests/teams_spec.rb  # one file
COVERAGE=true bundle exec rspec                # with SimpleCov
```

The suite uses RSpec, FactoryBot, Shoulda Matchers, DatabaseCleaner and
`rspec-sidekiq`. Request specs are the behavioural contract; service/repository
specs guard the domain layer.

---

## 5. The layered architecture in practice

Read `docs/ARCHITECTURE.md` for the full picture. In short:

```
Controller → Service → Repository → ActiveRecord → PostgreSQL
                  └── Contract (validate input)
                  └── Errors::*  (failure)  → rescued in ApplicationController
```

### Golden rules

1. **Controllers are thin.** Permit params, call one service, render.
2. **Services own use cases.** One public `#call`, one responsibility.
3. **Repositories own persistence.** No raw queries elsewhere.
4. **Contracts validate input.** Use `dry-validation`, raise on failure.
5. **Errors are typed.** Raise `Errors::ValidationError`, `Errors::NotFoundError`,
   `Errors::ForbiddenError`, `Errors::UnauthorizedError`.

---

## 6. Adding a new endpoint (worked example)

Say you want `POST /api/v1/teams/:slug/archive` that only owners can call.

### Step 1 — Route

```ruby
# config/routes.rb
resources :teams, param: :slug do
  member do
    post :invite
    post :join
    post :archive
  end
end
```

### Step 2 — Contract (only if the action takes input)

```ruby
# app/contracts/teams/archive_team_contract.rb
module Teams
  class ArchiveTeamContract < ApplicationContract
    params do
      optional(:reason).maybe(:string)
    end
  end
end
```

### Step 3 — Repository method (if new persistence is needed)

```ruby
# app/repositories/team_repository.rb
def archive(team, reason: nil)
  team.update!(archived_at: Time.current, archive_reason: reason)
end
```

### Step 4 — Service

```ruby
# app/services/teams/archive_team.rb
module Teams
  class ArchiveTeam < ApplicationService
    CONTRACT = ArchiveTeamContract.new

    def initialize(team:, reason: nil)
      @team = team
      @reason = reason
    end

    def call
      attrs = validate(CONTRACT, reason: @reason)
      TeamRepository.archive(@team, reason: attrs[:reason])
      @team
    end
  end
end
```

### Step 5 — Controller

```ruby
# app/controllers/api/v1/teams_controller.rb
before_action :require_team_owner!, only: [:destroy, :archive]

def archive
  team = ::Teams::ArchiveTeam.call(team: @team, reason: params[:reason])
  render json: TeamSerializer.new(team).serializable_hash
end
```

### Step 6 — Specs

```ruby
# spec/services/teams/archive_team_spec.rb
RSpec.describe Teams::ArchiveTeam do
  it "archives the team" do
    team = create(:team)
    described_class.call(team: team, reason: "done")
    expect(team.reload.archived_at).to be_present
  end
end
```

---

## 7. Code conventions

- **Naming** — services are verb phrases (`CreateTeam`, `InviteMember`,
  `UpsertStandup`); repositories are `<Aggregate>Repository`.
- **Enums** use `_prefix: true`; call `record.role_owner?`, `user.status_active?`,
  `standup.status_submitted?`.
- **Routes** — team member routes use `:slug`; nested routes use `:team_slug`.
  `Api::V1::BaseController#team_slug_param` resolves both.
- **Status codes** — use integer `422` (Rack 3.2 removed the
  `:unprocessable_entity` symbol).
- **Transactions** — wrap multi-step writes in `StandupRepository.transaction`
  (or the relevant repository).
- **No comments** unless they explain *why*.

---

## 8. Background jobs & scheduling

Jobs live in `app/jobs/` and delegate to a service. Recurring jobs are declared
in `config/initializers/sidekiq.rb` via `sidekiq-scheduler`.

Add a job:

```ruby
class WeeklyDigestJob < ApplicationJob
  queue_as :default

  def perform
    Standups::BuildWeeklyDigest.call
  end
end
```

Test a job inline in specs with the Sidekiq test mode already configured.

---

## 9. Real-time

- Channels: `StandupChannel`, `NotificationChannel`, `PresenceChannel`.
- Broadcast helpers are class methods (e.g.
  `StandupChannel.broadcast_standup_update(standup)`).
- Presence uses the shared `TEAMSYNC_REDIS` connection
  (`config/initializers/redis.rb`).
- Client URL: `NEXT_PUBLIC_WS_URL=ws://localhost:3000/cable`.

---

## 10. API documentation

Swagger UI is mounted at `/api-docs` via rswag. Specs/definitions live in
`swagger/`. Update them when you change a request/response contract.

---

## 11. Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| `MessageEncryptor::InvalidMessage` | `master.key` doesn't match `credentials.yml.enc`; restore/regenerate. |
| `Could not open library 'sodium'` | install `libsodium-dev` (PASETO uses Ed25519 via rbnacl). |
| `unknown keyword: quirks_mode` | `json 3.x` with Rails 7.1; keep `json < 3.0`. |
| `paseto 0.1.0 no longer found` | yanked from RubyGems; use `~> 0.4`. |
| `Invalid HTTP status: :unprocessable_entity` | Rack 3.2 renamed it; use `422`. |
| `uninitialized constant Errors` | error files must live under a namespace dir, e.g. `app/services/errors/`. |
| Standup predicate `undefined method submitted?` | prefixed enum → use `status_submitted?`. |
| `PG::DuplicateTable` on migrate | `t.references` already indexes; don't add a duplicate `add_index`. |

---

## 12. Useful commands

```bash
bin/rails routes                 # inspect routes and param names
bin/rails db:migrate db:seed     # migrate + seed
bin/rails runner "..."           # run code in app context
bundle exec rubocop              # lint (add a .rubocop.yml first)
```

---

## 13. Further reading

- [`ARCHITECTURE.md`](./ARCHITECTURE.md) — object flow, diagrams, layer rules.
- [`USER_GUIDE.md`](./USER_GUIDE.md) — end-user documentation.
- [`../backend/README.md`](../backend/README.md) — backend reference.
- [`../frontend/README.md`](../frontend/README.md) — frontend reference.
