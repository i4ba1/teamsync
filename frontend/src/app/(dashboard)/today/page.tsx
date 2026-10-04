'use client';

import { useEffect } from 'react';
import { StandupForm } from '@/components/standups/standup-form';
import { StandupStatusBadge } from '@/components/standups/standup-status-badge';
import { TimezoneDisplay } from '@/components/standups/timezone-display';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { useTeamStore } from '@/stores/team-store';
import { useTodayStandup } from '@/hooks/use-standups';
import { useTeams } from '@/hooks/use-teams';
import { useStandupChannel } from '@/hooks/use-websocket';
import { getStandupDueTime } from '@/lib/utils';

export default function TodayPage() {
  const { currentTeam, setCurrentTeam } = useTeamStore();
  const { data: teams } = useTeams();
  const { data: todayStandup, isLoading } = useTodayStandup(currentTeam?.slug || '');

  useEffect(() => {
    if (!currentTeam && teams && teams.length > 0) {
      setCurrentTeam(teams[0]);
    }
  }, [currentTeam, teams, setCurrentTeam]);

  useStandupChannel(currentTeam?.slug || '');

  if (!currentTeam) {
    return (
      <div className="flex h-full items-center justify-center">
        <p className="text-slate-400">Select a team to get started</p>
      </div>
    );
  }

  const dueTime = getStandupDueTime(currentTeam);

  return (
    <div className="mx-auto max-w-6xl space-y-6">
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-white">{currentTeam.name}</h1>
          <p className="text-sm text-slate-400">
            Standup due <TimezoneDisplay datetime={dueTime.toISOString()} format="time" showTimezone />
          </p>
        </div>
        <StandupStatusBadge status={todayStandup?.status ?? 'pending'} />
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-5">
        <div className="lg:col-span-3">
          {isLoading ? (
            <Skeleton className="h-[420px]" />
          ) : (
            <StandupForm teamSlug={currentTeam.slug} standup={todayStandup} />
          )}
        </div>

        <div className="space-y-4 lg:col-span-2">
          <Card className="border-slate-800 bg-slate-900/50">
            <CardHeader>
              <CardTitle className="text-lg text-white">Your Status</CardTitle>
            </CardHeader>
            <CardContent className="flex items-center justify-between">
              <span className="text-slate-400">Today&apos;s Standup</span>
              <StandupStatusBadge status={todayStandup?.status ?? 'pending'} />
            </CardContent>
          </Card>

          <Card className="border-slate-800 bg-slate-900/50">
            <CardHeader>
              <CardTitle className="text-lg text-white">Team Activity</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-slate-400">
                Live updates from your teammates will appear here as they submit standups.
              </p>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
