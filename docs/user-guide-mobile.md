# 📱 Panduan Pengguna: Mobile App

Panduan lengkap menggunakan aplikasi JalanCerdas AI di Android/iOS.

---

## 🚀 First Launch Setup

### 1. Buka Aplikasi

Setelah instalasi, buka aplikasi **JalanCerdas AI** dari home screen.

Splash screen akan menampilkan logo aplikasi selama beberapa detik.

### 2. Permission yang Diminta

Aplikasi akan meminta beberapa izin saat pertama kali dijalankan:

| Permission | Kegunaan | Wajib? |
|------------|----------|--------|
| **Camera** | Live preview untuk deteksi | ✅ Ya |
| **Location** | GPS koordinat lokasi deteksi | ✅ Ya |
| **Storage** | Menyimpan foto deteksi | ⚠️ Opsional |

> 💡 **Tips**: Jika permission ditolak, fitur terkait tidak akan berfungsi. Bisa diaktifkan nanti via Settings.

### 3. Setup API URL (Opsional)

Jika backend berjalan di server lain:
1. Buka tab **Settings** (ikon ⚙️)
2. Masukkan **API URL** yang sesuai
3. Default: `http://localhost:8000/api/v1`

**Referensi URL:**

| Environment | URL |
|-------------|-----|
| Android Emulator | `http://10.0.2.2:8000/api/v1` |
| iOS Simulator | `http://localhost:8000/api/v1` |
| Physical Device | `http://<IP_KOMPUTER>:8000/api/v1` |

---

## 🏠 Home Screen

Home screen adalah halaman utama dengan fitur deteksi real-time.

### Layout

```
┌─────────────────────────────────┐
│ [GPS: ✅]   [⚠️ 3]   [NET: ✅]│  ← Status bar
│                                 │
│                                 │
│      ┌─────────────────┐        │
│      │                 │        │
│      │   Camera        │        │  ← Live camera preview
│      │   Preview       │        │
│      │                 │        │
│      │   ┌─────┐       │        │  ← Bounding box overlay
│      │   │ 🕳️  │       │        │     (saat deteksi)
│      │   └─────┘       │        │
│      └─────────────────┘        │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Confidence: 92.1%           │ │  ← Info panel
│ │ Lat: -6.2088    Lng: 106.85 │ │
│ └─────────────────────────────┘ │
│                                 │
│  [🔄]    [▶️/⏹️]    [📷]       │  ← Controls
│ Switch   Start/    Capture
│ Camera   Stop      Photo
└─────────────────────────────────┘
│ Home  │ History │ Settings │    ← Bottom nav
```

### Status Indicators

| Indicator | ✅ (Green) | ❌ (Red) | Artinya |
|-----------|-----------|---------|---------|
| **GPS** | GPS aktif, lokasi terdeteksi | GPS mati/tidak tersedia | Perlu aktifkan GPS |
| **NET** | Internet tersedia | Tidak ada koneksi | Deteksi tetap jalan, upload di-queue |
| **Detection Count** | Angka badge merah | — | Jumlah deteksi dalam sesi ini |

### Mock Mode

Jika indicator 🔧 **MOCK MODE** muncul di pojok kiri atas:
- Aplikasi menggunakan deteksi simulasi (bukan model AI asli)
- Berguna untuk testing tanpa model TFLite
- Hasil deteksi di-generate random

---

## 🎯 Starting Detection

### Mulai Deteksi

1. Tab **Home** terbuka secara default
2. Deteksi **otomatis dimulai** saat home screen muncul
3. Kamera preview akan aktif dan model mulai inference

### Kontrol Deteksi

| Tombol | Fungsi |
|--------|--------|
| ▶️ **Play** (lingkaran biru) | Mulai deteksi |
| ⏹️ **Stop** (lingkaran merah) | Hentikan deteksi |
| 🔄 **Switch Camera** | Ganti kamera depan/belakang |
| 📷 **Capture** | Ambil foto manual |

### Cara Kerja Deteksi

```
1. Kamera menangkap frame (setiap 2 detik default)
2. Frame dikirim ke TFLite model
3. Model mengembalikan bounding boxes + confidence
4. Jika confidence > threshold (default 65%):
   a. Bounding box ditampilkan di layar
   b. GPS coordinates diambil
   c. Data disimpan lokal (Hive)
   d. Jika Auto Upload ON → upload ke server
   e. Jika offline → masuk offline queue
```

### Membaca Hasil Deteksi

Saat lubang terdeteksi, panel info akan menampilkan:

| Info | Deskripsi |
|------|-----------|
| **Confidence** | Tingkat keyakinan model (merah jika > 70%, kuning jika ≤ 70%) |
| **Lat** | Koordinat latitude GPS |
| **Lng** | Koordinat longitude GPS |

---

## 📜 Viewing History

### Akses History

Klik tab **History** di bottom navigation bar.

### Fitur History

- Daftar semua deteksi yang pernah dilakukan
- Menampilkan tipe kerusakan, confidence, lokasi, dan waktu
- Status upload (uploaded / queued / failed)
- Klik item untuk melihat detail

### Status di History

| Status | Icon | Artinya |
|--------|------|---------|
| **Detected** | 🔍 | Terdeteksi, belum diupload |
| **Uploaded** | ☁️ | Berhasil diupload ke server |
| **Queued** | ⏳ | Dalam antrian offline upload |
| **Failed** | ❌ | Upload gagal |

### Offline Queue

Jika aplikasi dalam mode offline atau jaringan tidak tersedia:
1. Deteksi disimpan ke Hive local database
2. Masuk ke upload queue
3. Ketika jaringan tersedia, queue otomatis di-retry
4. Status berubah dari Queued → Uploaded

---

## ⚙️ Changing Settings

### Akses Settings

Klik tab **Settings** di bottom navigation bar.

### Pengaturan yang Tersedia

#### API Configuration

| Setting | Default | Deskripsi |
|---------|---------|-----------|
| **API URL** | `http://localhost:8000/api/v1` | Backend server URL |

#### Detection Settings

| Setting | Default | Deskripsi |
|---------|---------|-----------|
| **Confidence Threshold** | 65% | Minimum confidence untuk mendeteksi. Slider 50% - 100%. |
| **Mock Detection Mode** | OFF | Aktifkan untuk simulasi tanpa model AI |

#### Upload Settings

| Setting | Default | Deskripsi |
|---------|---------|-----------|
| **Auto Upload** | ON | Otomatis upload deteksi ke server |
| **Offline Mode** | OFF | Matikan semua operasi jaringan |

### Reset Settings

Klik ikon restore (↩️) di pojok kanan atas Settings screen untuk reset semua ke default.

---

## 📡 Offline Mode

### Cara Kerja

1. **Mode Normal (Auto Upload ON)**:
   - Deteksi → Upload langsung ke server
   - Jika gagal → Masuk queue
   - Jika jaringan kembali → Auto retry

2. **Mode Offline (Offline Mode ON)**:
   - Tidak ada operasi jaringan sama sekali
   - Semua deteksi disimpan lokal
   - Bisa di-upload manual nanti

3. **Offline Queue Service**:
   - Monitoring jaringan via `connectivity_plus`
   - Saat jaringan kembali → upload queue otomatis diproses
   - Per-item retry (tidak batch)

### Penyimpanan Offline

Data disimpan di Hive boxes:
- `detections` — Semua record deteksi
- `upload_queue` — Item yang belum terupload

Data persist meskipun aplikasi ditutup.

---

## 🔧 Troubleshooting

### Kamera tidak muncul

1. Cek izin kamera di Settings → Apps → JalanCerdas → Permissions
2. Restart aplikasi
3. Jika di emulator, pastikan kamera virtual aktif

### GPS tidak aktif (indicator merah)

1. Aktifkan GPS di Settings → Location
2. Pastikan izin location diberikan ke aplikasi
3. Tunggu beberapa detik untuk lock GPS

### Tidak bisa upload (NET merah)

1. Cek koneksi internet
2. Deteksi tetap tersimpan lokal
3. Upload otomatis saat jaringan tersedia

### Mock Mode terus aktif

Model TFLite belum terinstall atau gagal load.
Untuk production:
1. Download model `.tflite`
2. Letakkan di `assets/models/model.tflite`
3. Rebuild aplikasi

### App crash saat buka kamera

1. Pastikan tidak ada aplikasi lain yang menggunakan kamera
2. Restart device
3. Clear cache aplikasi

### Data hilang setelah reinstall

Data Hive tersimpan di device storage. Jika di-uninstall, data hilang.
Untuk backup: data perlu di-upload ke server terlebih dahulu.
