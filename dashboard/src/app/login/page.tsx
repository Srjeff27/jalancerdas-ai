'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { login, isAuthenticated } from '@/services/auth';
import { Input } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';
import { Route, User, Lock } from 'lucide-react';

export default function LoginPage() {
  const router = useRouter();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (isAuthenticated()) {
      router.replace('/dashboard');
    }
  }, [router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!username || !password) {
      setError('Username dan password harus diisi');
      return;
    }

    setLoading(true);
    try {
      const res = await login({ username, password });
      localStorage.setItem('token', res.access_token);
      router.push('/dashboard');
    } catch (err: unknown) {
      const message =
        (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail ||
        'Username atau password salah';
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#f5f5f7] px-4">
      <div className="w-full max-w-[380px] animate-fade-in">
        {/* Logo */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-[#0071e3] mb-4 shadow-lg shadow-[#0071e3]/20">
            <Route className="w-7 h-7 text-white" />
          </div>
          <h1 className="text-2xl font-bold text-gray-900">JalanCerdas AI</h1>
          <p className="text-sm text-gray-500 mt-1">Dashboard Deteksi Jalan Rusak</p>
        </div>

        {/* Login card */}
        <div className="bg-white rounded-3xl shadow-sm border border-gray-100 p-8">
          <h2 className="text-lg font-semibold text-gray-900 mb-6">Masuk</h2>

          <form onSubmit={handleSubmit} className="space-y-4">
            <Input
              label="Username"
              placeholder="Masukkan username"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              icon={<User className="w-4 h-4" />}
              autoComplete="username"
            />

            <Input
              label="Password"
              type="password"
              placeholder="Masukkan password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              icon={<Lock className="w-4 h-4" />}
              autoComplete="current-password"
            />

            {error && (
              <div className="bg-red-50 border border-red-200 text-red-600 text-sm rounded-xl px-4 py-2.5 animate-fade-in">
                {error}
              </div>
            )}

            <Button
              type="submit"
              loading={loading}
              className="w-full"
              size="lg"
            >
              Masuk
            </Button>
          </form>
        </div>

        <p className="text-center text-xs text-gray-400 mt-6">
          © 2025 JalanCerdas AI. All rights reserved.
        </p>
      </div>
    </div>
  );
}
