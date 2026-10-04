'use client';

import { formatDistanceToNow, format } from 'date-fns';
import { toZonedTime } from 'date-fns-tz';

interface TimezoneDisplayProps {
  datetime: string | Date;
  format?: 'relative' | 'absolute' | 'time';
  showTimezone?: boolean;
  timezone?: string;
}

export function TimezoneDisplay({
  datetime,
  format: formatType = 'relative',
  showTimezone = true,
  timezone = Intl.DateTimeFormat().resolvedOptions().timeZone,
}: TimezoneDisplayProps) {
  const date = typeof datetime === 'string' ? new Date(datetime) : datetime;
  const zonedDate = toZonedTime(date, timezone);

  let displayText = '';

  switch (formatType) {
    case 'relative':
      displayText = formatDistanceToNow(date, { addSuffix: true });
      break;
    case 'absolute':
      displayText = format(zonedDate, 'PP p');
      break;
    case 'time':
      displayText = format(zonedDate, 'p');
      break;
  }

  const timezoneLabel = timezone.split('/').pop()?.replace(/_/g, ' ');

  return (
    <span className="text-slate-400">
      {formatType === 'relative' ? (
        <>
          {displayText.replace('about ', '')}
          {showTimezone && (
            <span className="text-slate-500">
              {' '}
              ({format(zonedDate, 'p')}
              {timezoneLabel ? ` ${timezoneLabel}` : ''})
            </span>
          )}
        </>
      ) : (
        <>
          {displayText}
          {showTimezone && timezoneLabel && <span className="text-slate-500"> {timezoneLabel}</span>}
        </>
      )}
    </span>
  );
}
