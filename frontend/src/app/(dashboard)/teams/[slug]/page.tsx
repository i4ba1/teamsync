'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import { Users, Settings as SettingsIcon, BarChart3, UserPlus } from 'lucide-react';

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Skeleton } from '@/components/ui/skeleton';
import { useTeamStore } from '@/stores/team-store';
import { useTeam } from '@/hooks/use-teams';
import { useToast } from '@/components/ui/use-toast';

export default function TeamPage() {
  const params = useParams();
  const slug = params.slug as string;
  const { setCurrentTeam, teamMembers, fetchTeamMembers, inviteMember, updateTeam } = useTeamStore();
  const { toast } = useToast();

  const { data: team, isLoading } = useTeam(slug);

  const [inviteEmail, setInviteEmail] = useState('');
  const [name, setName] = useState('');
  const [timezone, setTimezone] = useState('UTC');
  const [standupTime, setStandupTime] = useState('09:00');

  useEffect(() => {
    if (team) {
      setCurrentTeam(team);
      setName(team.name);
      setTimezone(team.timezone);
      setStandupTime(team.standupTime);
    }
  }, [team, setCurrentTeam]);

  useEffect(() => {
    if (slug) {
      fetchTeamMembers(slug);
    }
  }, [slug, fetchTeamMembers]);

  if (isLoading) {
    return (
      <div className="mx-auto max-w-6xl">
        <Skeleton className="mb-8 h-32" />
        <Skeleton className="h-[400px]" />
      </div>
    );
  }

  if (!team) {
    return (
      <div className="flex h-full items-center justify-center">
        <p className="text-slate-400">Team not found</p>
      </div>
    );
  }

  const canManage = team.currentUserRole === 'owner' || team.currentUserRole === 'admin';
  const stats = team.todayStats ?? { submitted: 0, missed: 0, total: team.memberCount ?? 0 };

  const handleInvite = async () => {
    if (!inviteEmail) return;
    try {
      await inviteMember(slug, inviteEmail);
      setInviteEmail('');
      toast({ title: 'Invitation sent', description: `Invited ${inviteEmail} to ${team.name}.` });
    } catch {
      toast({ variant: 'destructive', title: 'Error', description: 'Could not invite that user.' });
    }
  };

  const handleSave = async () => {
    try {
      await updateTeam(slug, { name, timezone, standupTime });
      toast({ title: 'Team updated', description: 'Your changes have been saved.' });
    } catch {
      toast({ variant: 'destructive', title: 'Error', description: 'Could not update the team.' });
    }
  };

  return (
    <div className="mx-auto max-w-6xl space-y-6">
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-white">{team.name}</h1>
          <p className="text-sm text-slate-400">
            {team.memberCount ?? teamMembers.length} members · {team.timezone} · standup at {team.standupTime}
          </p>
        </div>
        {team.currentUserRole && <Badge variant="secondary">{team.currentUserRole}</Badge>}
      </div>

      <Tabs defaultValue="overview" className="space-y-6">
        <TabsList className="bg-slate-800">
          <TabsTrigger value="overview" className="data-[state=active]:bg-slate-700">
            <BarChart3 className="mr-2 h-4 w-4" />
            Overview
          </TabsTrigger>
          <TabsTrigger value="members" className="data-[state=active]:bg-slate-700">
            <Users className="mr-2 h-4 w-4" />
            Members
          </TabsTrigger>
          <TabsTrigger value="settings" className="data-[state=active]:bg-slate-700">
            <SettingsIcon className="mr-2 h-4 w-4" />
            Settings
          </TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-6">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
            <Card className="border-slate-800 bg-slate-900/50">
              <CardHeader>
                <CardTitle className="text-sm text-slate-400">Submitted</CardTitle>
              </CardHeader>
              <CardContent className="text-3xl font-semibold text-green-400">{stats.submitted}</CardContent>
            </Card>
            <Card className="border-slate-800 bg-slate-900/50">
              <CardHeader>
                <CardTitle className="text-sm text-slate-400">Missed</CardTitle>
              </CardHeader>
              <CardContent className="text-3xl font-semibold text-red-400">{stats.missed}</CardContent>
            </Card>
            <Card className="border-slate-800 bg-slate-900/50">
              <CardHeader>
                <CardTitle className="text-sm text-slate-400">Total</CardTitle>
              </CardHeader>
              <CardContent className="text-3xl font-semibold text-white">{stats.total}</CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="members">
          <Card className="border-slate-800 bg-slate-900/50">
            <CardHeader className="flex flex-row items-center justify-between">
              <CardTitle className="text-white">Team Members</CardTitle>
              {canManage && (
                <div className="flex items-center gap-2">
                  <Input
                    aria-label="Invite by email"
                    placeholder="teammate@example.com"
                    value={inviteEmail}
                    onChange={(event) => setInviteEmail(event.target.value)}
                    className="w-64 border-slate-700 bg-slate-800 text-white"
                  />
                  <Button onClick={handleInvite}>
                    <UserPlus className="mr-2 h-4 w-4" />
                    Invite
                  </Button>
                </div>
              )}
            </CardHeader>
            <CardContent className="space-y-4">
              {teamMembers.length === 0 ? (
                <p className="text-slate-400">No members yet.</p>
              ) : (
                teamMembers.map((membership) => (
                  <div key={membership.id} className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <Avatar className="h-9 w-9">
                        <AvatarFallback className="bg-slate-700 text-slate-200">
                          {membership.user?.initials ?? '?'}
                        </AvatarFallback>
                      </Avatar>
                      <div>
                        <p className="text-sm font-medium text-white">
                          {membership.user?.fullName ?? membership.user?.email}
                        </p>
                        <p className="text-xs text-slate-400">{membership.user?.timezone}</p>
                      </div>
                    </div>
                    <Badge variant="secondary">{membership.role}</Badge>
                  </div>
                ))
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="settings">
          <Card className="border-slate-800 bg-slate-900/50">
            <CardHeader>
              <CardTitle className="text-white">Team Settings</CardTitle>
            </CardHeader>
            <CardContent className="max-w-md space-y-4">
              <div className="space-y-2">
                <label className="text-sm text-slate-300" htmlFor="team-name">
                  Name
                </label>
                <Input
                  id="team-name"
                  value={name}
                  onChange={(event) => setName(event.target.value)}
                  className="border-slate-700 bg-slate-800 text-white"
                />
              </div>
              <div className="space-y-2">
                <label className="text-sm text-slate-300" htmlFor="team-timezone">
                  Timezone
                </label>
                <Input
                  id="team-timezone"
                  value={timezone}
                  onChange={(event) => setTimezone(event.target.value)}
                  className="border-slate-700 bg-slate-800 text-white"
                />
              </div>
              <div className="space-y-2">
                <label className="text-sm text-slate-300" htmlFor="team-standup-time">
                  Standup time
                </label>
                <Input
                  id="team-standup-time"
                  type="time"
                  value={standupTime}
                  onChange={(event) => setStandupTime(event.target.value)}
                  className="border-slate-700 bg-slate-800 text-white"
                />
              </div>
              <Button onClick={handleSave} disabled={!canManage}>
                Save changes
              </Button>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
