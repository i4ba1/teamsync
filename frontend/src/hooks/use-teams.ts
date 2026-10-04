import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '@/lib/api';
import { Team } from '@/types';

export function useTeams() {
  return useQuery({
    queryKey: ['teams'],
    queryFn: async () => {
      const response = await api.getTeams();
      return response.data;
    },
  });
}

export function useTeam(slug: string) {
  return useQuery({
    queryKey: ['teams', slug],
    queryFn: async () => {
      const response = await api.getTeam(slug);
      return response.data;
    },
    enabled: !!slug,
  });
}

export function useCreateTeam() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: Partial<Team>) => api.createTeam(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['teams'] });
    },
  });
}

export function useUpdateTeam(slug: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: Partial<Team>) => api.updateTeam(slug, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['teams'] });
      queryClient.invalidateQueries({ queryKey: ['teams', slug] });
    },
  });
}

export function useDeleteTeam() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (slug: string) => api.deleteTeam(slug),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['teams'] });
    },
  });
}
