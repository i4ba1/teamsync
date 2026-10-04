'use client';

import { useState } from 'react';

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Skeleton } from '@/components/ui/skeleton';
import { StandupStatusBadge } from '@/components/standups/standup-status-badge';
import { useTeamStore } from '@/stores/team-store';
import { useStandups } from '@/hooks/use-standups';
import { formatDate } from '@/lib/utils';

const STATUS_OPTIONS = [
  { value: 'all', label: 'All statuses' },
  { value: 'submitted', label: 'Submitted' },
  { value: 'missed', label: 'Missed' },
  { value: 'draft', label: 'Draft' },
];

export default function HistoryPage() {
  const { currentTeam } = useTeamStore();
  const [status, setStatus] = useState('all');

  const params = status === 'all' ? undefined : { status };
  const { data, isLoading } = useStandups(currentTeam?.slug || '', params);
  const standups = data?.data ?? [];

  if (!currentTeam) {
    return (
      <div className="flex h-full items-center justify-center">
        <p className="text-slate-400">Select a team to view history</p>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-6xl space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold text-white">History</h1>
        <select
          aria-label="Filter by status"
          value={status}
          onChange={(event) => setStatus(event.target.value)}
          className="rounded-md border border-slate-700 bg-slate-800 px-3 py-2 text-sm text-white"
        >
          {STATUS_OPTIONS.map((option) => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
        </select>
      </div>

      {isLoading ? (
        <Skeleton className="h-[400px]" />
      ) : standups.length === 0 ? (
        <Card className="border-slate-800 bg-slate-900/50">
          <CardContent className="py-10 text-center text-slate-400">No standups found.</CardContent>
        </Card>
      ) : (
        <div className="space-y-4">
          {standups.map((standup) => (
            <Card key={standup.id} className="border-slate-800 bg-slate-900/50">
              <CardHeader className="flex flex-row items-center justify-between">
                <div className="flex items-center gap-3">
                  <Avatar className="h-9 w-9">
                    <AvatarFallback className="bg-slate-700 text-slate-200">
                      {standup.user?.initials ?? '?'}
                    </AvatarFallback>
                  </Avatar>
                  <div>
                    <CardTitle className="text-sm text-white">
                      {standup.user?.fullName ?? 'Unknown member'}
                    </CardTitle>
                    <p className="text-xs text-slate-400">{formatDate(standup.standupDate)}</p>
                  </div>
                </div>
                <StandupStatusBadge status={standup.status} />
              </CardHeader>
              <CardContent className="space-y-2 text-sm text-slate-300">
                {standup.itemsSummary?.yesterday?.length ? (
                  <p>
                    <span className="text-slate-500">Yesterday: </span>
                    {standup.itemsSummary.yesterday.join(' ')}
                  </p>
                ) : null}
                {standup.itemsSummary?.today?.length ? (
                  <p>
                    <span className="text-slate-500">Today: </span>
                    {standup.itemsSummary.today.join(' ')}
                  </p>
                ) : null}
                {standup.itemsSummary?.blockers?.length ? (
                  <p>
                    <span className="text-slate-500">Blockers: </span>
                    {standup.itemsSummary.blockers.join(' ')}
                  </p>
                ) : null}
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
