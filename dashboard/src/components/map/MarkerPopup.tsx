'use client';

import React from 'react';
import { Badge } from '@/components/ui/Badge';
import type { Detection } from '@/types';

interface MarkerPopupProps {
  detection: Detection;
}

export function MarkerPopup({ detection }: MarkerPopupProps) {
  return (
    <div className="w-64">
      {/* Thumbnail */}
      <div className="relative h-36 overflow-hidden rounded-t-lg bg-gray-100">
        <img
          src={detection.image_url || ''}
          alt={detection.damage_type}
          className="w-full h-full object-cover"
          onError={(e) => {
            (e.target as HTMLImageElement).src =
              'data:image/svg+xml,' +
              encodeURIComponent(
                '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="144" fill="%23f3f4f6"><rect width="256" height="144"/><text x="50%" y="50%" text-anchor="middle" dy=".3em" fill="%239ca3af" font-family="sans-serif" font-size="14">No Image</text></svg>'
              );
          }}
        />
      </div>

      {/* Info */}
      <div className="p-3 space-y-2">
        <div className="flex items-start justify-between gap-2">
          <h4 className="font-semibold text-sm text-gray-900 capitalize">
            {detection.damage_type}
          </h4>
          <Badge status={detection.status} size="sm" />
        </div>

        <div className="space-y-1 text-xs text-gray-500">
          <div className="flex justify-between">
            <span>Confidence</span>
            <span className="font-medium text-gray-700">
              {(detection.confidence * 100).toFixed(1)}%
            </span>
          </div>
          <div className="flex justify-between">
            <span>Tanggal</span>
            <span className="font-medium text-gray-700">
              {detection.detected_at
                ? new Date(detection.detected_at).toLocaleDateString('id-ID', {
                    day: 'numeric',
                    month: 'short',
                    year: 'numeric',
                  })
                : '-'}
            </span>
          </div>
          <div className="flex justify-between">
            <span>Lokasi</span>
            <span className="font-medium text-gray-700">
              {detection.latitude.toFixed(4)}, {detection.longitude.toFixed(4)}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
