import axios, { AxiosError, AxiosInstance, AxiosRequestConfig } from 'axios';
import {
  AuthTokens,
  User,
  Team,
  TeamMembership,
  Standup,
  Notification,
  LoginCredentials,
  SignupData,
  PaginationMeta,
  StandupFormData,
} from '@/types';
import { camelize, deserializeCollection, deserializeDoc, underscoreKeys } from '@/lib/deserialize';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

type AuthUser = User & { token: string; refresh_token: string; expires_in: number };

function camelizeObject(input: Record<string, unknown>): Record<string, unknown> {
  const result: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(input)) {
    result[camelize(key)] = value;
  }
  return result;
}

function normalizeAuth(body: { data?: Record<string, unknown> }): { data: AuthUser } {
  const { token, refresh_token, expires_in, ...attributes } = (body?.data ?? {}) as Record<string, unknown>;
  return {
    data: { ...camelizeObject(attributes), token, refresh_token, expires_in } as unknown as AuthUser,
  };
}

class ApiClient {
  private client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: `${API_URL}/api/v1`,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    this.setupInterceptors();
  }

  private setupInterceptors() {
    this.client.interceptors.request.use(
      (config) => {
        const token = localStorage.getItem('access_token');
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      (error) => Promise.reject(error),
    );

    this.client.interceptors.response.use(
      (response) => response,
      async (error: AxiosError) => {
        const originalRequest = error.config as AxiosRequestConfig & { _retry?: boolean };

        if (error.response?.status === 401 && !originalRequest._retry) {
          originalRequest._retry = true;

          try {
            const refreshToken = localStorage.getItem('refresh_token');
            if (!refreshToken) {
              throw new Error('No refresh token');
            }

            const response = await axios.post(`${this.client.defaults.baseURL}/auth/refresh`, {
              refresh_token: refreshToken,
            });

            const { token, refresh_token } = response.data;
            localStorage.setItem('access_token', token);
            localStorage.setItem('refresh_token', refresh_token);

            if (originalRequest.headers) {
              originalRequest.headers.Authorization = `Bearer ${token}`;
            }

            return this.client(originalRequest);
          } catch (refreshError) {
            localStorage.removeItem('access_token');
            localStorage.removeItem('refresh_token');
            if (window.location.pathname !== '/login') {
              window.location.href = '/login';
            }
            return Promise.reject(refreshError);
          }
        }

        return Promise.reject(error);
      },
    );
  }

  async login(credentials: LoginCredentials): Promise<{ data: AuthUser }> {
    const response = await this.client.post('/auth/login', credentials);
    return normalizeAuth(response.data);
  }

  async signup(data: SignupData): Promise<{ data: AuthUser }> {
    const response = await this.client.post('/auth/signup', { user: underscoreKeys(data as unknown as Record<string, unknown>) });
    return normalizeAuth(response.data);
  }

  async logout(): Promise<void> {
    const refreshToken = localStorage.getItem('refresh_token');
    await this.client.delete('/auth/logout', {
      data: { refresh_token: refreshToken },
    });
    localStorage.removeItem('access_token');
    localStorage.removeItem('refresh_token');
  }

  async getCurrentUser(): Promise<{ data: User }> {
    const response = await this.client.get('/auth/me');
    return normalizeAuth(response.data) as unknown as { data: User };
  }

  async updateProfile(data: Partial<User>): Promise<{ data: User }> {
    const response = await this.client.put('/auth/me', {
      user: underscoreKeys(data as unknown as Record<string, unknown>),
    });
    return normalizeAuth(response.data) as unknown as { data: User };
  }

  async getTeams(): Promise<{ data: Team[] }> {
    const response = await this.client.get('/teams');
    return { data: deserializeCollection(response.data) as unknown as Team[] };
  }

  async getTeam(slug: string): Promise<{ data: Team }> {
    const response = await this.client.get(`/teams/${slug}`);
    return { data: deserializeDoc(response.data).data as Team };
  }

  async createTeam(data: Partial<Team>): Promise<{ data: Team }> {
    const response = await this.client.post('/teams', {
      team: underscoreKeys(data as unknown as Record<string, unknown>),
    });
    return { data: deserializeDoc(response.data).data as Team };
  }

  async updateTeam(slug: string, data: Partial<Team>): Promise<{ data: Team }> {
    const response = await this.client.put(`/teams/${slug}`, {
      team: underscoreKeys(data as unknown as Record<string, unknown>),
    });
    return { data: deserializeDoc(response.data).data as Team };
  }

  async deleteTeam(slug: string): Promise<void> {
    await this.client.delete(`/teams/${slug}`);
  }

  async inviteMember(teamSlug: string, email: string, role?: string): Promise<void> {
    await this.client.post(`/teams/${teamSlug}/invite`, { email, role });
  }

  async joinTeam(slug: string, inviteCode: string): Promise<{ data: Team }> {
    const response = await this.client.post(`/teams/${slug}/join`, { invite_code: inviteCode });
    return { data: deserializeDoc(response.data).data as Team };
  }

  async getTeamMembers(teamSlug: string): Promise<{ data: TeamMembership[] }> {
    const response = await this.client.get(`/teams/${teamSlug}/members`);
    return { data: deserializeCollection(response.data) as unknown as TeamMembership[] };
  }

  async removeTeamMember(teamSlug: string, userId: string): Promise<void> {
    await this.client.delete(`/teams/${teamSlug}/members/${userId}`);
  }

  async updateMemberRole(teamSlug: string, userId: string, role: string): Promise<void> {
    await this.client.patch(`/teams/${teamSlug}/members/${userId}/update_role`, { role });
  }

  async getStandups(
    teamSlug: string,
    params?: Record<string, string>,
  ): Promise<{ data: Standup[]; meta: PaginationMeta }> {
    const response = await this.client.get(`/teams/${teamSlug}/standups`, { params });
    const { data, meta } = deserializeDoc(response.data);
    return { data: data as Standup[], meta: (meta ?? {}) as unknown as PaginationMeta };
  }

  async getTodayStandup(teamSlug: string): Promise<{ data: Standup }> {
    const response = await this.client.get(`/teams/${teamSlug}/standups/today`);
    return { data: deserializeDoc(response.data).data as Standup };
  }

  async getStandup(teamSlug: string, standupId: string): Promise<{ data: Standup }> {
    const response = await this.client.get(`/teams/${teamSlug}/standups/${standupId}`);
    return { data: deserializeDoc(response.data).data as Standup };
  }

  async createStandup(teamSlug: string, data: StandupFormData & { submit?: boolean }): Promise<{ data: Standup }> {
    const response = await this.client.post(`/teams/${teamSlug}/standups`, {
      items: [
        { item_type: 'yesterday', content: data.yesterday },
        { item_type: 'today', content: data.today },
        { item_type: 'blockers', content: data.blockers || '' },
      ],
      submit: data.submit,
    });
    return { data: deserializeDoc(response.data).data as Standup };
  }

  async updateStandup(
    teamSlug: string,
    standupId: string,
    data: Partial<StandupFormData> & { submit?: boolean },
  ): Promise<{ data: Standup }> {
    const items = [];
    if (data.yesterday !== undefined) {
      items.push({ item_type: 'yesterday', content: data.yesterday });
    }
    if (data.today !== undefined) {
      items.push({ item_type: 'today', content: data.today });
    }
    if (data.blockers !== undefined) {
      items.push({ item_type: 'blockers', content: data.blockers });
    }

    const response = await this.client.put(`/teams/${teamSlug}/standups/${standupId}`, {
      items: items.length > 0 ? items : undefined,
      submit: data.submit,
    });
    return { data: deserializeDoc(response.data).data as Standup };
  }

  async deleteStandup(teamSlug: string, standupId: string): Promise<void> {
    await this.client.delete(`/teams/${teamSlug}/standups/${standupId}`);
  }

  async getNotifications(params?: {
    unread?: boolean;
    page?: number;
  }): Promise<{ data: Notification[]; meta: { unreadCount?: number; pagination?: PaginationMeta } }> {
    const response = await this.client.get('/notifications', { params });
    const { data, meta } = deserializeDoc(response.data);
    return {
      data: data as Notification[],
      meta: (meta ?? {}) as { unreadCount?: number; pagination?: PaginationMeta },
    };
  }

  async getNotification(id: string): Promise<{ data: Notification }> {
    const response = await this.client.get(`/notifications/${id}`);
    return { data: deserializeDoc(response.data).data as Notification };
  }

  async markNotificationAsRead(id: string): Promise<{ data: Notification }> {
    const response = await this.client.patch(`/notifications/${id}`, { read: true });
    return { data: deserializeDoc(response.data).data as Notification };
  }

  async markAllNotificationsAsRead(): Promise<void> {
    await this.client.post('/notifications/mark_all_read');
  }
}

export const api = new ApiClient();
