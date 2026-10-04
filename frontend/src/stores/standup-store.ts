import { create } from 'zustand';
import { Standup, StandupFormData, StandupStatus } from '@/types';
import { api } from '@/lib/api';

interface StandupState {
  standups: Standup[];
  todayStandup: Standup | null;
  currentStandup: Standup | null;
  draft: StandupFormData;
  isLoading: boolean;
  error: string | null;
  
  setDraft: (draft: Partial<StandupFormData>) => void;
  clearDraft: () => void;
  fetchStandups: (teamSlug: string, params?: Record<string, string>) => Promise<void>;
  fetchTodayStandup: (teamSlug: string) => Promise<void>;
  fetchStandup: (teamSlug: string, standupId: string) => Promise<void>;
  createStandup: (teamSlug: string, data: StandupFormData & { submit?: boolean }) => Promise<void>;
  updateStandup: (teamSlug: string, standupId: string, data: Partial<StandupFormData> & { submit?: boolean }) => Promise<void>;
  deleteStandup: (teamSlug: string, standupId: string) => Promise<void>;
  updateStandupStatus: (standupId: string, status: StandupStatus) => void;
  addStandup: (standup: Standup) => void;
  clearError: () => void;
}

const defaultDraft: StandupFormData = {
  yesterday: '',
  today: '',
  blockers: '',
};

export const useStandupStore = create<StandupState>()((set, get) => ({
  standups: [],
  todayStandup: null,
  currentStandup: null,
  draft: { ...defaultDraft },
  isLoading: false,
  error: null,

  setDraft: (draft) => {
    set((state) => ({
      draft: { ...state.draft, ...draft },
    }));
    localStorage.setItem('standup_draft', JSON.stringify({ ...get().draft, ...draft }));
  },

  clearDraft: () => {
    set({ draft: { ...defaultDraft } });
    localStorage.removeItem('standup_draft');
  },

  fetchStandups: async (teamSlug, params) => {
    set({ isLoading: true, error: null });
    try {
      const response = await api.getStandups(teamSlug, params);
      set({ 
        standups: response.data, 
        isLoading: false 
      });
    } catch (error) {
      set({ 
        isLoading: false, 
        error: error instanceof Error ? error.message : 'Failed to fetch standups' 
      });
    }
  },

  fetchTodayStandup: async (teamSlug) => {
    set({ isLoading: true, error: null });
    try {
      const response = await api.getTodayStandup(teamSlug);
      set({ 
        todayStandup: response.data, 
        isLoading: false 
      });
      
      const standup = response.data;
      if (standup.standupItems && standup.standupItems.length > 0) {
        const draft: StandupFormData = {
          yesterday: standup.standupItems.find(i => i.itemType === 'yesterday')?.content || '',
          today: standup.standupItems.find(i => i.itemType === 'today')?.content || '',
          blockers: standup.standupItems.find(i => i.itemType === 'blockers')?.content || '',
        };
        set({ draft });
      }
    } catch (error) {
      set({ 
        isLoading: false, 
        error: error instanceof Error ? error.message : 'Failed to fetch today standup' 
      });
    }
  },

  fetchStandup: async (teamSlug, standupId) => {
    set({ isLoading: true, error: null });
    try {
      const response = await api.getStandup(teamSlug, standupId);
      set({ 
        currentStandup: response.data, 
        isLoading: false 
      });
    } catch (error) {
      set({ 
        isLoading: false, 
        error: error instanceof Error ? error.message : 'Failed to fetch standup' 
      });
    }
  },

  createStandup: async (teamSlug, data) => {
    set({ isLoading: true, error: null });
    try {
      const response = await api.createStandup(teamSlug, data);
      const newStandup = response.data;
      
      set((state) => ({
        standups: [newStandup, ...state.standups],
        todayStandup: newStandup.standupDate === new Date().toISOString().split('T')[0] 
          ? newStandup 
          : state.todayStandup,
        isLoading: false,
      }));
      
      if (data.submit) {
        get().clearDraft();
      }
    } catch (error) {
      set({ 
        isLoading: false, 
        error: error instanceof Error ? error.message : 'Failed to create standup' 
      });
      throw error;
    }
  },

  updateStandup: async (teamSlug, standupId, data) => {
    set({ isLoading: true, error: null });
    try {
      const response = await api.updateStandup(teamSlug, standupId, data);
      const updatedStandup = response.data;
      
      set((state) => ({
        standups: state.standups.map((s) =>
          s.id === standupId ? updatedStandup : s
        ),
        todayStandup: state.todayStandup?.id === standupId 
          ? updatedStandup 
          : state.todayStandup,
        currentStandup: state.currentStandup?.id === standupId
          ? updatedStandup
          : state.currentStandup,
        isLoading: false,
      }));
      
      if (data.submit) {
        get().clearDraft();
      }
    } catch (error) {
      set({ 
        isLoading: false, 
        error: error instanceof Error ? error.message : 'Failed to update standup' 
      });
      throw error;
    }
  },

  deleteStandup: async (teamSlug, standupId) => {
    set({ isLoading: true, error: null });
    try {
      await api.deleteStandup(teamSlug, standupId);
      set((state) => ({
        standups: state.standups.filter((s) => s.id !== standupId),
        todayStandup: state.todayStandup?.id === standupId 
          ? null 
          : state.todayStandup,
        currentStandup: state.currentStandup?.id === standupId
          ? null
          : state.currentStandup,
        isLoading: false,
      }));
    } catch (error) {
      set({ 
        isLoading: false, 
        error: error instanceof Error ? error.message : 'Failed to delete standup' 
      });
      throw error;
    }
  },

  updateStandupStatus: (standupId, status) => {
    set((state) => ({
      standups: state.standups.map((s) =>
        s.id === standupId ? { ...s, status } : s
      ),
      todayStandup: state.todayStandup?.id === standupId
        ? { ...state.todayStandup, status }
        : state.todayStandup,
    }));
  },

  addStandup: (standup) => {
    set((state) => ({
      standups: [standup, ...state.standups],
    }));
  },

  clearError: () => set({ error: null }),
}));

if (typeof window !== 'undefined') {
  const savedDraft = localStorage.getItem('standup_draft');
  if (savedDraft) {
    try {
      const parsed = JSON.parse(savedDraft);
      useStandupStore.setState({ draft: parsed });
    } catch {
      localStorage.removeItem('standup_draft');
    }
  }
}
