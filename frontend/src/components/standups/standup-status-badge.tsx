import { CheckCircle, AlertCircle, Pencil, Palmtree, Clock } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';
import { StandupStatus } from '@/types';

interface StandupStatusBadgeProps {
  status: StandupStatus | 'pending' | 'overdue';
  className?: string;
}

const statusConfig = {
  draft: { color: 'yellow', icon: Pencil, label: 'Draft' },
  submitted: { color: 'green', icon: CheckCircle, label: 'Submitted' },
  missed: { color: 'red', icon: AlertCircle, label: 'Missed' },
  vacation: { color: 'blue', icon: Palmtree, label: 'Vacation' },
  holiday: { color: 'purple', icon: Clock, label: 'Holiday' },
  pending: { color: 'yellow', icon: Clock, label: 'Pending' },
  overdue: { color: 'red', icon: AlertCircle, label: 'Overdue' },
};

export function StandupStatusBadge({ status, className }: StandupStatusBadgeProps) {
  const config = statusConfig[status];
  const Icon = config.icon;

  return (
    <Badge
      variant="secondary"
      className={cn(
        'flex items-center gap-1',
        config.color === 'green' && 'bg-green-500/10 text-green-500 hover:bg-green-500/20',
        config.color === 'red' && 'bg-red-500/10 text-red-500 hover:bg-red-500/20',
        config.color === 'yellow' && 'bg-yellow-500/10 text-yellow-500 hover:bg-yellow-500/20',
        config.color === 'blue' && 'bg-blue-500/10 text-blue-500 hover:bg-blue-500/20',
        config.color === 'purple' && 'bg-purple-500/10 text-purple-500 hover:bg-purple-500/20',
        className
      )}
    >
      <Icon className="w-3 h-3" />
      <span className="text-xs">{config.label}</span>
    </Badge>
  );
}
