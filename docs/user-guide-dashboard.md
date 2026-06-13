# 💻 Panduan Pengguna: Dashboard Web

Panduan lengkap menggunakan web dashboard JalanCerdas AI.

---

## 🔐 Login

### Akses Dashboard

Buka browser → `http://localhost:3000`

Akan redirect ke halaman login.

### Form Login

```
┌─────────────────────────────────┐
│         🛣️ JalanCerdas AI       │
│    Dashboard Deteksi Jalan Rusak │
│                                 │
│  ┌─────────────────────────────┐│
│  │ 📧 Username                ││
│  │ [________________________]  ││
│  │                             ││
│  │ 🔒 Password                ││
│  │ [________________________]  ││
│  │                             ││
│  │        [ Masuk ]            ││
│  └─────────────────────────────┘│
│                                 │
│     © 2025 JalanCerdas AI       │
└─────────────────────────────────┘
```

### Default Credentials

| Field | Value |
|-------|-------|
| Username | `admin` |
| Password | `admin123` |

> ⚠️ Ganti password setelah login pertama kali (untuk production).

### Session

- Token JWT disimpan di `localStorage` browser
- Token valid selama 24 jam
- Session hilang jika token expired atau browser data di-clear

---

## 📊 Dashboard Overview

Setelah login, halaman utama menampilkan overview data.

### Layout

```
┌─────────┬────────────────────────────────────────────────┐
│         │  Header: JalanCerdas AI          [User: admin] │
│ Sidebar │────────────────────────────────────────────────│
│         │                                                │
│ 📊 Dash │  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐       │
│ 📋 Lapor│  │Total │ │ Baru │ │Terver│ │Proses│       │
│         │  │  15  │ │  6   │ │  4   │ │  3   │       │
│         │  └──────┘ └──────┘ └──────┘ └──────┘       │
│         │  ┌──────┐ ┌────────────────────────────────┐ │
│         │  │Selesa│ │ Rata-rata Confidence: 86.1%    │ │
│         │  │  4   │ │                                │ │
│         │  └──────┘ └────────────────────────────────┘ │
│         │                                                │
│         │  ┌────────────────────────────────────────┐   │
│         │  │           🗺️ PETA DETEKSI              │   │
│         │  │                                        │   │
│         │  │     📍        📍                       │   │
│         │  │        📍              📍              │   │
│         │  │                    📍                  │   │
│         │  │  📍           📍        📍             │   │
│         │  │              📍                       │   │
│         │  └────────────────────────────────────────┘   │
└─────────┴────────────────────────────────────────────────┘
```

### Stat Cards

| Card | Warna | Deskripsi |
|------|-------|-----------|
| **Total Deteksi** | 🔵 Biru | Jumlah seluruh deteksi |
| **Baru** | 🔵 Biru muda | Deteksi baru (belum ditangani) |
| **Terverifikasi** | 🟢 Hijau | Sudah diverifikasi admin |
| **Diproses** | 🟡 Kuning | Sedang dalam perbaikan |
| **Selesai** | 🟣 Ungu | Perbaikan selesai |
| **Rata-rata Confidence** | 🔴 Merah | Rata-rata confidence semua deteksi |

### Peta Deteksi

Peta interaktif menggunakan Leaflet/OpenStreetMap.
- Setiap deteksi ditampilkan sebagai marker di peta
- Klik marker untuk melihat detail deteksi
- Peta zoom ke Indonesia sebagai default view

---

## 🗺️ Viewing Map

### Interaksi Peta

| Aksi | Hasil |
|------|-------|
| **Scroll** | Zoom in/out |
| **Drag** | Pindah area |
| **Klik marker** | Popup detail deteksi |
| **Klik popup** | Link ke detail laporan |

### Marker Popup

Saat marker diklik, popup menampilkan:

```
┌──────────────────────┐
│ 🕳️ Pothole          │
│ Confidence: 92.1%    │
│ Status: Baru         │
│ 📍 -6.2088, 106.85  │
│ 📅 15 Jan 2025       │
└──────────────────────┘
```

---

## 📈 Reading Statistics

### Memahami Stat Cards

**Total Deteksi**: Jumlah seluruh record deteksi di database.

**Status Breakdown**:
- **Baru** → Deteksi baru dari mobile app, belum ada tindakan
- **Terverifikasi** → Admin sudah mengecek dan mengkonfirmasi
- **Diproses** → Tim lapangan sedang melakukan perbaikan
- **Selesai** → Perbaikan sudah dilakukan

**Rata-rata Confidence**: Semakin tinggi, semakin akurat model AI.

### Menginterpretasikan Data

- Jumlah "Baru" tinggi → Banyak deteksi baru menunggu review
- Jumlah "Diproses" tinggi → Banyak perbaikan sedang berjalan
- Rata-rata confidence rendah → Pertimbangkan recalibrate model

---

## 📋 Browsing Reports

### Akses Laporan

Klik **Laporan** di sidebar navigation.

### Fitur Laporan

- Daftar semua deteksi dalam format card/list
- Filter berdasarkan status
- Pagination (50 item per halaman default)
- Sort by newest first

### Filter Status

| Filter | Tampilkan |
|--------|-----------|
| Semua | Semua deteksi tanpa filter |
| Baru | Deteksi baru saja |
| Terverifikasi | Sudah diverifikasi |
| Diproses | Sedang diperbaiki |
| Selesai | Sudah selesai |

---

## 🔄 Changing Report Status

### Cara Mengubah Status

1. Buka halaman **Laporan** atau **Detail Laporan**
2. Klik tombol **Ubah Status** pada laporan
3. Pilih status baru dari dropdown:
   - `Baru` → `Terverifikasi`
   - `Terverifikasi` → `Diproses`
   - `Diproses` → `Selesai`
4. Konfirmasi perubahan

### Status Flow

```
Baru ──► Terverifikasi ──► Diproses ──► Selesai
 │              │               │
 └── Kembali ───┘──── Kembali ──┘
```

> 🔒 Mengubah status memerlukan login (JWT auth).

---

## 📄 Report Details

### Akses Detail

Klik item laporan di daftar atau klik marker di peta.

### Informasi yang Ditampilkan

```
┌─────────────────────────────────────────┐
│ Detail Laporan                          │
│─────────────────────────────────────────│
│                                         │
│ ID: a1b2c3d4-e5f6-7890-abcd-ef...    │
│                                         │
│ Tipe Kerusakan:  Pothole               │
│ Confidence:      92.1%                  │
│ Status:          Baru                   │
│                                         │
│ 📍 Lokasi                              │
│ Latitude:  -6.2088                      │
│ Longitude: 106.8456                     │
│                                         │
│ 🖼️ Gambar                              │
│ [Preview gambar deteksi]                │
│                                         │
│ 📅 Waktu                               │
│ Detected:  15 Jan 2025, 10:30 WIB      │
│ Created:   15 Jan 2025, 10:30:01 UTC   │
│ Updated:   15 Jan 2025, 10:30:01 UTC   │
│                                         │
│ [Ubah Status ▼]                         │
└─────────────────────────────────────────┘
```

---

## 🔧 Tips dan Best Practices

### Untuk Admin

1. **Review harian**: Cek tab "Baru" setiap hari untuk review deteksi baru
2. **Update status**: Ubah status secara berkala untuk tracking progress
3. **Export data**: Gunakan statistik untuk laporan berkala
4. **Peta**: Gunakan peta untuk melihat distribusi kerusakan per wilayah

### Untuk Operator

1. **Pastikan mobile app terhubung ke server yang benar**
2. **Cek GPS sebelum mulai deteksi**
3. **Upload detection segera** setelah terdeteksi
4. **Gunakan mock mode** untuk training/demo

### Performance Tips

- Dashboard menggunakan SSR (Server-Side Rendering) untuk load cepat
- Peta menggunakan dynamic import untuk mempercepat initial load
- Stat data di-cache di browser (refresh untuk data terbaru)

---

## 🔧 Troubleshooting

### "Username atau password salah"

1. Pastikan sudah seed data: `POST /api/seed`
2. Default: admin / admin123
3. Cek backend berjalan: `curl localhost:8000/health`

### Dashboard kosong / tidak ada data

1. Pastikan backend berjalan
2. Pastikan `NEXT_PUBLIC_API_URL` benar di `.env`
3. Seed data jika belum: `curl -X POST http://localhost:8000/api/seed`

### Peta tidak muncul

1. Cek koneksi internet (Leaflet membutuhkan tile server)
2. Refresh halaman
3. Cek console browser untuk error

### Error "Gagal memuat data dari server"

1. Backend mungkin belum berjalan
2. Cek URL API di `.env`
3. Cek CORS settings di backend
4. Cek network tab di browser DevTools

### Logout

Hapus token dari browser:
1. Buka DevTools → Application → Local Storage
2. Hapus item `token`
3. Atau clear browser data
4. Akan redirect ke halaman login
