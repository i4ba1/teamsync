'use client';

import { useState, useEffect } from 'react';
import { Wifi, WifiOff } from 'lucide-react';
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from '@/components/ui/tooltip';
import { cn } from '@/lib/utils';

export function RealTimeIndicator() {
  const [isConnected, setIsConnected] = useState(true);

  useEffect(() => {
    const interval = setInterval(() => {
      setIsConnected(true);
    }, 5000);

    return () => clearInterval(interval);
  }, []);

  return (
    <TooltipProvider>
      <Tooltip>
        <TooltipTrigger asChild>
          <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-slate-800">
            <div
              className={cn(
                'w-2 h-2 rounded-full',
                isConnected ? 'bg-green-500 animate-pulse-dot' : 'bg-red-500'
              )}
            />
            <span className="text-xs text-slate-400">
              {isConnected ? 'Live' : 'Offline'}
            </span>
            {isConnected ? (
              <Wifi className="w-3 h-3 text-green-500" />
            ) : (
              <WifiOff className="w-3 h-3 text-red-500" />
            )}
          </div>
        </TooltipTrigger>
        <TooltipContent>
          <p>
            {isConnected
              ? 'Connected to real-time updates'
              : 'Reconnecting...'}
          </p>
        </TooltipContent>
      </Tooltip>
    </TooltipProvider>
  );
}
