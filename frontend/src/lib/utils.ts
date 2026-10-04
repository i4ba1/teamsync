import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";
import { format as dateFormat, formatDistanceToNow } from "date-fns";
import { toZonedTime, fromZonedTime } from "date-fns-tz";
import { Team } from "@/types";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatDate(date: string | Date, format = 'PP'): string {
  return dateFormat(new Date(date), format);
}

export function formatDateInTimezone(
  date: string | Date,
  timezone: string,
  format = 'PP p'
): string {
  const zonedDate = toZonedTime(new Date(date), timezone);
  return dateFormat(zonedDate, format);
}

export function formatRelativeTime(date: string | Date): string {
  return formatDistanceToNow(new Date(date), { addSuffix: true });
}

export function getInitials(firstName: string, lastName: string): string {
  return `${firstName.charAt(0)}${lastName.charAt(0)}`.toUpperCase();
}

export function getStandupDueTime(team: Team): Date {
  const now = new Date();
  const [hours, minutes] = team.standupTime.split(':');

  const zonedNow = toZonedTime(now, team.timezone);
  zonedNow.setHours(parseInt(hours), parseInt(minutes), 0, 0);

  return fromZonedTime(zonedNow, team.timezone);
}

export function isStandupDay(team: Team, date: Date = new Date()): boolean {
  return team.standupDays.includes(date.getDay());
}

export function getNextStandupDate(team: Team): Date {
  const date = new Date();
  let daysToAdd = 0;
  
  for (let i = 0; i < 7; i++) {
    const checkDate = new Date(date);
    checkDate.setDate(date.getDate() + i);
    if (isStandupDay(team, checkDate)) {
      daysToAdd = i;
      break;
    }
  }
  
  const nextDate = new Date(date);
  nextDate.setDate(date.getDate() + daysToAdd);
  return nextDate;
}

export function generateInviteCode(): string {
  return Math.random().toString(36).substring(2, 14).toUpperCase();
}

export function detectTimezone(): string {
  return Intl.DateTimeFormat().resolvedOptions().timeZone;
}

export function getTimezoneOffset(timezone: string): string {
  const now = new Date();
  const formatter = new Intl.DateTimeFormat('en-US', {
    timeZone: timezone,
    timeZoneName: 'shortOffset',
  });
  const parts = formatter.formatToParts(now);
  const offsetPart = parts.find(p => p.type === 'timeZoneName');
  return offsetPart?.value || '';
}

export const TIMEZONES = [
  'UTC',
  'America/New_York',
  'America/Chicago',
  'America/Denver',
  'America/Los_Angeles',
  'America/Toronto',
  'America/Vancouver',
  'America/Mexico_City',
  'America/Sao_Paulo',
  'Europe/London',
  'Europe/Paris',
  'Europe/Berlin',
  'Europe/Madrid',
  'Europe/Rome',
  'Europe/Amsterdam',
  'Europe/Vienna',
  'Europe/Stockholm',
  'Europe/Oslo',
  'Europe/Copenhagen',
  'Europe/Helsinki',
  'Europe/Warsaw',
  'Europe/Prague',
  'Europe/Budapest',
  'Europe/Istanbul',
  'Europe/Moscow',
  'Africa/Cairo',
  'Africa/Johannesburg',
  'Africa/Lagos',
  'Asia/Dubai',
  'Asia/Jerusalem',
  'Asia/Tehran',
  'Asia/Karachi',
  'Asia/Kolkata',
  'Asia/Dhaka',
  'Asia/Bangkok',
  'Asia/Singapore',
  'Asia/Jakarta',
  'Asia/Hong_Kong',
  'Asia/Shanghai',
  'Asia/Seoul',
  'Asia/Tokyo',
  'Asia/Manila',
  'Australia/Perth',
  'Australia/Adelaide',
  'Australia/Darwin',
  'Australia/Brisbane',
  'Australia/Sydney',
  'Australia/Melbourne',
  'Pacific/Auckland',
  'Pacific/Fiji',
];

export const WEEKDAYS = [
  { value: 0, label: 'Sunday', short: 'Sun' },
  { value: 1, label: 'Monday', short: 'Mon' },
  { value: 2, label: 'Tuesday', short: 'Tue' },
  { value: 3, label: 'Wednesday', short: 'Wed' },
  { value: 4, label: 'Thursday', short: 'Thu' },
  { value: 5, label: 'Friday', short: 'Fri' },
  { value: 6, label: 'Saturday', short: 'Sat' },
];
