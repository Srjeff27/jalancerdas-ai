import api from '@/lib/api';
import type { Detection, Statistics, DetectionListResponse } from '@/types';

export async function getAllDetections(params?: {
  status?: string;
  limit?: number;
  offset?: number;
}): Promise<DetectionListResponse> {
  const response = await api.get('/api/detections/', { params });
  return response.data;
}

export async function getDetection(id: string): Promise<Detection> {
  const response = await api.get(`/api/detections/${id}`);
  return response.data;
}

export async function updateDetectionStatus(
  id: string,
  status: string
): Promise<Detection> {
  const response = await api.patch(`/api/detections/${id}/status`, { status });
  return response.data;
}

export async function getStatistics(): Promise<Statistics> {
  const response = await api.get('/api/statistics/');
  return response.data;
}

export async function getMapDetections(): Promise<Detection[]> {
  const response = await api.get('/api/detections/', {
    params: { limit: 1000, offset: 0 },
  });
  return response.data.detections || [];
}
