# TeamSync - Backend PRD
## Real-Time Async Standup Tool for Remote Teams

---

## 1. Overview

### 1.1 Product Summary
TeamSync backend is a Ruby on Rails API that powers a real-time asynchronous standup tool designed for international remote teams. It handles multi-timezone scheduling, real-time updates via WebSockets, and team collaboration features.

### 1.2 Target Users
- Remote software teams across multiple timezones
- Team leads managing international distributed teams
- Individual contributors who need async standup updates

### 1.3 Tech Stack
- **Framework:** Ruby on Rails 7.1 (API mode)
- **Language:** Ruby 3.2+
- **Database:** PostgreSQL 15+
- **Caching:** Redis 7+
- **Real-time:** Action Cable (Redis adapter)
- **Authentication:** Devise + JWT (devise-jwt)
- **Background Jobs:** Sidekiq
- **Testing:** RSpec, FactoryBot, Shoulda Matchers
- **Documentation:** Swagger/OpenAPI (rswag)
- **Deployment:** Docker, Fly.io/Heroku

---

## 2. System Architecture

### 2.1 High-Level Architecture

┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Next.js App   │◄────┤  Rails API       │◄────┤   PostgreSQL    │
│   (Frontend)    │     │  (This PRD)      │     │   (Primary DB)  │
└─────────────────┘     └──────────────────┘     └─────────────────┘
▲                       │
│                       ▼
│              ┌──────────────────┐
└──────────────┤   Redis          │
WebSocket │   (Cache/Queue/  │
│   Pub-Sub)       │
└──────────────────┘


### 2.2 Database Schema

#### Core Entities

**users**
```ruby
# Table: users
- id: uuid (PK)
- email: string (unique, indexed)
- encrypted_password: string
- first_name: string
- last_name: string
- timezone: string (default: 'UTC')
- avatar_url: string
- status: enum [active, inactive, suspended]
- role: enum [super_admin, admin, member]
- created_at: datetime
- updated_at: datetime

# Indexes
- index on email (unique)
- index on status


# Table: teams
- id: uuid (PK)
- name: string
- slug: string (unique, indexed)
- timezone: string (default: 'UTC') # Team default timezone
- standup_time: time (default: '09:00') # When standups are due
- standup_days: integer[] (default: [1,2,3,4,5]) # 0=Sun, 6=Sat
- created_by_id: uuid (FK → users)
- settings: jsonb (flexible team settings)
- created_at: datetime
- updated_at: datetime

# Indexes
- index on slug (unique)
- index on created_by_id


# Table: team_memberships
- id: uuid (PK)
- team_id: uuid (FK → teams)
- user_id: uuid (FK → users)
- role: enum [owner, admin, member]
- joined_at: datetime
- created_at: datetime
- updated_at: datetime

# Indexes
- index on [team_id, user_id] (unique)
- index on user_id



# Table: standups
- id: uuid (PK)
- team_id: uuid (FK → teams)
- user_id: uuid (FK → users)
- standup_date: date
- status: enum [draft, submitted, missed, vacation, holiday]
- completed_at: datetime
- created_at: datetime
- updated_at: datetime

# Indexes
- index on [team_id, standup_date]
- index on [user_id, standup_date] (unique)
- index on status


# Table: standup_items
- id: uuid (PK)
- standup_id: uuid (FK → standups)
- item_type: enum [yesterday, today, blockers, notes]
- content: text
- order: integer
- created_at: datetime
- updated_at: datetime

# Indexes
- index on standup_id
- index on [standup_id, item_type]


# Table: notifications
- id: uuid (PK)
- user_id: uuid (FK → users)
- team_id: uuid (FK → teams, nullable)
- notification_type: enum [standup_reminder, mention, team_invite, standup_submitted]
- title: string
- message: text
- data: jsonb (payload)
- read_at: datetime
- created_at: datetime

# Indexes
- index on [user_id, read_at]
- index on created_at


3. API Endpoints
3.1 Authentication (/api/v1/auth)
| Method | Endpoint   | Description          | Auth |
| ------ | ---------- | -------------------- | ---- |
| POST   | `/signup`  | Register new user    | No   |
| POST   | `/login`   | Authenticate user    | No   |
| DELETE | `/logout`  | Revoke JWT           | Yes  |
| GET    | `/me`      | Current user profile | Yes  |
| PUT    | `/me`      | Update profile       | Yes  |
| POST   | `/refresh` | Refresh JWT token    | Yes  |


// POST /api/v1/auth/signup
{
  "user": {
    "email": "john@example.com",
    "password": "SecurePass123!",
    "first_name": "John",
    "last_name": "Doe",
    "timezone": "America/New_York"
  }
}

// Response 201
{
  "data": {
    "id": "uuid",
    "email": "john@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "timezone": "America/New_York",
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiJ9..."
  }
}



3.2 Teams (/api/v1/teams)
| Method | Endpoint                   | Description          | Auth         |
| ------ | -------------------------- | -------------------- | ------------ |
| GET    | `/teams`                   | List user's teams    | Yes          |
| POST   | `/teams`                   | Create new team      | Yes          |
| GET    | `/teams/:slug`             | Get team details     | Yes (member) |
| PUT    | `/teams/:slug`             | Update team          | Yes (admin+) |
| DELETE | `/teams/:slug`             | Delete team          | Yes (owner)  |
| POST   | `/teams/:slug/invite`      | Invite member        | Yes (admin+) |
| POST   | `/teams/:slug/join`        | Join via invite code | Yes          |
| DELETE | `/teams/:slug/members/:id` | Remove member        | Yes (admin+) |


3.3 Standups (/api/v1/teams/:team_slug/standups)
| Method | Endpoint          | Description                       | Auth         |
| ------ | ----------------- | --------------------------------- | ------------ |
| GET    | `/standups`       | List team standups (with filters) | Yes (member) |
| GET    | `/standups/today` | Get today's standup status        | Yes (member) |
| GET    | `/standups/:id`   | Get standup details               | Yes (member) |
| POST   | `/standups`       | Create/submit standup             | Yes (member) |
| PUT    | `/standups/:id`   | Update standup                    | Yes (owner)  |
| DELETE | `/standups/:id`   | Delete standup                    | Yes (owner)  |


3.4 Real-time (/cable)
WebSocket endpoint for Action Cable.
Channels:

    StandupChannel - Subscribe to team standup updates
    NotificationChannel - Personal notification stream
