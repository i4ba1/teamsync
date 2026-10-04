export interface User {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  fullName: string;
  initials: string;
  timezone: string;
  avatarUrl?: string;
  status: 'active' | 'inactive' | 'suspended';
  role: 'member' | 'admin' | 'super_admin';
  createdAt: string;
}

export interface Team {
  id: string;
  name: string;
  slug: string;
  timezone: string;
  standupTime: string;
  standupDays: number[];
  settings?: TeamSettings;
  memberCount?: number;
  currentUserRole?: 'owner' | 'admin' | 'member';
  todayStats?: {
    submitted: number;
    missed: number;
    total: number;
  };
  inviteCode?: string;
  createdAt: string;
  createdBy?: User;
}

export interface TeamSettings {
  reminderEnabled?: boolean;
  reminderMinutesBefore?: number;
  allowWeekendStandups?: boolean;
}

export interface TeamMembership {
  id: string;
  role: 'owner' | 'admin' | 'member';
  joinedAt: string;
  user: User;
  team?: Team;
}

export type StandupStatus = 'draft' | 'submitted' | 'missed' | 'vacation' | 'holiday';

export interface Standup {
  id: string;
  standupDate: string;
  status: StandupStatus;
  completedAt?: string;
  editable: boolean;
  itemsSummary: Record<string, string[]>;
  user: User;
  team: Team;
  standupItems: StandupItem[];
  createdAt: string;
}

export type StandupItemType = 'yesterday' | 'today' | 'blockers' | 'notes';

export interface StandupItem {
  id: string;
  itemType: StandupItemType;
  content: string;
  sortOrder: number;
}

export interface StandupFormData {
  yesterday: string;
  today: string;
  blockers?: string;
}

export type NotificationType = 
  | 'standup_reminder' 
  | 'mention' 
  | 'team_invite' 
  | 'standup_submitted'
  | 'team_removed'
  | 'role_changed';

export interface Notification {
  id: string;
  notificationType: NotificationType;
  title: string;
  message: string;
  data: Record<string, unknown>;
  read: boolean;
  readAt?: string;
  team?: Team;
  createdAt: string;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export interface LoginCredentials {
  email: string;
  password: string;
  rememberMe?: boolean;
}

export interface SignupData {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  timezone: string;
}

export interface ApiError {
  error: string;
  message: string;
  details?: string[];
}

export interface WebSocketPayload {
  type: string;
  message?: string;
  data?: unknown;
  standup?: Standup;
  standupId?: string;
  userId?: string;
  notification?: Notification;
  count?: number;
}

export interface PaginationMeta {
  currentPage: number;
  nextPage?: number;
  prevPage?: number;
  totalPages: number;
  totalCount: number;
}

export interface PaginatedResponse<T> {
  data: T[];
  meta: PaginationMeta;
}
