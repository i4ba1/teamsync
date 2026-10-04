'use client';

import { useEffect, useRef, useCallback } from 'react';
import { createConsumer, Subscription } from '@rails/actioncable';
import { useStandupStore } from '@/stores/standup-store';
import { useToast } from '@/components/ui/use-toast';
import { WebSocketPayload, Standup, Notification } from '@/types';

const WS_URL = process.env.NEXT_PUBLIC_WS_URL || 'ws://localhost:3000/cable';

export function useStandupChannel(teamSlug: string) {
  const subscriptionRef = useRef<Subscription | null>(null);
  const { addStandup, updateStandupStatus } = useStandupStore();
  const { toast } = useToast();

  useEffect(() => {
    if (!teamSlug) return;

    const token = localStorage.getItem('access_token');
    if (!token) return;

    const consumer = createConsumer(`${WS_URL}?token=${token}`);

    subscriptionRef.current = consumer.subscriptions.create(
      { channel: 'StandupChannel', team_slug: teamSlug },
      {
        connected() {
          console.log('Connected to StandupChannel');
        },
        disconnected() {
          console.log('Disconnected from StandupChannel');
        },
        received(data: WebSocketPayload) {
          handleReceivedData(data);
        },
      }
    );

    function handleReceivedData(data: WebSocketPayload) {
      switch (data.type) {
        case 'standup_created':
          if (data.standup) {
            addStandup(data.standup);
            toast({
              title: 'New Standup',
              description: `${data.standup.user.fullName} submitted their standup`,
            });
          }
          break;
        case 'standup_updated':
          if (data.standup) {
            toast({
              title: 'Standup Updated',
              description: `${data.standup.user.fullName} updated their standup`,
            });
          }
          break;
        case 'standup_reminder':
          toast({
            title: 'Standup Reminder',
            description: data.message || 'Your standup is due soon!',
          });
          break;
        case 'connected':
          console.log(data.message);
          break;
      }
    }

    return () => {
      if (subscriptionRef.current) {
        subscriptionRef.current.unsubscribe();
      }
      consumer.disconnect();
    };
  }, [teamSlug, addStandup, toast]);

  const sendMessage = useCallback((data: Record<string, unknown>) => {
    if (subscriptionRef.current) {
      subscriptionRef.current.perform('receive', data);
    }
  }, []);

  return { sendMessage };
}

export function useNotificationChannel() {
  const subscriptionRef = useRef<Subscription | null>(null);
  const { toast } = useToast();

  useEffect(() => {
    const token = localStorage.getItem('access_token');
    if (!token) return;

    const consumer = createConsumer(`${WS_URL}?token=${token}`);

    subscriptionRef.current = consumer.subscriptions.create(
      { channel: 'NotificationChannel' },
      {
        connected() {
          console.log('Connected to NotificationChannel');
        },
        disconnected() {
          console.log('Disconnected from NotificationChannel');
        },
        received(data: WebSocketPayload) {
          handleReceivedData(data);
        },
      }
    );

    function handleReceivedData(data: WebSocketPayload) {
      switch (data.type) {
        case 'new_notification':
          if (data.notification) {
            const notification = data.notification as Notification;
            toast({
              title: notification.title,
              description: notification.message,
            });
          }
          break;
        case 'unread_count':
          break;
      }
    }

    return () => {
      if (subscriptionRef.current) {
        subscriptionRef.current.unsubscribe();
      }
      consumer.disconnect();
    };
  }, [toast]);

  const markAsRead = useCallback((notificationId: string) => {
    if (subscriptionRef.current) {
      subscriptionRef.current.perform('receive', {
        action: 'mark_read',
        notification_id: notificationId,
      });
    }
  }, []);

  const markAllAsRead = useCallback(() => {
    if (subscriptionRef.current) {
      subscriptionRef.current.perform('receive', {
        action: 'mark_all_read',
      });
    }
  }, []);

  return { markAsRead, markAllAsRead };
}

export function usePresenceChannel(teamSlug: string) {
  const subscriptionRef = useRef<Subscription | null>(null);

  useEffect(() => {
    if (!teamSlug) return;

    const token = localStorage.getItem('access_token');
    if (!token) return;

    const consumer = createConsumer(`${WS_URL}?token=${token}`);

    subscriptionRef.current = consumer.subscriptions.create(
      { channel: 'PresenceChannel', team_slug: teamSlug },
      {
        connected() {
          console.log('Connected to PresenceChannel');
        },
        disconnected() {
          console.log('Disconnected from PresenceChannel');
        },
        received(data: WebSocketPayload) {
          console.log('Presence update:', data);
        },
      }
    );

    return () => {
      if (subscriptionRef.current) {
        subscriptionRef.current.unsubscribe();
      }
      consumer.disconnect();
    };
  }, [teamSlug]);

  const ping = useCallback(() => {
    if (subscriptionRef.current) {
      subscriptionRef.current.perform('receive', { action: 'ping' });
    }
  }, []);

  return { ping };
}
