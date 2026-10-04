'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { Calendar, Clock, Settings, Plus } from 'lucide-react';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';
import { useTeamStore } from '@/stores/team-store';
import { useTeams } from '@/hooks/use-teams';
import { useToast } from '@/components/ui/use-toast';

const navItems = [
  { icon: Calendar, label: 'Today', href: '/today' },
  { icon: Clock, label: 'History', href: '/history' },
];

export function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const { toast } = useToast();
  const { data: teams } = useTeams();
  const { currentTeam, setCurrentTeam, createTeam } = useTeamStore();

  const handleCreateTeam = async () => {
    const name = window.prompt('Team name');
    if (!name) return;

    try {
      const team = await createTeam({
        name,
        timezone: currentTeam?.timezone || 'UTC',
        standupTime: '09:00',
        standupDays: [1, 2, 3, 4, 5],
      } as never);
      setCurrentTeam(team);
      router.push(`/teams/${team.slug}`);
    } catch {
      toast({ variant: 'destructive', title: 'Error', description: 'Could not create the team.' });
    }
  };

  return (
    <aside className="flex w-64 flex-col border-r border-slate-800 bg-slate-900">
      <div className="p-4">
        <Button
          onClick={handleCreateTeam}
          variant="outline"
          className="w-full border-slate-700 bg-transparent text-slate-200 hover:bg-slate-800"
        >
          <Plus className="mr-2 h-4 w-4" />
          New team
        </Button>
      </div>

      <nav className="flex-1 space-y-2 px-4">
        <div className="space-y-1">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = pathname === item.href;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  'flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors',
                  isActive ? 'bg-primary text-primary-foreground' : 'text-slate-400 hover:bg-slate-800 hover:text-white',
                )}
              >
                <Icon className="h-4 w-4" />
                {item.label}
              </Link>
            );
          })}
        </div>

        <div className="space-y-1 pt-4">
          <p className="px-3 text-xs font-semibold uppercase tracking-wider text-slate-500">Teams</p>
          {(teams ?? []).map((team) => (
            <button
              key={team.id}
              type="button"
              onClick={() => setCurrentTeam(team)}
              className={cn(
                'flex w-full items-center gap-3 rounded-lg px-3 py-2 text-left text-sm font-medium transition-colors',
                currentTeam?.id === team.id
                  ? 'bg-slate-800 text-white'
                  : 'text-slate-400 hover:bg-slate-800 hover:text-white',
              )}
            >
              <span className="truncate">{team.name}</span>
            </button>
          ))}
        </div>
      </nav>

      <div className="border-t border-slate-800 p-4">
        <Link
          href="/settings"
          className={cn(
            'flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors',
            pathname === '/settings' ? 'bg-primary text-primary-foreground' : 'text-slate-400 hover:bg-slate-800 hover:text-white',
          )}
        >
          <Settings className="h-4 w-4" />
          Settings
        </Link>
      </div>
    </aside>
  );
}
