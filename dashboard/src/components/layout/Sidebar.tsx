'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { cn } from '@/lib/utils';
import {
  LayoutDashboard,
  FileText,
  Settings,
  ChevronLeft,
  ChevronRight,
  Route,
} from 'lucide-react';

const navItems = [
  {
    label: 'Dashboard',
    href: '/dashboard',
    icon: LayoutDashboard,
  },
  {
    label: 'Laporan',
    href: '/reports',
    icon: FileText,
  },
  {
    label: 'Pengaturan',
    href: '/settings',
    icon: Settings,
  },
];

export function Sidebar() {
  const [collapsed, setCollapsed] = useState(false);
  const pathname = usePathname();

  return (
    <aside
      className={cn(
        'fixed left-0 top-0 h-screen bg-white border-r border-gray-100',
        'flex flex-col z-40 transition-all duration-300 ease-in-out',
        collapsed ? 'w-[68px]' : 'w-[240px]'
      )}
    >
      {/* Logo */}
      <div className="flex items-center h-16 px-4 border-b border-gray-100">
        <div className="flex items-center gap-2.5 min-w-0">
          <div className="flex-shrink-0 w-8 h-8 rounded-lg bg-[#0071e3] flex items-center justify-center">
            <Route className="w-4 h-4 text-white" />
          </div>
          {!collapsed && (
            <div className="animate-fade-in">
              <h1 className="text-sm font-bold text-gray-900 leading-tight truncate">
                JalanCerdas
              </h1>
              <p className="text-[10px] font-medium text-[#0071e3] uppercase tracking-wider">
                AI Dashboard
              </p>
            </div>
          )}
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-3 py-4 space-y-1">
        {navItems.map((item) => {
          const isActive =
            pathname === item.href ||
            (item.href !== '/dashboard' && pathname.startsWith(item.href));
          const Icon = item.icon;

          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                'flex items-center gap-3 px-3 py-2 rounded-xl text-sm font-medium',
                'transition-all duration-150',
                isActive
                  ? 'bg-[#0071e3]/10 text-[#0071e3]'
                  : 'text-gray-500 hover:bg-gray-100 hover:text-gray-900',
                collapsed && 'justify-center px-0'
              )}
              title={collapsed ? item.label : undefined}
            >
              <Icon className="w-5 h-5 flex-shrink-0" />
              {!collapsed && <span>{item.label}</span>}
            </Link>
          );
        })}
      </nav>

      {/* Collapse toggle */}
      <div className="px-3 pb-4">
        <button
          onClick={() => setCollapsed(!collapsed)}
          className={cn(
            'w-full flex items-center justify-center gap-2 px-3 py-2 rounded-xl',
            'text-gray-400 hover:bg-gray-100 hover:text-gray-600',
            'transition-all duration-150 text-xs'
          )}
        >
          {collapsed ? (
            <ChevronRight className="w-4 h-4" />
          ) : (
            <>
              <ChevronLeft className="w-4 h-4" />
              <span>Tutup</span>
            </>
          )}
        </button>
      </div>
    </aside>
  );
}
