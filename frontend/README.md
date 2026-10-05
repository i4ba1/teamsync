# TeamSync Frontend

Modern, responsive web application for TeamSync - a real-time asynchronous standup tool for remote teams.

## Tech Stack

- **Framework:** Next.js 14 (App Router)
- **Language:** TypeScript 5+
- **Styling:** Tailwind CSS 3.4
- **UI Components:** shadcn/ui + Radix UI primitives
- **State Management:** Zustand (global) + React Query (server)
- **Real-time:** Action Cable client (@rails/actioncable)
- **Forms:** React Hook Form + Zod validation
- **Icons:** Lucide React
- **Date/Time:** date-fns-tz (timezone-aware)

## Getting Started

### Prerequisites

- Node.js 18+ 
- npm or yarn
- Backend API running (see backend README)

### Setup

1. Install dependencies:
```bash
npm install
```

2. Copy environment file:
```bash
cp .env.example .env.local
```

3. Update `.env.local` with your backend URL:
```env
NEXT_PUBLIC_API_URL=http://localhost:3000
NEXT_PUBLIC_WS_URL=ws://localhost:3000/cable
```

4. Run development server:
```bash
npm run dev
```

5. Open [http://localhost:3001](http://localhost:3001)

## Project Structure

```
src/
├── app/                    # Next.js App Router
│   ├── (auth)/            # Auth group (login, signup)
│   ├── (dashboard)/       # Main app group
│   │   ├── today/         # Today's standup page
│   │   ├── history/       # Standup history
│   │   ├── teams/[slug]/  # Team management
│   │   └── settings/      # User settings
│   ├── layout.tsx         # Root layout
│   └── globals.css        # Global styles
├── components/
│   ├── ui/                # shadcn/ui components
│   ├── forms/             # Form components
│   ├── standups/          # Standup-specific
│   ├── teams/             # Team-specific
│   └── layout/            # Layout components
├── hooks/                 # Custom React hooks
│   ├── use-teams.ts       # Team data hooks
│   ├── use-standups.ts    # Standup data hooks
│   └── use-websocket.ts   # WebSocket hooks
├── lib/                   # Utilities
│   ├── utils.ts           # Helper functions
│   └── api.ts             # API client
├── stores/                # Zustand stores
│   ├── auth-store.ts      # Auth state
│   ├── team-store.ts      # Team state
│   └── standup-store.ts   # Standup state
└── types/                 # TypeScript definitions
    └── index.ts
```

## Key Features

### Authentication
- PASETO-based token authentication
- Automatic token refresh
- Protected routes

### Real-Time Updates
- WebSocket connection via Action Cable
- Live standup submissions
- Instant notifications
- Online presence indicators

### Standup Management
- Rich text standup editor
- Auto-save drafts to localStorage
- Submit/submitted status tracking
- History view with calendar heatmap

### Team Management
- Create and manage teams
- Invite members via email
- Role-based access (owner/admin/member)
- Standup scheduling (time + days)

## Available Scripts

```bash
# Development
npm run dev          # Start development server

# Build
npm run build        # Build for production
npm run start        # Start production server

# Testing
npm run test         # Run unit tests (Vitest)
npm run test:e2e     # Run E2E tests (Playwright)

# Code Quality
npm run lint         # Run ESLint
npm run type-check   # Run TypeScript checker
```

## Design Principles

1. **Timezone-first:** Every time display respects user's local timezone
2. **Real-time feel:** Instant updates without page refreshes
3. **Minimal friction:** Submit standups in under 60 seconds
4. **Dark mode default:** Easy on the eyes for developers working late

## Responsive Breakpoints

- **Mobile:** < 640px (bottom nav, single column)
- **Tablet:** 640px - 1024px (collapsible sidebar)
- **Desktop:** > 1024px (full sidebar, two-column layouts)

## API Integration

The frontend communicates with the Rails backend via REST API and WebSockets:

- **REST API:** All CRUD operations
- **WebSocket:** Real-time updates via Action Cable
- **Authentication:** PASETO tokens with automatic refresh

## License

MIT
