'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { isAuthenticated } from '@/services/auth';
import { getStatistics } from '@/services/detections';
import { Sidebar } from '@/components/layout/Sidebar';
import { Header } from '@/components/layout/Header';
import { Card } from '@/components/ui/Card';
import { PageSpinner } from '@/components/ui/Spinner';
import dynamic from 'next/dynamic';
import {
  Layers,
  CircleDot,
  CheckCircle2,
  Clock,
  Sparkles,
  TrendingUp,
} from 'lucide-react';
import type { Statistics } from '@/types';

const DetectionMap = dynamic(
  () => import('@/components/map/DetectionMap').then((m) => m.DetectionMap),
  { ssr: false, loading: () => <div className="h-[500px] bg-gray-50 rounded-2xl animate-pulse" /> }
);

export default function DashboardPage() {
  const router = useRouter();
  const [stats, setStats] = useState<Statistics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!isAuthenticated()) {
      router.replace('/login');
      return;
    }

    async function fetchStats() {
      try {
        const data = await getStatistics();
        setStats(data);
      } catch (err) {
        console.error(err);
        // Fallback mock data if API unavailable
        setStats({
          total: 0,
          baru: 0,
          terverifikasi: 0,
          diproses: 0,
          selesai: 0,
          average_confidence: 0,
        });
        setError('Gagal memuat data dari server');
      } finally {
        setLoading(false);
      }
    }
    fetchStats();
  }, [router]);

  if (loading) return <PageSpinner />;

  const statCards = [
    {
      label: 'Total Deteksi',
      value: stats?.total ?? 0,
      icon: Layers,
      color: 'text-[#0071e3]',
      bg: 'bg-[#0071e3]/10',
    },
    {
      label: 'Baru',
      value: stats?.baru ?? 0,
      icon: CircleDot,
      color: 'text-blue-500',
      bg: 'bg-blue-50',
    },
    {
      label: 'Terverifikasi',
      value: stats?.terverifikasi ?? 0,
      icon: CheckCircle2,
      color: 'text-emerald-500',
      bg: 'bg-emerald-50',
    },
    {
      label: 'Diproses',
      value: stats?.diproses ?? 0,
      icon: Clock,
      color: 'text-amber-500',
      bg: 'bg-amber-50',
    },
    {
      label: 'Selesai',
      value: stats?.selesai ?? 0,
      icon: Sparkles,
      color: 'text-purple-500',
      bg: 'bg-purple-50',
    },
    {
      label: 'Rata-rata Confidence',
      value: `${((stats?.average_confidence ?? 0) * 100).toFixed(1)}%`,
      icon: TrendingUp,
      color: 'text-rose-500',
      bg: 'bg-rose-50',
    },
  ];

  return (
    <div className="flex min-h-screen bg-[#f5f5f7]">
      <Sidebar />
      <div className="flex-1 ml-[240px]">
        <Header />
        <main className="p-6 space-y-6 animate-fade-in">
          {error && (
            <div className="bg-amber-50 border border-amber-200 text-amber-700 text-sm rounded-xl px-4 py-2.5">
              {error}
            </div>
          )}

          {/* Stat cards */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4">
            {statCards.map((stat, i) => {
              const Icon = stat.icon;
              return (
                <Card key={stat.label} hover className="animate-fade-in" style={{ animationDelay: `${i * 50}ms` }}>
                  <div className="flex items-center gap-3">
                    <div className={`p-2 rounded-xl ${stat.bg}`}>
                      <Icon className={`w-5 h-5 ${stat.color}`} />
                    </div>
                    <div>
                      <p className="text-xs text-gray-500 font-medium">{stat.label}</p>
                      <p className="text-xl font-bold text-gray-900">{stat.value}</p>
                    </div>
                  </div>
                </Card>
              );
            })}
          </div>

          {/* Map */}
          <Card padding="none" className="overflow-hidden">
            <div className="px-6 pt-6 pb-3">
              <h2 className="text-lg font-semibold text-gray-900">Peta Deteksi</h2>
              <p className="text-sm text-gray-500">
                Semua lokasi deteksi lubang jalan di Indonesia
              </p>
            </div>
            <div className="px-4 pb-4">
              <DetectionMap height="500px" />
            </div>
          </Card>
        </main>
      </div>
    </div>
  );
}
