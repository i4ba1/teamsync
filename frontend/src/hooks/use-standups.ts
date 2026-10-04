import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '@/lib/api';
import { Standup, StandupFormData } from '@/types';

export function useStandups(teamSlug: string, params?: Record<string, string>) {
  return useQuery({
    queryKey: ['standups', teamSlug, params],
    queryFn: async () => {
      const response = await api.getStandups(teamSlug, params);
      return response;
    },
    enabled: !!teamSlug,
  });
}

export function useTodayStandup(teamSlug: string) {
  return useQuery({
    queryKey: ['standups', 'today', teamSlug],
    queryFn: async () => {
      const response = await api.getTodayStandup(teamSlug);
      return response.data;
    },
    enabled: !!teamSlug,
  });
}

export function useStandup(teamSlug: string, standupId: string) {
  return useQuery({
    queryKey: ['standups', teamSlug, standupId],
    queryFn: async () => {
      const response = await api.getStandup(teamSlug, standupId);
      return response.data;
    },
    enabled: !!teamSlug && !!standupId,
  });
}

export function useCreateStandup(teamSlug: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: StandupFormData & { submit?: boolean }) =>
      api.createStandup(teamSlug, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['standups', teamSlug] });
      queryClient.invalidateQueries({ queryKey: ['standups', 'today', teamSlug] });
    },
  });
}

export function useUpdateStandup(teamSlug: string, standupId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: Partial<StandupFormData> & { submit?: boolean }) =>
      api.updateStandup(teamSlug, standupId, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['standups', teamSlug] });
      queryClient.invalidateQueries({ queryKey: ['standups', 'today', teamSlug] });
      queryClient.invalidateQueries({ queryKey: ['standups', teamSlug, standupId] });
    },
  });
}

export function useDeleteStandup(teamSlug: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (standupId: string) => api.deleteStandup(teamSlug, standupId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['standups', teamSlug] });
      queryClient.invalidateQueries({ queryKey: ['standups', 'today', teamSlug] });
    },
  });
}
