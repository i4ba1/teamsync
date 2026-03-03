# TeamSync Backend

Real-time asynchronous standup tool for remote teams - Ruby on Rails API.

## Tech Stack

- **Ruby**: 3.2.2
- **Rails**: 7.1 (API mode)
- **Database**: PostgreSQL 15+
- **Cache/Queue**: Redis 7+
- **Authentication**: PASETO V4 (Public tokens)
- **Real-time**: Action Cable (Redis adapter)
- **Background Jobs**: Sidekiq
- **Testing**: RSpec, FactoryBot, Shoulda Matchers

## Getting Started

### Prerequisites

- Docker & Docker Compose
- Or: Ruby 3.2+, PostgreSQL 15+, Redis 7+

### Setup with Docker

1. Copy environment file:
```bash
cp .env.example .env
```

2. Generate a PASETO secret key:
```bash
openssl rand -base64 32
```

3. Update `.env` with your generated key:
```env
PASETO_SECRET_KEY=your-generated-key
```

4. Build and start services:
```bash
docker-compose up --build
```

5. Create database and run migrations:
```bash
docker-compose exec api rails db:create db:migrate db:seed
```

6. Access the API at `http://localhost:3000`

### Setup without Docker

1. Install dependencies:
```bash
bundle install
```

2. Setup database:
```bash
rails db:create db:migrate db:seed
```

3. Start services:
```bash
# Terminal 1: Redis
redis-server

# Terminal 2: Sidekiq
bundle exec sidekiq

# Terminal 3: Rails server
bundle exec rails server
```

## API Endpoints

### Authentication
- `POST /api/v1/auth/signup` - Register new user
- `POST /api/v1/auth/login` - Authenticate user
- `DELETE /api/v1/auth/logout` - Revoke token
- `GET /api/v1/auth/me` - Current user profile
- `PUT /api/v1/auth/me` - Update profile
- `POST /api/v1/auth/refresh` - Refresh access token

### Teams
- `GET /api/v1/teams` - List teams
- `POST /api/v1/teams` - Create team
- `GET /api/v1/teams/:slug` - Get team
- `PUT /api/v1/teams/:slug` - Update team
- `DELETE /api/v1/teams/:slug` - Delete team
- `POST /api/v1/teams/:slug/invite` - Invite member
- `POST /api/v1/teams/:slug/join` - Join via invite

### Team Members
- `GET /api/v1/teams/:team_id/members` - List members
- `DELETE /api/v1/teams/:team_id/members/:id` - Remove member
- `PATCH /api/v1/teams/:team_id/members/:id/update_role` - Update role

### Standups
- `GET /api/v1/teams/:team_id/standups` - List standups
- `GET /api/v1/teams/:team_id/standups/today` - Today's standup
- `GET /api/v1/teams/:team_id/standups/:id` - Get standup
- `POST /api/v1/teams/:team_id/standups` - Create standup
- `PUT /api/v1/teams/:team_id/standups/:id` - Update standup
- `DELETE /api/v1/teams/:team_id/standups/:id` - Delete standup

### Notifications
- `GET /api/v1/notifications` - List notifications
- `GET /api/v1/notifications/:id` - Get notification
- `PATCH /api/v1/notifications/:id` - Update notification
- `POST /api/v1/notifications/mark_all_read` - Mark all read

### WebSocket
- `ws://localhost:3000/cable` - Action Cable endpoint

## Testing

Run tests with:
```bash
bundle exec rspec
```

Run with coverage:
```bash
COVERAGE=true bundle exec rspec
```

## Background Jobs

Scheduled jobs:
- **Standup Reminder** - Sends reminders at 1h, 30m, 10m before standup time
- **Mark Missed Standups** - Daily job to mark missed standups

Access Sidekiq Web UI at: `/sidekiq`

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Next.js App   │◄────┤  Rails API       │◄────┤   PostgreSQL    │
│   (Frontend)    │     │  (PASETO Auth)   │     │   (Primary DB)  │
└─────────────────┘     └──────────────────┘     └─────────────────┘
        ▲                       │
        │                       ▼
        │              ┌──────────────────┐
        └──────────────┤   Redis          │
     WebSocket        │   (Cache/Queue/  │
                       │   Pub-Sub)       │
                       └──────────────────┘
```

## License

MIT
