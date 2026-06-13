'use client';

import React, { useEffect, useState } from 'react';
import { useRouter, useParams } from 'next/navigation';
import { isAuthenticated } from '@/services/auth';
import { getDetection, updateDetectionStatus } from '@/services/detections';
import { Sidebar } from '@/components/layout/Sidebar';
import { Header } from '@/components/layout/Header';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { PageSpinner } from '@/components/ui/Spinner';
import {
  ArrowLeft,
  MapPin,
  Calendar,
  Tag,
  Activity,
  Camera,
} from 'lucide-react';
import type { Detection } from '@/types';

const statuses = ['Baru', 'Terverifikasi', 'Diproses', 'Selesai'] as const;

export default function ReportDetailPage() {
  const router = useRouter();
  const params = useParams();
  const id = params.id as string;
  const [detection, setDetection] = useState<Detection | null>(null);
  const [loading, setLoading] = useState(true);
  const [updating, setUpdating] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!isAuthenticated()) {
      router.replace('/login');
      return;
    }
    async function fetchDetection() {
      try {
        const data = await getDetection(id);
        setDetection(data);
      } catch {
        setError('Gagal memuat data laporan');
      } finally {
        setLoading(false);
      }
    }
    if (id) fetchDetection();
  }, [id, router]);

  const handleStatusChange = async (newStatus: string) => {
    if (!detection) return;
    setUpdating(true);
    try {
      const updated = await updateDetectionStatus(detection.id, newStatus);
      setDetection(updated);
    } catch {
      setError('Gagal mengubah status');
    } finally {
      setUpdating(false);
    }
  };

  if (loading) return <PageSpinner />;
  if (!detection) {
    return (
      <div className="flex min-h-screen bg-[#f5f5f7]">
        <Sidebar />
        <div className="flex-1 ml-[240px]">
          <Header />
          <main className="p-6">
            <Card>
              <p className="text-center text-gray-500 py-12">{error || 'Laporan tidak ditemukan'}</p>
            </Card>
          </main>
        </div>
      </div>
    );
  }

  const details = [
    { icon: Tag, label: 'Tipe Kerusakan', value: detection.damage_type },
    {
      icon: Activity,
      label: 'Confidence',
      value: `${(detection.confidence * 100).toFixed(1)}%`,
    },
    {
      icon: MapPin,
      label: 'Latitude',
      value: detection.latitude.toFixed(6),
    },
    {
      icon: MapPin,
      label: 'Longitude',
      value: detection.longitude.toFixed(6),
    },
    {
      icon: Calendar,
      label: 'Tanggal Deteksi',
      value: detection.detected_at
        ? new Date(detection.detected_at).toLocaleString('id-ID')
        : '-',
    },
    {
      icon: Calendar,
      label: 'Dibuat',
      value: new Date(detection.created_at).toLocaleString('id-ID'),
    },
  ];

  return (
    <div className="flex min-h-screen bg-[#f5f5f7]">
      <Sidebar />
      <div className="flex-1 ml-[240px]">
        <Header />
        <main className="p-6 animate-fade-in">
          {/* Back button */}
          <button
            onClick={() => router.push('/reports')}
            className="flex items-center gap-2 text-sm text-gray-500 hover:text-gray-900 mb-4 transition-colors"
          >
            <ArrowLeft className="w-4 h-4" />
            Kembali ke Laporan
          </button>

          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-4 py-2.5 mb-4">
              {error}
            </div>
          )}

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Image */}
            <Card padding="none" className="lg:col-span-1 overflow-hidden">
              <div className="aspect-square bg-gray-100 relative">
                {detection.image_url ? (
                  <img
                    src={detection.image_url}
                    alt={detection.damage_type}
                    className="w-full h-full object-cover"
                    onError={(e) => {
                      (e.target as HTMLImageElement).src =
                        'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200"><rect fill="%23f3f4f6" width="200" height="200"/><text x="50%" y="50%" text-anchor="middle" dy=".3em" fill="%239ca3af" font-size="14">No Image</text></svg>';
                    }}
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center">
                    <Camera className="w-12 h-12 text-gray-300" />
                  </div>
                )}
              </div>
            </Card>

            {/* Details */}
            <Card className="lg:col-span-2 space-y-6">
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-bold text-gray-900">Detail Laporan</h2>
                <Badge status={detection.status} size="md" />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {details.map((item) => {
                  const Icon = item.icon;
                  return (
                    <div key={item.label} className="flex items-start gap-3 p-3 rounded-xl bg-gray-50">
                      <Icon className="w-4 h-4 text-gray-400 mt-0.5" />
                      <div>
                        <p className="text-xs text-gray-500 font-medium">{item.label}</p>
                        <p className="text-sm font-medium text-gray-900">{item.value}</p>
                      </div>
                    </div>
                  );
                })}
              </div>

              {/* Status change */}
              <div className="pt-4 border-t border-gray-100">
                <h3 className="text-sm font-semibold text-gray-900 mb-3">Ubah Status</h3>
                <div className="flex flex-wrap gap-2">
                  {statuses.map((s) => (
                    <Button
                      key={s}
                      size="sm"
                      variant={detection.status === s ? 'primary' : 'outline'}
                      disabled={updating || detection.status === s}
                      onClick={() => handleStatusChange(s)}
                    >
                      {s}
                    </Button>
                  ))}
                </div>
              </div>
            </Card>
          </div>
        </main>
      </div>
    </div>
  );
}
