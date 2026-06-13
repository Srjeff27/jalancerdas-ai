# 💻 Instalasi Dashboard Web

Panduan menginstal dan menjalankan web dashboard JalanCerdas AI.

---

## 📋 Prerequisites

| Komponen | Versi Minimum | Cek Versi |
|----------|--------------|-----------|
| Node.js | 18.0+ | `node --version` |
| npm | 9.0+ | `npm --version` |
| Backend API | Running | `curl localhost:8000/health` |

> ⚠️ **Pastikan backend API sudah berjalan** sebelum menjalankan dashboard.

---

## 🚀 Manual Installation

### 1. Clone Repository

```bash
git clone https://github.com/username/jalancerdas-ai.git
cd jalancerdas-ai/dashboard
```

### 2. Install Dependencies

```bash
npm install
```

**Dependencies utama:**
```
next          14.2.0    # React framework
react         18.3.0    # UI library
react-dom     18.3.0    # React DOM renderer
leaflet       1.9.4     # Interactive maps
react-leaflet 4.2.1     # React wrapper for Leaflet
axios         1.7.0     # HTTP client
lucide-react  0.378     # Icon library
clsx          2.1.0     # Class name utility
tailwind-merge 2.3.0    # Tailwind class merging
```

**Dev dependencies:**
```
typescript    5.4.0     # Type system
@types/react  18.3.0    # React type definitions
tailwindcss   4.0.0     # Utility-first CSS
@tailwindcss/postcss 4.0.0
postcss       8.4.0     # CSS processor
```

### 3. Konfigurasi Environment Variables

```bash
cp .env.example .env
```

Edit file `.env`:

```env
NEXT_PUBLIC_API_URL=http://localhost:8000
```

> `NEXT_PUBLIC_API_URL` harus menunjuk ke backend API yang berjalan.
> Di production, ganti dengan URL production backend.

### 4. Jalankan Development Server

```bash
npm run dev
```

Dashboard berjalan di: **http://localhost:3000**

### 5. Verifikasi

Buka browser → http://localhost:3000

- Akan redirect ke halaman login
- Login dengan: `admin` / `admin123` (setelah seed data)
- Dashboard overview dengan peta dan statistik

---

## 🏗️ Build for Production

### 1. Build

```bash
npm run build
```

Output build ada di `.next/` directory.

### 2. Start Production Server

```bash
npm run start
```

Produksi server berjalan di: **http://localhost:3000**

---

## 🐳 Docker Installation

### 1. Build Image

```bash
cd dashboard
docker build -t jalancerdas-dashboard .
```

**Dockerfile (multi-stage build):**
```dockerfile
FROM node:20-alpine AS base

FROM base AS deps
WORKDIR /app
COPY package.json ./
RUN npm install --frozen-lockfile

FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM base AS runner
WORKDIR /app
ENV NODE_ENV production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 3000
ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"]
```

### 2. Jalankan Container

```bash
docker run -d \
  --name jalancerdas-dashboard \
  -p 3000:3000 \
  -e NEXT_PUBLIC_API_URL=http://localhost:8000 \
  jalancerdas-dashboard
```

> ⚠️ Untuk Docker, `NEXT_PUBLIC_API_URL` harus diakses dari browser client, bukan dari container.
> Jika dashboard dan backend berjalan di Docker Compose, gunakan host port.

---

## 📁 Struktur Dashboard

```
dashboard/
├── src/
│   ├── app/
│   │   ├── page.tsx                    # Root → redirect /login
│   │   ├── layout.tsx                  # Root layout
│   │   ├── login/
│   │   │   └── page.tsx                # Login page
│   │   ├── dashboard/
│   │   │   ├── page.tsx                # Main dashboard view
│   │   │   └── @analytics/
│   │   │       └── default.tsx         # Analytics parallel route
│   │   └── reports/
│   │       ├── page.tsx                # Reports list
│   │       └── [id]/
│   │           └── page.tsx            # Report detail
│   ├── components/
│   │   ├── map/
│   │   │   ├── DetectionMap.tsx        # Leaflet map wrapper
│   │   │   └── MarkerPopup.tsx         # Detection marker popup
│   │   ├── layout/
│   │   │   ├── Sidebar.tsx             # Navigation sidebar
│   │   │   └── Header.tsx              # Top header bar
│   │   └── ui/
│   │       ├── Badge.tsx               # Status badge
│   │       ├── Button.tsx              # Button component
│   │       ├── Card.tsx                # Card wrapper
│   │       ├── Input.tsx               # Form input
│   │       ├── Modal.tsx               # Modal dialog
│   │       └── Spinner.tsx             # Loading spinner
│   └── services/                       # API service functions
│       └── auth.ts, detections.ts
├── public/                             # Static assets
├── package.json
├── tsconfig.json
├── Dockerfile
├── .env
└── .env.example
```

---

## 🎨 Customization

### Mengganti Warna Theme

Dashboard menggunakan warna biru Apple-style (`#0071e3`) sebagai primary color.

Untuk mengganti, cari dan replace di file komponen:
```tsx
// Default
bg-[#0071e3]     // Background primary
text-[#0071e3]   // Text primary
shadow-[#0071e3] // Shadow primary
```

### Mengganti Logo

Edit `Sidebar.tsx` dan `Header.tsx` untuk mengganti logo dan branding.

### Menambah Halaman

Buat folder baru di `src/app/`:
```
src/app/your-page/
└── page.tsx
```

Next.js akan otomatis register route `/your-page`.

---

## 🔧 Troubleshooting

### Error: `Module not found: Can't resolve 'leaflet'`

```bash
npm install leaflet @types/leaflet
```

### Error: `Hydration mismatch`

Ini normal di development. Production build tidak terpengaruh.

### Error: `ECONNREFUSED localhost:8000`

Backend belum berjalan. Jalankan backend terlebih dahulu:
```bash
cd ../backend
source .venv/bin/activate
uvicorn app.main:app --reload
```

### Error: `NEXT_PUBLIC_API_URL` not picking up

Environment variables dengan prefix `NEXT_PUBLIC_` hanya di-inject saat build time.

```bash
# Rebuild setelah mengubah .env
npm run build
npm run start
```

### Warning: `useRouter` during SSR

Normal untuk Next.js App Router. Komponen harus di-declare `'use client'`.

---

## ✅ Checklist Instalasi

- [ ] Node.js 18+ terinstall
- [ ] `npm install` berhasil
- [ ] File `.env` sudah dikonfigurasi
- [ ] Backend API berjalan
- [ ] Development server berjalan (`npm run dev`)
- [ ] Halaman login muncul di browser
- [ ] Login dengan akun seed berhasil
- [ ] Dashboard menampilkan data
