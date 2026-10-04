'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/stores/auth-store';
import { Sidebar } from '@/components/layout/sidebar';
import { Header } from '@/components/layout/header';
import { Loader2 } from 'lucide-react';

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  const { isAuthenticated, fetchUser } = useAuthStore();
  const [checked, setChecked] = useState(false);

  // Resolve the session before deciding whether to render or redirect. Without
  // this, the persisted auth state has not rehydrated yet on a full page load
  // and the guard would bounce an authenticated user to /login.
  useEffect(() => {
    let active = true;

    fetchUser().finally(() => {
      if (active) setChecked(true);
    });

    return () => {
      active = false;
    };
  }, [fetchUser]);

  useEffect(() => {
    if (checked && !isAuthenticated) {
      router.push('/login');
    }
  }, [checked, isAuthenticated, router]);

  if (!checked || !isAuthenticated) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-slate-950">
        <Loader2 className="h-8 w-8 animate-spin text-white" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-950">
      <div className="flex h-screen">
        <Sidebar />
        <div className="flex flex-1 flex-col overflow-hidden">
          <Header />
          <main className="flex-1 overflow-y-auto p-6">{children}</main>
        </div>
      </div>
    </div>
  );
}
