# 🚗 JalanCerdas AI

**Sistem Deteksi Jalan Rusak Berbasis AI & Peta Digital**

[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?style=flat&logo=python&logoColor=white)](https://python.org)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev)
[![Next.js](https://img.shields.io/badge/Next.js-14+-000000?style=flat&logo=next.js&logoColor=white)](https://nextjs.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.109+-009688?style=flat&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=flat&logo=docker&logoColor=white)](https://docker.com)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## 👥 Tim

**Nama Tim:** Pak Gubernur Jalannyo Rusak Galo

| Nama | NIM | Peran |
|------|-----|-------|
| Jefri Hamid Jaya | G1F023003 | Full-Stack Developer |
| Rivan | - | AI/ML Engineer |
| Aida | - | UI/UX Designer |

---

## 📋 Deskripsi

JalanCerdas AI adalah aplikasi pendeteksi lubang jalan berbasis YOLO yang berjalan di aplikasi Android. Aplikasi digunakan di kendaraan seperti dashcam. Ketika kamera mendeteksi lubang jalan/pothole, aplikasi otomatis:

1. Mengambil foto/frame dari kamera
2. Membaca koordinat GPS
3. Mencatat confidence deteksi & waktu
4. Mengirim data ke server

Data disimpan di database dan ditampilkan pada website dashboard berbasis peta digital (WebGIS).

---

## ✨ Fitur Utama

### Mobile App (Android)
- 🎥 Live kamera dengan deteksi real-time
- 📍 GPS otomatis setiap deteksi
- 🧠 Model YOLO TFLite untuk deteksi pothole
- 📡 Upload otomatis / offline queue
- 🌙 Dark mode untuk penggunaan di kendaraan

### Backend API
- 🚀 FastAPI高性能 API
- 🔐 JWT Authentication untuk admin
- 📊 Statistik dashboard endpoint
- 🗄️ PostgreSQL + PostGIS support
- 📦 MinIO object storage untuk gambar

### Web Dashboard
- 🗺️ Peta Leaflet dengan marker berwarna
- 📈 Statistik real-time
- 📋 Tabel laporan dengan filter & pagination
- ✅ Ubah status laporan (Baru → Terverifikasi → Diproses → Selesai)
- 🎨 UI clean & minimalis ala iOS/macOS

### AI Model
- 🤖 YOLOv8n/YOLO11n untuk deteksi pothole
- 📱 TFLite export untuk mobile
- 📊 Evaluasi mAP, precision, recall
- 📓 Jupyter notebook untuk training interaktif

---

## 🏗️ Arsitektur Sistem

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Flutter    │────▶│   FastAPI    │────▶│  PostgreSQL  │
│   Android    │     │   Backend    │     │   Database   │
│   (Mobile)   │     │   :8000      │     │   :5432      │
└──────────────┘     └──────┬───────┘     └──────────────┘
                            │
                            ▼
                     ┌──────────────┐
                     │    MinIO     │
                     │   Storage    │
                     │   :9000      │
                     └──────────────┘
                            │
┌──────────────┐            │
│   Next.js   │◀───────────┘
│  Dashboard  │
│   :3000     │
└──────────────┘
       ▲
       │
┌──────────────┐
│    Nginx     │
│  :80 / :443  │
│   (Proxy)    │
└──────────────┘
```

---

## 🛠️ Tech Stack

| Komponen | Teknologi |
|----------|-----------|
| Mobile App | Flutter 3.x, Camera, Geolocator, TFLite, Hive |
| Backend | FastAPI, SQLAlchemy (async), Pydantic, JWT |
| Database | PostgreSQL 16, PostGIS (optional) |
| Storage | MinIO (S3-compatible) |
| Dashboard | Next.js 14, TypeScript, Tailwind CSS, Leaflet.js |
| AI Model | YOLOv8n/YOLO11n, Ultralytics, TFLite |
| Deployment | Docker Compose, Nginx, Let's Encrypt |

---

## 🚀 Quick Start dengan Docker

```bash
# 1. Clone repository
git clone https://github.com/Srjeff27/jalancerdas-ai.git
cd jalancerdas-ai

# 2. Copy environment file
cp deployment/.env.example deployment/.env

# 3. Jalankan semua service
cd deployment
docker compose up -d --build

# 5. Seed data dummy
curl -X POST http://localhost:8000/api/seed

# 6. Akses services
# Dashboard: http://localhost:3001 (or via Nginx: http://localhost:8888)
# Backend API: http://localhost:8000 (or via Nginx: http://localhost:8888/api/)
# Swagger Docs: http://localhost:8000/docs
# MinIO Console: http://localhost:9003
# Login: admin / admin123
```

---

## 🔧 Menjalankan Secara Manual

### Backend

```bash
cd backend

# Buat virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Konfigurasi environment
cp .env.example .env
# Edit .env sesuai kebutuhan

# Jalankan migration
alembic upgrade head

# Seed data
python seed_data.py

# Jalankan server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Dashboard

```bash
cd dashboard

# Install dependencies
npm install

# Konfigurasi environment
cp .env.example .env.local
# Edit .env.local

# Jalankan development server
npm run dev
```

### Mobile App

```bash
cd mobile

# Install dependencies
flutter pub get

# Jalankan di emulator/device
flutter run

# Build APK
flutter build apk --release
```

### AI Model Training

```bash
cd ai-model

# Install ultralytics
pip install ultralytics

# Download dataset
python scripts/download_dataset.py

# Training
python scripts/train.py --epochs 100 --batch 16

# Export ke TFLite
python scripts/export_tflite.py

# Copy model ke Flutter
cp best.tflite ../mobile/assets/models/pothole_yolo.tflite
```

---

## 📁 Struktur Project

```
jalancerdas-ai/
├── mobile/              # Flutter Android app
│   ├── lib/
│   │   ├── services/    # Camera, GPS, Detection, Upload, Offline
│   │   ├── models/      # Hive data models
│   │   ├── providers/   # State management (Provider)
│   │   ├── screens/     # UI screens
│   │   ├── widgets/     # Reusable widgets
│   │   └── utils/       # Helpers, constants
│   └── assets/          # TFLite model placeholder
│
├── backend/             # FastAPI backend
│   ├── app/
│   │   ├── api/         # Route handlers
│   │   ├── models/      # SQLAlchemy models
│   │   ├── schemas/     # Pydantic schemas
│   │   ├── services/    # Business logic
│   │   └── core/        # Config, security
│   ├── alembic/         # Database migrations
│   └── Dockerfile
│
├── dashboard/           # Next.js dashboard
│   └── src/
│       ├── app/         # Pages (App Router)
│       ├── components/  # UI components
│       ├── services/    # API services
│       ├── lib/         # Utilities, API client
│       └── types/       # TypeScript types
│
├── ai-model/            # YOLO training
│   ├── scripts/         # Training, export, eval
│   ├── notebooks/       # Jupyter notebooks
│   ├── configs/         # Dataset config
│   └── docs/            # Model specs
│
├── deployment/          # Docker + Nginx
│   ├── docker-compose.yml
│   ├── .env
│   └── nginx/
│
└── docs/                # Full documentation
```

---

## 📚 Dokumentasi

| Dokumen | Deskripsi |
|---------|-----------|
| [Arsitektur Sistem](docs/arsitektur-sistem.md) | Diagram arsitektur & komponen |
| [Instalasi Backend](docs/instalasi-backend.md) | Setup backend FastAPI |
| [Instalasi Dashboard](docs/instalasi-dashboard.md) | Setup dashboard Next.js |
| [Instalasi Mobile](docs/instalasi-mobile.md) | Setup Flutter app |
| [API Documentation](docs/api-documentation.md) | Endpoint API lengkap |
| [Database Schema](docs/database-schema.md) | Struktur database |
| [User Guide Mobile](docs/user-guide-mobile.md) | Panduan pengguna mobile |
| [User Guide Dashboard](docs/user-guide-dashboard.md) | Panduan pengguna dashboard |
| [Daftar Library](docs/daftar-library-lisensi.md) | Dependencies & lisensi |
| [Roadmap](docs/roadmap-pengembangan.md) | Rencana pengembangan |

---

## 🔐 API Endpoints

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| POST | `/api/detections` | ❌ | Kirim data deteksi |
| GET | `/api/detections` | ❌ | List semua deteksi |
| GET | `/api/detections/{id}` | ❌ | Detail deteksi |
| PATCH | `/api/detections/{id}/status` | ✅ | Ubah status (admin) |
| POST | `/api/upload` | ❌ | Upload gambar |
| POST | `/api/auth/login` | ❌ | Login admin |
| GET | `/api/auth/me` | ✅ | Info user login |
| GET | `/api/statistics` | ❌ | Statistik dashboard |
| POST | `/api/seed` | ❌ | Seed data dummy |

---

## 🔑 Default Credentials

| Service | Username | Password |
|---------|----------|----------|
| Admin Dashboard | admin | admin123 |
| MinIO Console | minioadmin | minioadmin |

> ⚠️ **Ubah credentials default sebelum deployment production!**

---

## 🗺️ Status Laporan

| Status | Warna | Deskripsi |
|--------|-------|-----------|
| 🔵 Baru | Biru | Laporan baru diterima |
| 🟢 Terverifikasi | Hijau | Sudah diverifikasi |
| 🟡 Diproses | Kuning/Oranye | Sedang dikerjakan |
| 🟣 Selesai | Ungu/Abu | Perbaikan selesai |

---

## 📈 Roadmap

### Phase 1 — MVP ✅
- Deteksi pothole (1 kelas)
- Upload foto + GPS + confidence
- Dashboard peta + CRUD status
- Offline queue

### Phase 2 — Multi Detection 🔄
- Multi-kelas: pothole, crack, bump, flood
- Model ensemble
- Severity scoring

### Phase 3 — User System
- User registration & profiles
- crowdsourcing rating
- Push notification

### Phase 4 — Smart Analytics
- Predictive maintenance
- Hotspot analysis
- Trend reporting
- Government API

---

## 📄 Lisensi

MIT License — See [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- [Ultralytics YOLO](https://github.com/ultralytics/ultralytics) — AI detection model
- [FastAPI](https://fastapi.tiangolo.com/) — Backend framework
- [Next.js](https://nextjs.org/) — Dashboard framework
- [Flutter](https://flutter.dev/) — Mobile framework
- [Leaflet](https://leafletjs.com/) — Map library
- [MinIO](https://min.io/) — Object storage
- [OpenStreetMap](https://www.openstreetmap.org/) — Map tiles

---

**Made with ❤️ by Tim Pak Gubernur Jalannyo Rusak Galo**
