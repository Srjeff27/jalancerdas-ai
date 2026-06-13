'use client';

import React, { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { getMapDetections } from '@/services/detections';
import { MarkerPopup } from './MarkerPopup';
import { Spinner } from '@/components/ui/Spinner';
import type { Detection, StatusType } from '@/types';

// Fix default marker icon
// eslint-disable-next-line @typescript-eslint/no-explicit-any
delete (L.Icon.Default.prototype as any)['_getIconUrl'];
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
});

const statusColors: Record<StatusType, string> = {
  Baru: '#0071e3',
  Terverifikasi: '#30d158',
  Diproses: '#ff9f0a',
  Selesai: '#af52de',
};

function createMarkerIcon(status: StatusType): L.DivIcon {
  const color = statusColors[status] || '#0071e3';
  return L.divIcon({
    className: 'custom-marker',
    html: `
      <div style="
        width: 28px; height: 28px;
        background: ${color};
        border: 3px solid white;
        border-radius: 50%;
        box-shadow: 0 2px 8px rgba(0,0,0,0.2);
        display: flex; align-items: center; justify-content: center;
      ">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="3" stroke-linecap="round">
          <circle cx="12" cy="12" r="3"/>
        </svg>
      </div>
    `,
    iconSize: [28, 28],
    iconAnchor: [14, 14],
    popupAnchor: [0, -16],
  });
}

function MapLegend() {
  return (
    <div className="absolute bottom-4 right-4 z-[1000] bg-white rounded-xl shadow-lg p-3 border border-gray-100">
      <p className="text-xs font-semibold text-gray-700 mb-2">Status</p>
      <div className="space-y-1.5">
        {Object.entries(statusColors).map(([status, color]) => (
          <div key={status} className="flex items-center gap-2">
            <div
              className="w-3 h-3 rounded-full border-2 border-white shadow-sm"
              style={{ background: color }}
            />
            <span className="text-xs text-gray-600 capitalize">{status}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

interface DetectionMapProps {
  height?: string;
  detections?: Detection[];
}

export function DetectionMap({ height = '500px', detections: propDetections }: DetectionMapProps) {
  const [detections, setDetections] = useState<Detection[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (propDetections) {
      setDetections(propDetections);
      setLoading(false);
      return;
    }

    async function fetch() {
      try {
        const data = await getMapDetections();
        setDetections(Array.isArray(data) ? data : []);
      } catch (err) {
        console.error('Failed to fetch detections:', err);
        setError('Gagal memuat data deteksi');
      } finally {
        setLoading(false);
      }
    }
    fetch();
  }, [propDetections]);

  if (loading) {
    return (
      <div
        className="flex items-center justify-center bg-gray-50 rounded-2xl border border-gray-100"
        style={{ height }}
      >
        <div className="text-center">
          <Spinner size="lg" />
          <p className="mt-2 text-sm text-gray-400">Memuat peta...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div
        className="flex items-center justify-center bg-red-50 rounded-2xl border border-red-100"
        style={{ height }}
      >
        <p className="text-sm text-red-500">{error}</p>
      </div>
    );
  }

  return (
    <div className="relative rounded-2xl overflow-hidden border border-gray-100 shadow-sm" style={{ height }}>
      <MapContainer
        center={[-2.5, 118]}
        zoom={5}
        style={{ height: '100%', width: '100%' }}
        scrollWheelZoom={true}
        zoomControl={true}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png"
        />
        {detections.map((d) => (
          <Marker
            key={d.id}
            position={[d.latitude, d.longitude]}
            icon={createMarkerIcon(d.status)}
          >
            <Popup>
              <MarkerPopup detection={d} />
            </Popup>
          </Marker>
        ))}
      </MapContainer>
      <MapLegend />
    </div>
  );
}
