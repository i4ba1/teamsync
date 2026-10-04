import { create } from 'zustand';
import { Team, TeamMembership } from '@/types';
import { api } from '@/lib/api';

interface TeamState {
  teams: Team[];
  currentTeam: Team | null;
  teamMembers: TeamMembership[];
  isLoading: boolean;
  error: string | null;
  
  setCurrentTeam: (team: Team | null) => void;
  fetchTeams: () => Promise<void>;
  fetchTeam: (slug: string) => Promise<void>;
  createTeam: (data: Partial<Team>) => Promise<Team>;
  updateTeam: (slug: string, data: Partial<Team>) => Promise<void>;
  deleteTeam: (slug: string) => Promise<void>;
  fetchTeamMembers: (slug: string) => Promise<void>;
  inviteMember: (slug: string, email: string, role?: string) => Promise<void>;
  joinTeam: (slug: string, inviteCode: string) => Promise<void>;
  removeMember: (slug: string, userId: string) => Promise<void>;
  updateMemberRole: (slug: string, userId: string, role: string) => Promise<void>;
  generateInviteCode: (slug: string) => Promise<string>;
  clearError: () => void;
}

export const useTeamStore = create<TeamState>()((set, get) => ({
  teams: [],
  currentTeam: null,
  teamMembers: [],
  isLoading: false,
  error: null,

  setCurrentTeam: (team) => set({ currentTeam: team }),

  fetchTeams: async () => {
    set({ isLoading: true, error: null });
    try {
      const response = await api.getTeams();
      set({ teams: response.data, isLoading: false });
    } catch (error) {
      set({ 
        isLoading: false, 
        error: error instanceof Error ? error.message : 'Failed to fetch teams' 
      });
    }
  },

  fetchTeam: async (slug) => {
    set({ isLoading: true, error: null });
    try {
      const response = await api.getTeam(slug);
      set({ 
        currentTeam: response.data, 
        isLoading: false 
      });
    } catch (error) {
      set({ 
        isLoading: false, 
        error: error instanceof Error ? error.message : 'Failed to fetch team' 
      });
    }
  },

  createTeam: async (data) => {
    set({ isLoading: true, error: null });
    try {
      const response = await api.createTeam(data);
      const newTeam = response.data;
      set((state) => ({ 
        teams: [...state.teams, newTeam],
        currentTeam: newTeam,
        isLoading: false 
      }));
      return newTeam;
    } catch (error) {
      set({ 
        isLoading: false, 
        error: error instanceof Error ? error.message : 'Failed to create team' 
      });
      throw error;
    }
  },

  updateTeam: async (slug, data) => {
    set({ isLoading: true, error: null });
    try {
      const response = await api.updateTeam(slug, data);
      const updatedTeam = response.data;
      set((state) => ({
        teams: state.teams.map((t) => (t.slug === slug ? updatedTeam : t)),
        currentTeam: state.currentTeam?.slug === slug ? updatedTeam : state.currentTeam,
        isLoading: false,
      }));
    } catch (error) {
      set({ 
        isLoading: false, 
        error: error instanceof Error ? error.message : 'Failed to update team' 
      });
      throw error;
    }
  },

  deleteTeam: async (slug) => {
    set({ isLoading: true, error: null });
    try {
      await api.deleteTeam(slug);
      set((state) => ({
        teams: state.teams.filter((t) => t.slug !== slug),
        currentTeam: state.currentTeam?.slug === slug ? null : state.currentTeam,
        isLoading: false,
      }));
    } catch (error) {
      set({ 
        isLoading: false, 
        error: error instanceof Error ? error.message : 'Failed to delete team' 
      });
      throw error;
    }
  },

  fetchTeamMembers: async (slug) => {
    set({ isLoading: true, error: null });
    try {
      const response = await api.getTeamMembers(slug);
      set({ 
        teamMembers: response.data as TeamMembership[], 
        isLoading: false 
      });
    } catch (error) {
      set({ 
        isLoading: false, 
        error: error instanceof Error ? error.message : 'Failed to fetch members' 
      });
    }
  },

  inviteMember: async (slug, email, role) => {
    set({ isLoading: true, error: null });
    try {
      await api.inviteMember(slug, email, role);
      set({ isLoading: false });
    } catch (error) {
      set({ 
        isLoading: false, 
        error: error instanceof Error ? error.message : 'Failed to invite member' 
      });
      throw error;
    }
  },

  joinTeam: async (slug, inviteCode) => {
    set({ isLoading: true, error: null });
    try {
      const response = await api.joinTeam(slug, inviteCode);
      const team = response.data;
      set((state) => ({
        teams: [...state.teams, team],
        currentTeam: team,
        isLoading: false,
      }));
    } catch (error) {
      set({ 
        isLoading: false, 
        error: error instanceof Error ? error.message : 'Failed to join team' 
      });
      throw error;
    }
  },

  removeMember: async (slug, userId) => {
    set({ isLoading: true, error: null });
    try {
      await api.removeTeamMember(slug, userId);
      set((state) => ({
        teamMembers: state.teamMembers.filter((m) => m.user.id !== userId),
        isLoading: false,
      }));
    } catch (error) {
      set({ 
        isLoading: false, 
        error: error instanceof Error ? error.message : 'Failed to remove member' 
      });
      throw error;
    }
  },

  updateMemberRole: async (slug, userId, role) => {
    set({ isLoading: true, error: null });
    try {
      await api.updateMemberRole(slug, userId, role);
      set((state) => ({
        teamMembers: state.teamMembers.map((m) =>
          m.user.id === userId ? { ...m, role: role as 'owner' | 'admin' | 'member' } : m
        ),
        isLoading: false,
      }));
    } catch (error) {
      set({ 
        isLoading: false, 
        error: error instanceof Error ? error.message : 'Failed to update role' 
      });
      throw error;
    }
  },

  generateInviteCode: async (slug) => {
    const code = Math.random().toString(36).substring(2, 14).toUpperCase();
    return code;
  },

  clearError: () => set({ error: null }),
}));
