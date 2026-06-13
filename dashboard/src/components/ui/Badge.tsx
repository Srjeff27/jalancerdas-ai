import React from 'react';
import { cn } from '@/lib/utils';

type StatusType = 'Baru' | 'Terverifikasi' | 'Diproses' | 'Selesai';

const statusConfig: Record<
  StatusType,
  { label: string; className: string; dotClass: string }
> = {
  Baru: {
    label: 'Baru',
    className: 'bg-blue-50 text-blue-700 border border-blue-200',
    dotClass: 'bg-blue-500',
  },
  Terverifikasi: {
    label: 'Terverifikasi',
    className: 'bg-emerald-50 text-emerald-700 border border-emerald-200',
    dotClass: 'bg-emerald-500',
  },
  Diproses: {
    label: 'Diproses',
    className: 'bg-amber-50 text-amber-700 border border-amber-200',
    dotClass: 'bg-amber-500',
  },
  Selesai: {
    label: 'Selesai',
    className: 'bg-purple-50 text-purple-700 border border-purple-200',
    dotClass: 'bg-purple-500',
  },
};

interface BadgeProps {
  status: StatusType | string;
  className?: string;
  size?: 'sm' | 'md';
}

export function Badge({ status, className, size = 'sm' }: BadgeProps) {
  const config = statusConfig[status as StatusType] || {
    label: status,
    className: 'bg-gray-50 text-gray-700 border border-gray-200',
    dotClass: 'bg-gray-500',
  };

  return (
    <span
      className={cn(
        'inline-flex items-center gap-1.5 font-medium rounded-full',
        size === 'sm' ? 'px-2.5 py-0.5 text-xs' : 'px-3 py-1 text-sm',
        config.className,
        className
      )}
    >
      <span className={cn('w-1.5 h-1.5 rounded-full', config.dotClass)} />
      {config.label}
    </span>
  );
}
