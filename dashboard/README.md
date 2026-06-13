# Dashboard — JalanCerdas AI

Web dashboard berbasis Next.js untuk memantau dan mengelola data deteksi jalan rusak.

## Quick Start

```bash
npm install
npm run dev
```

## Fitur

- Peta Leaflet interaktif dengan marker berwarna sesuai status
- Statistik real-time
- Tabel laporan dengan filter & pagination
- Ubah status laporan (Baru → Terverifikasi → Diproses → Selesai)
- UI clean & minimalis ala iOS/macOS

## Struktur

```
src/
├── app/           # Pages (App Router)
│   ├── login/     # Halaman login
│   ├── dashboard/ # Peta + statistik
│   └── reports/   # Daftar & detail laporan
├── components/    # UI components (Sidebar, Card, Map, etc.)
├── services/      # API service calls
├── lib/           # Axios client, utilities
└── types/         # TypeScript type definitions
```

## Environment

```bash
cp .env.example .env.local
# Edit NEXT_PUBLIC_API_URL sesuai backend
```
