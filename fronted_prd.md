
---

## 📄 Frontend PRD (`frontend-prd.md`)

```markdown
# TeamSync - Frontend PRD
## Real-Time Async Standup Tool for Remote Teams

---

## 1. Overview

### 1.1 Product Summary
TeamSync frontend is a modern, responsive web application built with Next.js and TypeScript. It provides an intuitive interface for remote teams to manage asynchronous standups across multiple timezones with real-time collaboration features.

### 1.2 Design Principles
- **Timezone-first:** Every time display respects user's local timezone
- **Real-time feel:** Instant updates without page refreshes
- **Minimal friction:** Submit standups in under 60 seconds
- **Dark mode default:** Easy on the eyes for developers working late

### 1.3 Tech Stack
- **Framework:** Next.js 14 (App Router)
- **Language:** TypeScript 5+
- **Styling:** Tailwind CSS 3.4
- **UI Components:** shadcn/ui + Radix UI primitives
- **State Management:** Zustand (global) + React Query (server)
- **Real-time:** Action Cable client (@rails/actioncable)
- **Forms:** React Hook Form + Zod validation
- **Testing:** Vitest + React Testing Library + Playwright
- **Icons:** Lucide React
- **Date/Time:** date-fns-tz (timezone-aware)

---

## 2. Architecture

### 2.1 Project Structure
src/
├── app/                    # Next.js App Router
│   ├── (auth)/            # Auth group (login, signup)
│   ├── (dashboard)/       # Main app group
│   │   ├── teams/
│   │   ├── standups/
│   │   └── settings/
│   ├── api/               # API routes (proxies)
│   └── layout.tsx
├── components/
│   ├── ui/                # shadcn components
│   ├── forms/             # Form components
│   ├── standups/          # Standup-specific
│   ├── teams/             # Team-specific
│   └── layout/            # Layout components
├── hooks/                 # Custom React hooks
├── lib/                   # Utilities, API clients
├── stores/                # Zustand stores
├── types/                 # TypeScript definitions
└── styles/                # Global styles


### 2.2 State Management

**Zustand Stores:**
- `useAuthStore` - User session, JWT tokens
- `useTeamStore` - Current team, team list
- `useStandupStore` - Current standup, draft state
- `useNotificationStore` - Toast notifications

**React Query:**
- Server state caching
- Optimistic updates
- Background refetching
- Infinite scroll for standup history

---

## 3. Page Specifications

### 3.1 Authentication Pages

#### Login (`/login`)
**Layout:** Centered card, dark gradient background

**Components:**
- Email/password inputs with validation
- "Remember me" checkbox
- "Forgot password" link
- Sign up CTA

**States:**
- Loading (button spinner)
- Error (inline validation + toast)
- Success (redirect to dashboard)

```typescript
// Validation schema
const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  rememberMe: z.boolean().default(false)
});

Sign Up (/signup)
Additional Fields:
First/Last name
Timezone selector (auto-detect, dropdown fallback)
Password strength indicator
Terms acceptance
3.2 Dashboard Layout (/(dashboard))
Structure:
┌─────────────────────────────────────────────────────┐
│  Sidebar        │  Header (team switcher, notifs)   │
│  - Teams        ├───────────────────────────────────┤
│  - Today        │                                   │
│  - History      │  Main Content Area                │
│  - Settings     │                                   │
│                 │                                   │
└─────────────────┴───────────────────────────────────┘

Responsive Behavior:
Desktop: Fixed sidebar (240px)
Tablet: Collapsible sidebar
Mobile: Bottom navigation

Sidebar Component
interface SidebarProps {
  teams: Team[];
  activeTeam: Team | null;
  onTeamSwitch: (teamId: string) => void;
  standupStatus: 'pending' | 'submitted' | 'overdue';
}


3.3 Today Page (/today) ⭐ PRIMARY PAGE
Purpose: Main interface for submitting today's standup
Layout:
Left column (60%): Standup editor
Right column (40%): Team activity feed
Standup Editor:
┌─────────────────────────────────────┐
│  ⏰ Due in 2 hours (9:00 PM WIB)   │
├─────────────────────────────────────┤
│  Yesterday                          │
│  ┌───────────────────────────────┐ │
│  │ What did you accomplish       │ │
│  │ yesterday?                    │ │
│  │                               │ │
│  └───────────────────────────────┘ │
│                                     │
│  Today                              │
│  ┌───────────────────────────────┐ │
│  │ What are you working on       │ │
│  │ today?                        │ │
│  │                               │ │
│  └───────────────────────────────┘ │
│                                     │
│  Blockers                           │
│  ┌───────────────────────────────┐ │
│  │ Any blockers or impediments?  │ │
│  │ (Optional)                    │ │
│  └───────────────────────────────┘ │
│                                     │
│  [Save Draft]  [Submit Standup]     │
└─────────────────────────────────────┘


Features:
Auto-save draft to localStorage (every 30 seconds)
Rich text support (markdown shortcuts)
Character counters
Keyboard shortcuts (Cmd+Enter to submit)

Real-time Activity Feed:
Live updates when teammates submit
"John just submitted their standup" notifications
Online presence indicators

3.4 Standup History (/history)
Layout: Calendar view + List view toggle
Calendar View:
Heat map showing submission consistency
Color coding: Green (submitted), Red (missed), Gray (weekend/holiday)
Click date to view details

List View:
Filterable by user, date range, status
Infinite scroll
Export to CSV button (admin only)

Standup Card Component:
interface StandupCardProps {
  standup: {
    id: string;
    user: User;
    date: string;
    status: StandupStatus;
    items: StandupItem[];
    submittedAt: string;
  };
  showActions?: boolean;
}


3.5 Team Management (/teams/[slug])
Tabs:
Overview - Stats, recent activity, quick actions
Members - List with roles, invite functionality
Settings - Standup time, days, timezone
Integrations - Slack, webhooks (future)

Invite Modal:
Email input with multi-select
Role selector (Admin/Member)
Invite link generation
Pending invites list


3.6 Settings (/settings)
Sections:
Profile - Name, avatar, timezone, password
Notifications - Email preferences, reminder times
Appearance - Theme (light/dark/system), density
Account - Export data, delete account


4. Component Library
4.1 Custom Components
TimezoneDisplay
interface TimezoneDisplayProps {
  datetime: string | Date;
  format?: 'relative' | 'absolute' | 'time';
  showTimezone?: boolean;
  timezone?: string; // Override, defaults to user preference
}

// Usage
<TimezoneDisplay 
  datetime="2024-03-03T14:00:00Z" 
  format="relative" 
  showTimezone 
/>
// Output: "Due in 2 hours (9:00 PM WIB)"

StandupStatusBadge
type Status = 'draft' | 'submitted' | 'overdue' | 'vacation';

const statusConfig = {
  draft: { color: 'yellow', icon: 'Pencil', label: 'Draft' },
  submitted: { color: 'green', icon: 'CheckCircle', label: 'Submitted' },
  overdue: { color: 'red', icon: 'AlertCircle', label: 'Overdue' },
  vacation: { color: 'blue', icon: 'PalmTree', label: 'Vacation' }
};


RealTimeIndicator
Pulsing dot when WebSocket connected
Tooltip showing connection status
Auto-reconnect with exponential backoff

4.2 Form Components
StandupForm
interface StandupFormData {
  yesterday: string;
  today: string;
  blockers?: string;
}

const schema = z.object({
  yesterday: z.string().min(10, 'Please provide more details'),
  today: z.string().min(10, 'What are you working on today?'),
  blockers: z.string().optional()
});


5. Real-Time Implementation
5.1 WebSocket Hook
// hooks/useStandupChannel.ts
export const useStandupChannel = (teamId: string) => {
  const { addStandup, updateStandup } = useStandupStore();
  
  useEffect(() => {
    const cable = createConsumer(process.env.NEXT_PUBLIC_WS_URL);
    const channel = cable.subscriptions.create(
      { channel: 'StandupChannel', team_id: teamId },
      {
        received: (data: WebSocketPayload) => {
          switch (data.type) {
            case 'standup_submitted':
              addStandup(data.data);
              toast.success(`${data.data.user.name} submitted their standup`);
              break;
            case 'standup_updated':
              updateStandup(data.data);
              break;
          }
        }
      }
    );
    
    return () => channel.unsubscribe();
  }, [teamId]);
};

5.2 Optimistic Updates
// React Query mutation with optimistic update
const submitStandup = useMutation({
  mutationFn: api.standups.submit,
  onMutate: async (newStandup) => {
    // Cancel outgoing refetches
    await queryClient.cancelQueries(['standups', 'today']);
    
    // Snapshot previous value
    const previous = queryClient.getQueryData(['standups', 'today']);
    
    // Optimistically update
    queryClient.setQueryData(['standups', 'today'], (old) => ({
      ...old,
      status: 'submitted',
      ...newStandup
    }));
    
    return { previous };
  },
  onError: (err, newStandup, context) => {
    // Rollback on error
    queryClient.setQueryData(['standups', 'today'], context?.previous);
    toast.error('Failed to submit standup');
  },
  onSettled: () => {
    // Refetch after error or success
    queryClient.invalidateQueries(['standups', 'today']);
  }
});


6.3 Responsive Breakpoints
Mobile: < 640px (bottom nav, single column)
Tablet: 640px - 1024px (collapsible sidebar)
Desktop: > 1024px (full sidebar, two-column layouts)


