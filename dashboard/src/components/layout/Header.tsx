'use client';

import React from 'react';
import { usePathname, useRouter } from 'next/navigation';
import { LogOut, User } from 'lucide-react';
import { logout } from '@/services/auth';
import { Button } from '@/components/ui/Button';

const pageTitles: Record<string, string> = {
  '/dashboard': 'Dashboard',
  '/reports': 'Laporan Deteksi',
  '/settings': 'Pengaturan',
};

export function Header() {
  const pathname = usePathname();
  const router = useRouter();

  const title =
    pageTitles[pathname] ||
    (pathname.startsWith('/reports/') ? 'Detail Laporan' : 'JalanCerdas AI');

  const handleLogout = () => {
    logout();
  };

  return (
    <header className="h-16 bg-white/80 backdrop-blur-xl border-b border-gray-100 px-6 flex items-center justify-between sticky top-0 z-30">
      <h1 className="text-lg font-semibold text-gray-900">{title}</h1>

      <div className="flex items-center gap-3">
        {/* User avatar */}
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-full bg-gray-100 flex items-center justify-center">
            <User className="w-4 h-4 text-gray-500" />
          </div>
          <span className="text-sm text-gray-600 hidden sm:inline">Admin</span>
        </div>

        {/* Logout */}
        <Button
          variant="ghost"
          size="sm"
          onClick={handleLogout}
          icon={<LogOut className="w-4 h-4" />}
          className="text-gray-500 hover:text-red-500"
        />
      </div>
    </header>
  );
}
