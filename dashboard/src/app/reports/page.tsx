'use client';

import React, { useEffect, useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { isAuthenticated } from '@/services/auth';
import { getAllDetections } from '@/services/detections';
import { Sidebar } from '@/components/layout/Sidebar';
import { Header } from '@/components/layout/Header';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { PageSpinner } from '@/components/ui/Spinner';
import { Search, Eye, ChevronLeft, ChevronRight } from 'lucide-react';
import type { Detection } from '@/types';

const statusOptions = [
  { value: '', label: 'Semua Status' },
  { value: 'Baru', label: 'Baru' },
  { value: 'Terverifikasi', label: 'Terverifikasi' },
  { value: 'Diproses', label: 'Diproses' },
  { value: 'Selesai', label: 'Selesai' },
];

export default function ReportsPage() {
  const router = useRouter();
  const [detections, setDetections] = useState<Detection[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [statusFilter, setStatusFilter] = useState('');
  const perPage = 10;

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const params: { limit: number; offset: number; status?: string } = {
        limit: perPage,
        offset: page * perPage,
      };
      if (statusFilter) params.status = statusFilter;
      const result = await getAllDetections(params);
      setDetections(result.detections || []);
      setTotal(result.total || 0);
    } catch {
      setDetections([]);
      setTotal(0);
    } finally {
      setLoading(false);
    }
  }, [page, statusFilter]);

  useEffect(() => {
    if (!isAuthenticated()) {
      router.replace('/login');
      return;
    }
    fetchData();
  }, [fetchData, router]);

  const totalPages = Math.ceil(total / perPage);

  return (
    <div className="flex min-h-screen bg-[#f5f5f7]">
      <Sidebar />
      <div className="flex-1 ml-[240px]">
        <Header />
        <main className="p-6 animate-fade-in">
          {/* Filters */}
          <div className="flex flex-col sm:flex-row items-start sm:items-center gap-3 mb-6">
            <div className="relative flex-1 max-w-xs">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
              <input
                type="text"
                placeholder="Filter laporan..."
                className="w-full pl-9 pr-4 py-2 text-sm rounded-xl border border-gray-200 bg-white focus:outline-none focus:ring-2 focus:ring-[#0071e3]/20 focus:border-[#0071e3]"
              />
            </div>

            <select
              value={statusFilter}
              onChange={(e) => {
                setStatusFilter(e.target.value);
                setPage(0);
              }}
              className="px-4 py-2 text-sm rounded-xl border border-gray-200 bg-white focus:outline-none focus:ring-2 focus:ring-[#0071e3]/20"
            >
              {statusOptions.map((opt) => (
                <option key={opt.value} value={opt.value}>
                  {opt.label}
                </option>
              ))}
            </select>

            <span className="text-sm text-gray-500">
              {total} laporan
            </span>
          </div>

          {/* Table */}
          {loading ? (
            <PageSpinner />
          ) : (
            <Card padding="none">
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="border-b border-gray-100">
                      <th className="text-left text-xs font-medium text-gray-500 uppercase tracking-wider px-4 py-3">Foto</th>
                      <th className="text-left text-xs font-medium text-gray-500 uppercase tracking-wider px-4 py-3">Tipe</th>
                      <th className="text-left text-xs font-medium text-gray-500 uppercase tracking-wider px-4 py-3">Lokasi</th>
                      <th className="text-left text-xs font-medium text-gray-500 uppercase tracking-wider px-4 py-3">Confidence</th>
                      <th className="text-left text-xs font-medium text-gray-500 uppercase tracking-wider px-4 py-3">Tanggal</th>
                      <th className="text-left text-xs font-medium text-gray-500 uppercase tracking-wider px-4 py-3">Status</th>
                      <th className="text-left text-xs font-medium text-gray-500 uppercase tracking-wider px-4 py-3">Aksi</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-50">
                    {detections.length === 0 ? (
                      <tr>
                        <td colSpan={7} className="text-center py-12 text-gray-400">
                          Tidak ada data
                        </td>
                      </tr>
                    ) : (
                      detections.map((item) => (
                        <tr key={item.id} className="hover:bg-gray-50/50 transition-colors">
                          <td className="px-4 py-3">
                            <div className="w-12 h-12 rounded-xl overflow-hidden bg-gray-100 flex-shrink-0">
                              <img
                                src={item.image_url || ''}
                                alt={item.damage_type}
                                className="w-full h-full object-cover"
                                onError={(e) => {
                                  (e.target as HTMLImageElement).style.display = 'none';
                                }}
                              />
                            </div>
                          </td>
                          <td className="px-4 py-3">
                            <span className="text-sm font-medium text-gray-900 capitalize">
                              {item.damage_type}
                            </span>
                          </td>
                          <td className="px-4 py-3">
                            <span className="text-sm text-gray-600">
                              {item.latitude.toFixed(4)}, {item.longitude.toFixed(4)}
                            </span>
                          </td>
                          <td className="px-4 py-3">
                            <span className="text-sm text-gray-600">
                              {(item.confidence * 100).toFixed(1)}%
                            </span>
                          </td>
                          <td className="px-4 py-3">
                            <span className="text-sm text-gray-600">
                              {item.detected_at
                                ? new Date(item.detected_at).toLocaleDateString('id-ID')
                                : '-'}
                            </span>
                          </td>
                          <td className="px-4 py-3">
                            <Badge status={item.status} />
                          </td>
                          <td className="px-4 py-3">
                            <Button
                              size="sm"
                              variant="ghost"
                              onClick={() => router.push(`/reports/${item.id}`)}
                            >
                              <Eye className="w-4 h-4" />
                            </Button>
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>

              {/* Pagination */}
              {totalPages > 1 && (
                <div className="flex items-center justify-between px-4 py-3 border-t border-gray-100">
                  <span className="text-sm text-gray-500">
                    Halaman {page + 1} dari {totalPages}
                  </span>
                  <div className="flex gap-2">
                    <Button
                      size="sm"
                      variant="ghost"
                      disabled={page === 0}
                      onClick={() => setPage(page - 1)}
                    >
                      <ChevronLeft className="w-4 h-4" />
                    </Button>
                    <Button
                      size="sm"
                      variant="ghost"
                      disabled={page >= totalPages - 1}
                      onClick={() => setPage(page + 1)}
                    >
                      <ChevronRight className="w-4 h-4" />
                    </Button>
                  </div>
                </div>
              )}
            </Card>
          )}
        </main>
      </div>
    </div>
  );
}
