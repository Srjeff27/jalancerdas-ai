# 🏗️ Arsitektur Sistem JalanCerdas AI

Arsitektur lengkap sistem deteksi lubang jalan berbasis AI untuk monitoring kondisi infrastruktur jalan di Indonesia.

---

## 📊 High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        END USERS                                │
│                                                                 │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐     │
│   │  📱 Mobile   │    │  💻 Dashboard│    │  🏛️ Admin   │     │
│   │  App         │    │  (Web)       │    │  Panel       │     │
│   │  (Flutter)   │    │  (Next.js)   │    │  (Next.js)   │     │
│   └──────┬───────┘    └──────┬───────┘    └──────┬───────┘     │
│          │                    │                    │              │
│          │ Camera + GPS      │ HTTP/REST          │ HTTP/REST   │
│          │ TFLite Inference  │                    │              │
└──────────┼────────────────────┼────────────────────┼─────────────┘
           │                    │                    │
           ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                     REST API (FastAPI)                           │
│                     Port: 8000                                   │
│                                                                 │
│   ┌─────────┐ ┌──────────┐ ┌──────────┐ ┌────────────────┐    │
│   │ Auth    │ │Detection │ │Statistics│ │ Upload         │    │
│   │ (JWT)   │ │ CRUD     │ │ Endpoint │ │ (Multipart)    │    │
│   └────┬────┘ └────┬─────┘ └────┬─────┘ └───────┬────────┘    │
│        │           │            │                │              │
└────────┼───────────┼────────────┼────────────────┼──────────────┘
         │           │            │                │
         ▼           ▼            ▼                ▼
┌────────────────┐ ┌─────────────────────┐ ┌──────────────────┐
│ 🗄️ PostgreSQL  │ │ 📦 MinIO            │ │ 📁 File System  │
│ (PostGIS)      │ │ (S3-compatible)     │ │ (Fallback)      │
│ Port: 5432     │ │ Port: 9000          │ │                  │
│                │ │ Bucket:             │ │                  │
│ • detections   │ │ road-detections     │ │                  │
│ • users        │ │                     │ │                  │
└────────────────┘ └─────────────────────┘ └──────────────────┘
```

---

## 🧩 Komponen Sistem

### 1. 📱 Mobile App (Flutter)

Aplikasi mobile yang berjalan di Android/iOS untuk deteksi lubang jalan secara real-time.

**Fitur utama:**
- Live camera preview dengan overlay bounding box
- Inference model TFLite on-device (YOLO-based)
- Pengambilan GPS koordinat otomatis
- Upload deteksi ke backend via REST API
- Offline queue untuk upload saat jaringan tersedia kembali
- Mock mode untuk pengembangan tanpa model AI

**Arsitektur internal:**
```
lib/
├── main.dart                    # Entry point, inisialisasi Hive + Provider
├── app.dart                     # MaterialApp route configuration
├── models/
│   ├── detection_record.dart    # Model data deteksi
│   ├── app_settings.dart        # Model pengaturan aplikasi
│   └── adapters.dart            # Hive TypeAdapter untuk serialization
├── screens/
│   ├── splash_screen.dart       # Loading screen
│   ├── home_screen.dart         # Camera view + detection overlay
│   ├── history_screen.dart      # Daftar deteksi sebelumnya
│   ├── detection_detail_screen.dart  # Detail satu deteksi
│   └── settings_screen.dart     # Pengaturan aplikasi
├── services/
│   ├── api_service.dart         # Dio HTTP client wrapper
│   ├── camera_service.dart      # Inisialisasi & kontrol kamera
│   ├── location_service.dart    # GPS / Geolocator
│   ├── detection_service.dart   # TFLite inference + mock detection
│   ├── upload_service.dart      # Upload ke backend via multipart
│   └── offline_queue_service.dart # Hive-based upload queue
├── providers/
│   ├── detection_provider.dart  # State management deteksi
│   └── settings_provider.dart   # State management pengaturan
├── widgets/
│   ├── detection_card.dart      # Card untuk daftar history
│   ├── detection_overlay.dart   # Bounding box overlay di kamera
│   └── status_indicator.dart    # Indikator GPS/Network status
└── utils/
    ├── constants.dart           # Konstanta aplikasi
    └── helpers.dart             # Utility functions
```

**Tech Stack:**
- Flutter 3.x (Dart)
- Provider (state management)
- Hive (local database / offline storage)
- TFLite (on-device AI inference)
- Camera plugin (live preview)
- Geolocator (GPS)
- Dio (HTTP client)
- Connectivity Plus (network monitoring)

---

### 2. 🖥️ Backend API (FastAPI)

REST API server yang menerima data deteksi dari mobile app dan menyediakan data untuk dashboard.

**Fitur utama:**
- Async API endpoints (FastAPI + SQLAlchemy async)
- JWT authentication
- Multipart image upload ke MinIO
- CRUD detection records
- Statistics aggregation
- Seed data endpoint untuk development
- Graceful degradation (MinIO unavailable → local fallback)

**Arsitektur internal:**
```
backend/
├── app/
│   ├── main.py                  # FastAPI app entry + lifespan
│   ├── database.py              # SQLAlchemy async engine + session
│   ├── core/
│   │   ├── config.py            # Pydantic Settings (env vars)
│   │   └── security.py          # JWT creation, verification, bcrypt
│   ├── models/
│   │   ├── detection.py         # Detection SQLAlchemy model
│   │   └── user.py              # User SQLAlchemy model
│   ├── schemas/
│   │   ├── detection.py         # Pydantic schemas (Create, Response, List)
│   │   └── auth.py              # Auth schemas (Login, Token, User)
│   ├── services/
│   │   ├── detection_service.py # Detection CRUD logic + statistics
│   │   └── minio_service.py     # MinIO upload + graceful fallback
│   └── api/
│       ├── detections.py        # /api/detections/* endpoints
│       ├── auth.py              # /api/auth/* endpoints
│       ├── statistics.py        # /api/statistics endpoint
│       ├── upload.py            # /api/upload endpoint
│       └── seed.py              # /api/seed endpoint
├── alembic/                     # Database migration scripts
│   └── env.py
├── alembic.ini                  # Alembic configuration
├── requirements.txt             # Python dependencies
├── Dockerfile                   # Docker build instructions
└── .env.example                 # Environment variable template
```

**Tech Stack:**
- Python 3.11+
- FastAPI 0.110+ (async web framework)
- SQLAlchemy 2.0+ (async ORM)
- PostgreSQL (database)
- MinIO (S3-compatible object storage)
- python-jose (JWT)
- passlib + bcrypt (password hashing)
- Alembic (database migrations)
- Uvicorn (ASGI server)

---

### 3. 📊 Dashboard (Next.js)

Web dashboard untuk visualisasi dan manajemen data deteksi.

**Fitur utama:**
- Login page dengan JWT auth
- Dashboard overview dengan stat cards
- Peta interaktif (Leaflet) menampilkan lokasi deteksi
- Daftar laporan dengan filter status
- Detail laporan dengan ubah status
- Responsive design (Tailwind CSS)

**Arsitektur internal:**
```
dashboard/
├── src/
│   ├── app/
│   │   ├── page.tsx             # Root → redirect ke /login
│   │   ├── layout.tsx           # Root layout (HTML, fonts)
│   │   ├── login/
│   │   │   └── page.tsx         # Login form
│   │   ├── dashboard/
│   │   │   ├── page.tsx         # Main dashboard (stats + map)
│   │   │   └── @analytics/
│   │   │       └── default.tsx  # Analytics view
│   │   └── reports/
│   │       ├── page.tsx         # Reports list
│   │       └── [id]/
│   │           └── page.tsx     # Report detail
│   ├── components/
│   │   ├── map/
│   │   │   ├── DetectionMap.tsx # Leaflet map component
│   │   │   └── MarkerPopup.tsx  # Popup marker detail
│   │   ├── layout/
│   │   │   ├── Sidebar.tsx      # Navigation sidebar
│   │   │   └── Header.tsx       # Top header bar
│   │   └── ui/
│   │       ├── Badge.tsx
│   │       ├── Button.tsx
│   │       ├── Card.tsx
│   │       ├── Input.tsx
│   │       ├── Modal.tsx
│   │       └── Spinner.tsx
│   └── services/                # API service functions
├── package.json
├── Dockerfile                   # Multi-stage Docker build
├── tsconfig.json
└── .env.example                 # NEXT_PUBLIC_API_URL
```

**Tech Stack:**
- Next.js 14 (React 18)
- TypeScript 5.4+
- Tailwind CSS 4
- Leaflet / react-leaflet (maps)
- Axios (HTTP client)
- Lucide React (icons)

---

### 4. 🗄️ PostgreSQL Database

Database relasional untuk menyimpan data deteksi dan user.

**Tabel utama:**
- `detections` — Record deteksi lubang/jalan rusak
- `users` — User credentials untuk autentikasi

**Extensions:**
- PostGIS (opsional, untuk spatial queries di masa depan)

**Connection:**
- Driver: `asyncpg` (async PostgreSQL)
- Pool: pre-ping enabled, auto-reconnect

---

### 5. 📦 MinIO (Object Storage)

S3-compatible object storage untuk menyimpan gambar deteksi.

**Konfigurasi:**
- Bucket: `road-detections`
- Path: `YYYY/MM/DD/{uuid}.ext`
- Graceful fallback: Jika MinIO unavailable, path lokal dikembalikan

---

## 🔄 Data Flow

### Flow 1: Deteksi Lubang Jalan (Mobile → Backend)

```
📱 Mobile                    🖥️ Backend                  📦 Storage
   │                           │                           │
   │  1. Kamera capture frame  │                           │
   │──────────────────►        │                           │
   │                           │                           │
   │  2. TFLite inference      │                           │
   │     (on-device)           │                           │
   │                           │                           │
   │  3. Bounding box +        │                           │
   │     confidence > 0.65     │                           │
   │                           │                           │
   │  4. Get GPS coordinates   │                           │
   │                           │                           │
   │  5. POST /api/detections  │                           │
   │     (multipart/form-data) │                           │
   │──────────────────────────►│                           │
   │                           │  6. Upload image file     │
   │                           │──────────────────────────►│
   │                           │                           │ (MinIO/S3)
   │                           │  7. Store record in DB    │
   │                           │──────────────────►        │
   │                           │                           │ (PostgreSQL)
   │  8. Response: Detection   │                           │
   │◄──────────────────────────│                           │
```

### Flow 2: Dashboard Visualization (Dashboard → Backend)

```
💻 Dashboard                 🖥️ Backend                  🗄️ Database
   │                           │                           │
   │  1. GET /api/statistics   │                           │
   │──────────────────────────►│  2. Aggregate queries     │
   │                           │──────────────────────────►│
   │                           │  3. Return stats          │
   │◄──────────────────────────│                           │
   │                           │                           │
   │  4. GET /api/detections   │                           │
   │──────────────────────────►│  5. Query with pagination │
   │                           │──────────────────────────►│
   │                           │  6. Return detection list │
   │◄──────────────────────────│                           │
   │                           │                           │
   │  7. Render map + cards    │                           │
   │     with detection data   │                           │
```

### Flow 3: Offline Upload (Mobile Queue → Retry)

```
📱 Mobile
   │
   │  1. Detection detected
   │  2. Network unavailable
   │  3. Save to Hive queue (upload_queue box)
   │
   │  ... waiting for network ...
   │
   │  4. Connectivity restored
   │  5. OfflineQueueService triggers retry
   │  6. Upload each queued detection
   │  7. Remove from queue on success
```

---

## 🛠️ Technology Stack

| Komponen | Teknologi | Versi | Lisensi |
|----------|-----------|-------|---------|
| **Mobile Framework** | Flutter | 3.x | BSD-3 |
| **Mobile State** | Provider | 6.1.2 | MIT |
| **Mobile Storage** | Hive | 2.2.3 | Apache-2.0 |
| **Mobile AI** | tflite_flutter | 0.10.4 | MIT |
| **Mobile HTTP** | Dio | 5.4.3 | MIT |
| **Mobile Camera** | camera | 0.11.0 | Apache-2.0 |
| **Mobile GPS** | geolocator | 11.0.0 | MIT |
| **Mobile Network** | connectivity_plus | 6.0.3 | BSD-3 |
| **Backend Framework** | FastAPI | 0.110+ | MIT |
| **Backend ORM** | SQLAlchemy | 2.0+ | MIT |
| **Backend DB Driver** | asyncpg | 0.29+ | Apache-2.0 |
| **Backend Auth** | python-jose | 3.3+ | MIT |
| **Backend Password** | passlib + bcrypt | 1.7+ | BSD-3 |
| **Backend Storage** | MinIO (Python) | 7.2+ | Apache-2.0 |
| **Backend Migration** | Alembic | 1.13+ | MIT |
| **Database** | PostgreSQL | 15+ | PostgreSQL |
| **Object Storage** | MinIO | Latest | AGPL-3.0 |
| **Dashboard Framework** | Next.js | 14 | MIT |
| **Dashboard UI** | React | 18.3 | MIT |
| **Dashboard Styling** | Tailwind CSS | 4 | MIT |
| **Dashboard Maps** | Leaflet | 1.9.4 | BSD-2 |
| **Dashboard HTTP** | Axios | 1.7 | MIT |
| **Dashboard Icons** | Lucide React | 0.378 | ISC |

---

## 🚀 Deployment Architecture

### Development Environment

```
┌─────────────────────────────────────────┐
│           localhost (Developer)          │
│                                         │
│  :8000  FastAPI (uvicorn --reload)     │
│  :3000  Next.js (npm run dev)          │
│  :5432  PostgreSQL                     │
│  :9000  MinIO Console                  │
│  :9001  MinIO API                      │
└─────────────────────────────────────────┘
```

### Production Environment (Docker Compose)

```
┌─────────────────────────────────────────────────────────┐
│                   Docker Network                        │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌───────────────┐  │
│  │ Backend      │  │ Dashboard   │  │ PostgreSQL    │  │
│  │ Container    │  │ Container   │  │ Container     │  │
│  │ :8000        │  │ :3000       │  │ :5432         │  │
│  └──────┬───────┘  └──────┬──────┘  └───────────────┘  │
│         │                  │                            │
│         └──────────┬───────┘                            │
│                    │                                    │
│              ┌─────┴──────┐                            │
│              │ MinIO      │                            │
│              │ Container  │                            │
│              │ :9000/:9001│                            │
│              └────────────┘                            │
└─────────────────────────────────────────────────────────┘
                      │
              ┌───────┴────────┐
              │ Reverse Proxy  │
              │ (Nginx/Caddy)  │
              │ :80 / :443     │
              └────────────────┘
```

### Production Considerations

| Aspek | Development | Production |
|-------|-------------|------------|
| CORS | `allow_origins=["*"]` | Specific domains only |
| DEBUG | `True` | `False` |
| JWT Secret | Default value | Strong random key |
| Database | Local PostgreSQL | Managed PostgreSQL (RDS, Supabase) |
| Storage | Local MinIO | AWS S3 / MinIO cluster |
| HTTPS | HTTP only | TLS via reverse proxy |

---

## 🔒 Security Considerations

### Authentication & Authorization

- **JWT Tokens**: HS256 algorithm, 24 jam expiry
- **Password Hashing**: bcrypt via passlib
- **Protected Endpoints**: `PATCH /api/detections/{id}/status` requires valid JWT
- **Public Endpoints**: `POST /api/detections`, `GET /api/detections`, `GET /api/statistics`

### Data Security

- Password tidak pernah disimpan dalam plaintext
- JWT secret harus diganti di production
- CORS harus dibatasi di production
- File upload divalidasi berdasarkan content type (JPEG, PNG, WebP)

### Network Security

- HTTPS di production via reverse proxy
- Rate limiting (future enhancement)
- MinIO access key harus aman

### Environment Variables

Semua sensitive values harus disimpan di `.env` file:
- `DATABASE_URL` — Connection string PostgreSQL
- `JWT_SECRET` — Secret key untuk signing JWT
- `MINIO_ACCESS_KEY` / `MINIO_SECRET_KEY` — Kredensial MinIO

**Jangan pernah commit `.env` file ke repository!**

---

## 📐 Design Decisions

| Keputusan | Alasan |
|-----------|--------|
| Async SQLAlchemy | Performa tinggi untuk I/O-bound operations |
| TFLite on-device | Tidak butuh GPU server, inference cepat, hemat bandwidth |
| MinIO (S3-compatible) | Mudah migrasi ke AWS S3 di production |
| Hive (mobile storage) | Lebih cepat dari SQLite untuk key-value, async-ready |
| Provider (state management) | Simpel untuk app ukuran menengah, built-in Flutter |
| Tailwind CSS | Utility-first, konsisten, cepat development |
| PostGIS-ready schema | Spatial queries untuk fitur masa depan |
