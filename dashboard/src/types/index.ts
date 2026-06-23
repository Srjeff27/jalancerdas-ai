export type StatusType = 'Baru' | 'Terverifikasi' | 'Diproses' | 'Selesai';

export interface Detection {
  id: string;
  damage_type: string;
  confidence: number;
  latitude: number;
  longitude: number;
  image_url: string;
  detected_at: string | null;
  status: StatusType;
  created_at: string;
  updated_at: string;
}

export interface Statistics {
  total: number;
  baru: number;
  terverifikasi: number;
  diproses: number;
  selesai: number;
  average_confidence: number;
}

export interface User {
  id: string;
  username: string;
  created_at: string;
}

export interface LoginRequest {
  username: string;
  password: string;
}

export interface LoginResponse {
  access_token: string;
  token_type: string;
  user: User;
}

export interface DetectionListResponse {
  detections: Detection[];
  total: number;
  limit: number;
  offset: number;
}

export interface ApiResponse<T> {
  data: T;
  message?: string;
  status: number;
}
