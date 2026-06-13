import api from '@/lib/api';
import type { LoginRequest, LoginResponse } from '@/types';

export async function login(data: LoginRequest): Promise<LoginResponse> {
  const response = await api.post<LoginResponse>('/api/auth/login', data);
  return response.data;
}

export function logout(): void {
  localStorage.removeItem('token');
  window.location.href = '/login';
}

export function isAuthenticated(): boolean {
  if (typeof window === 'undefined') return false;
  return !!localStorage.getItem('token');
}
