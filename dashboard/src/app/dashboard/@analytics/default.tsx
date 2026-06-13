'use client';

import React, { useEffect, useState } from 'react';
import { getStatistics } from '@/services/detections';
import { Card } from '@/components/ui/Card';
import { Spinner } from '@/components/ui/Spinner';
import {
  PieChart,
  TrendingUp,
  Clock,
  CheckCircle2,
} from 'lucide-react';
import type { Statistics } from '@/types';

export default function AnalyticsDefault() {
  const [stats, setStats] = useState<Statistics | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetch() {
      try {
        const data = await getStatistics();
        setStats(data);
      } catch {
        setStats({
          total: 0,
          baru: 0,
          terverifikasi: 0,
          diproses: 0,
          selesai: 0,
          average_confidence: 0,
        });
      } finally {
        setLoading(false);
      }
    }
    fetch();
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <Spinner size="md" />
      </div>
    );
  }

  const total = stats?.total || 1;
  const statusBreakdown = [
    { label: 'Baru', value: stats?.baru ?? 0, color: '#0071e3' },
    { label: 'Terverifikasi', value: stats?.terverifikasi ?? 0, color: '#30d158' },
    { label: 'Diproses', value: stats?.diproses ?? 0, color: '#ff9f0a' },
    { label: 'Selesai', value: stats?.selesai ?? 0, color: '#af52de' },
  ];

  return (
    <div className="space-y-4 animate-fade-in">
      <Card>
        <div className="flex items-center gap-2 mb-4">
          <PieChart className="w-5 h-5 text-[#0071e3]" />
          <h3 className="font-semibold text-gray-900">Distribusi Status</h3>
        </div>
        <div className="space-y-3">
          {statusBreakdown.map((item) => (
            <div key={item.label}>
              <div className="flex items-center justify-between text-sm mb-1">
                <span className="text-gray-600">{item.label}</span>
                <span className="font-medium text-gray-900">{item.value}</span>
              </div>
              <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                <div
                  className="h-full rounded-full transition-all duration-500"
                  style={{
                    width: `${(item.value / total) * 100}%`,
                    backgroundColor: item.color,
                  }}
                />
              </div>
            </div>
          ))}
        </div>
      </Card>

      <Card>
        <div className="flex items-center gap-2 mb-4">
          <TrendingUp className="w-5 h-5 text-rose-500" />
          <h3 className="font-semibold text-gray-900">Insights</h3>
        </div>
        <div className="space-y-3 text-sm">
          <div className="flex items-center gap-3 p-3 rounded-xl bg-gray-50">
            <CheckCircle2 className="w-4 h-4 text-emerald-500" />
            <span className="text-gray-600">
              <span className="font-medium text-gray-900">
                {((stats?.terverifikasi ?? 0) / total * 100).toFixed(1)}%
              </span>{' '}
              laporan terverifikasi
            </span>
          </div>
          <div className="flex items-center gap-3 p-3 rounded-xl bg-gray-50">
            <Clock className="w-4 h-4 text-amber-500" />
            <span className="text-gray-600">
              <span className="font-medium text-gray-900">
                {stats?.diproses ?? 0}
              </span>{' '}
              laporan sedang diproses
            </span>
          </div>
        </div>
      </Card>
    </div>
  );
}
