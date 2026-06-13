# 🗺️ Roadmap Pengembangan

Rencana pengembangan JalanCerdas AI dari MVP hingga produksi skala nasional.

---

## 📅 Timeline Overview

```
Phase 1         Phase 2         Phase 3         Phase 4
MVP             Multi-Class     User Accounts   Real-time
(Current)       Detection       System          Alerts
Jan-Mar 2025    Apr-Jun 2025    Jul-Sep 2025    Oct-Dec 2025
   │                │                │                │
   ▼                ▼                ▼                ▼
Phase 5         Phase 6         Phase 7
Analytics &     Gov API         Multi-City
Reporting       Integration     Deployment
Jan-Mar 2026    Apr-Jun 2026    Jul-Dec 2026
```

---

## ✅ Phase 1: MVP (Current)

**Status: IN PROGRESS**

### Goal
Sistem deteksi lubang jalan berbasis AI yang berfungsi penuh untuk satu kota.

### Deliverables

| Komponen | Status | Detail |
|----------|--------|--------|
| Mobile App (Flutter) | ✅ Done | Camera + TFLite inference + GPS |
| Backend API (FastAPI) | ✅ Done | CRUD, Auth, Upload, Statistics |
| Dashboard (Next.js) | ✅ Done | Login, Map, Stats, Reports |
| PostgreSQL Database | ✅ Done | Async ORM, Alembic migrations |
| MinIO Storage | ✅ Done | Image upload + fallback |
| Mock Detection Mode | ✅ Done | Development without AI model |
| Seed Data | ✅ Done | 15 dummy detections |
| Offline Queue | ✅ Done | Hive-based upload queue |

### Key Features
- [x] Deteksi lubang menggunakan kamera mobile
- [x] On-device inference (TFLite)
- [x] Upload gambar + metadata ke backend
- [x] Peta interaktif di dashboard
- [x] Statistik ringkasan
- [x] CRUD laporan dengan status tracking
- [x] JWT authentication
- [x] Offline mode dengan auto-retry

### Tech Stack
- Flutter 3.x + Provider + Hive
- FastAPI + SQLAlchemy + PostgreSQL
- Next.js 14 + Tailwind + Leaflet
- TFLite + YOLO-based model
- MinIO (S3-compatible)

---

## 🔮 Phase 2: Multi-Class Detection

**Target: Q2 2025**

### Goal
Deteksi berbagai jenis kerusakan jalan, bukan hanya lubang.

### Features

| Feature | Deskripsi | Prioritas |
|---------|-----------|-----------|
| Crack Detection | Deteksi retakan jalan | 🔴 High |
| Depression Detection | Deteksi penurunan/cekungan | 🔴 High |
| Bump Detection | Deteksi tonjolan/gundukan | 🟡 Medium |
| Severity Classification | Klasifikasi tingkat keparahan | 🟡 Medium |
| Multi-detection per frame | Beberapa deteksi dalam 1 frame | 🟡 Medium |
| Custom model training | Fine-tune dengan dataset lokal | 🟢 Low |

### Dataset Requirements
- Minimal 1000 gambar per kelas kerusakan
- Annotasi bounding box dalam format YOLO
- Variasi kondisi: siang/malam, basah/kering, berbagai aspal
- Sumber: Koleksi sendiri + dataset publik (RDD2022, etc.)

### Model Improvements
- Train model YOLOv8n custom dengan dataset Indonesia
- Export ke TFLite dengan quantization (INT8)
- Target inference time: <100ms per frame
- Target mAP: >0.75

---

## 👤 Phase 3: User Accounts

**Target: Q3 2025**

### Goal
Sistem user multi-level dengan role-based access control.

### Features

| Feature | Deskripsi | Prioritas |
|---------|-----------|-----------|
| User Registration | Self-registration untuk masyarakat | 🔴 High |
| Role System | Admin, Operator, Masyarakat | 🔴 High |
| Profile Management | Edit profile, avatar, bio | 🟡 Medium |
| User Dashboard | Statistik personal per user | 🟡 Medium |
| Leaderboard | Top contributor (gamification) | 🟢 Low |
| Email Verification | Verifikasi email saat register | 🟢 Low |

### Role Definitions

| Role | Permission |
|------|-----------|
| **Admin** | Full access: CRUD, status update, user management |
| **Operator** | View all, update status, export reports |
| **Masyarakat** | Submit detections, view own history |

### Database Changes
```sql
-- Extend users table
ALTER TABLE users ADD COLUMN role VARCHAR(20) DEFAULT 'masyarakat';
ALTER TABLE users ADD COLUMN email VARCHAR(255);
ALTER TABLE users ADD COLUMN display_name VARCHAR(100);
ALTER TABLE users ADD COLUMN avatar_url TEXT;
ALTER TABLE users ADD COLUMN is_verified BOOLEAN DEFAULT false;

-- Detection ownership
ALTER TABLE detections ADD COLUMN user_id UUID REFERENCES users(id);
```

---

## 📲 Phase 4: Real-time Alerts

**Target: Q4 2025**

### Goal
Notifikasi real-time untuk deteksi baru di area tertentu.

### Features

| Feature | Deskripsi | Prioritas |
|---------|-----------|-----------|
| Push Notifications | Firebase Cloud Messaging | 🔴 High |
| Area-based Alerts | Alert untuk area/radius tertentu | 🔴 High |
| WebSocket Updates | Live dashboard updates | 🟡 Medium |
| Email Reports | Daily/weekly email summary | 🟢 Low |
| Telegram Bot | Alert via Telegram | 🟢 Low |

### Architecture
```
Mobile → Backend → Notification Service
                      │
                 ┌────┴────┐
                 │ FCM     │ Push ke devices
                 │ WebSocket│ Dashboard live
                 │ Email   │ Email reports
                 └─────────┘
```

### API Additions
```
POST /api/alerts/subscribe    — Subscribe area alerts
DELETE /api/alerts/subscribe  — Unsubscribe
GET /api/alerts/preferences  — Get alert settings
PATCH /api/alerts/preferences — Update alert settings
```

---

## 📊 Phase 5: Analytics & Reporting

**Target: Q1 2026**

### Goal
Analisis mendalam dan pelaporan otomatis untuk pengambil kebijakan.

### Features

| Feature | Deskripsi | Prioritas |
|---------|-----------|-----------|
| Time Series Analysis | Tren deteksi per waktu | 🔴 High |
| Heatmap View | Peta heatmap kerusakan | 🔴 High |
| Area Statistics | Stat per kecamatan/kota | 🟡 Medium |
| Export Reports | PDF/Excel export | 🟡 Medium |
| Trend Prediction | Prediksi kerusakan masa depan | 🟢 Low |
| Road Quality Index | Indeks kualitas jalan | 🟢 Low |

### Dashboard Additions
- Time series chart (per hari/minggu/bulan)
- Heatmap overlay di peta
- Area comparison charts
- Export button (PDF, CSV, Excel)
- Filter by date range, area, damage type

### Analytics API
```
GET /api/analytics/timeseries   — Data time series
GET /api/analytics/heatmap      — Heatmap data points
GET /api/analytics/area/{id}    — Area-specific stats
GET /api/analytics/trends       — Trend analysis
GET /api/analytics/export       — Export reports
```

---

## 🏛️ Phase 6: Government API Integration

**Target: Q2 2026**

### Goal
Integrasi dengan sistem pemerintah untuk aksi nyata perbaikan jalan.

### Features

| Feature | Deskripsi | Prioritas |
|---------|-----------|-----------|
| Public API | REST API untuk instansi pemerintah | 🔴 High |
| Data Sharing | Export data ke format standar pemerintah | 🔴 High |
| Dinas PU Integration | Kirim laporan ke Dinas Pekerjaan Umum | 🟡 Medium |
| BPJN Integration | Integrasi dengan Balai PJJ Nasional | 🟡 Medium |
| Open Data | Portal data terbuka untuk peneliti | 🟢 Low |

### Public API
```
GET /api/public/detections      — Public detection list
GET /api/public/statistics      — Public statistics
GET /api/public/area/{area_id}  — Area report
```

### Standards Compliance
- Format sesuai standar data infrastruktur Indonesia
- Koordinat dalam format WGS84
- Export ke format GeoJSON, KML, Shapefile
- REST API dengan OpenAPI 3.0 spec

---

## 🌏 Phase 7: Multi-City Deployment

**Target: Q3-Q4 2026**

### Goal
Deployment skala nasional di beberapa kota besar Indonesia.

### Features

| Feature | Deskripsi | Prioritas |
|---------|-----------|-----------|
| Multi-tenant Architecture | Isolasi data per kota | 🔴 High |
| City Dashboard | Dashboard khusus per kota | 🔴 High |
| Kubernetes Deployment | Container orchestration | 🟡 Medium |
| CDN for Images | Content delivery network | 🟡 Medium |
| Performance Optimization | Caching, query optimization | 🟡 Medium |
| SLA Monitoring | Uptime & performance SLA | 🟢 Low |

### Target Cities

| Prioritas | Kota | Alasan |
|-----------|------|--------|
| 🥇 | Jakarta | Ibu kota, lalu lintas tinggi |
| 🥇 | Surabaya | Kota terbesar kedua |
| 🥈 | Bandung | Kota tech, ITB partnership |
| 🥈 | Yogyakarta | Kota pendidikan |
| 🥉 | Medan | Kota terbesar di Sumatera |
| 🥉 | Makassar | Kota terbesar di Sulawesi |
| 🥉 | Semarang | Kota metropolitan Jawa Tengah |
| 🥉 | Bali | Pariwisata internasional |

### Infrastructure Requirements
- Kubernetes cluster (3+ nodes)
- Managed PostgreSQL (RDS/Cloud SQL)
- S3-compatible storage (AWS S3 / MinIO cluster)
- CDN (Cloudflare / CloudFront)
- Load balancer (Nginx / AWS ALB)
- Monitoring (Prometheus + Grafana)

---

## 🎯 Long-term Vision (2027+)

### Advanced AI Features
- Multi-spectral imaging (thermal camera)
- Drone-based detection
- Video stream analysis (continuous detection)
- Predictive maintenance scheduling

### Smart City Integration
- IoT sensors di jalan utama
- Traffic data correlation
- Weather impact analysis
- Road age estimation

### Community Features
- Citizen reporting app
- Social features (comments, upvotes)
- Reward system (poin, badge)
- Verified reporter program

### Research & Development
- Dataset sharing platform
- Model benchmarking
- Academic partnerships
- Paper publication

---

## 📏 Success Metrics

### Phase 1 (MVP)
| Metric | Target |
|--------|--------|
| Detections per day | 100+ |
| Detection accuracy (mAP) | >0.70 |
| Upload success rate | >95% |
| App crash rate | <1% |

### Phase 3 (User Accounts)
| Metric | Target |
|--------|--------|
| Registered users | 1000+ |
| Daily active users | 100+ |
| Reports per user | 10+ |

### Phase 7 (Multi-City)
| Metric | Target |
|--------|--------|
| Cities deployed | 8+ |
| Total detections | 100,000+ |
| Uptime | >99.9% |
| Response time (p95) | <200ms |

---

## 🤝 Contributing

Setiap fase terbuka untuk kontribusi. Lihat `CONTRIBUTING.md` untuk panduan.

### Priority Labels
- 🔴 **High**: Core feature, blocking other work
- 🟡 **Medium**: Important, but can wait
- 🟢 **Low**: Nice to have, no blockers

### How to Contribute

1. Pick an issue dari GitHub
2. Assign ke diri sendiri
3. Buat branch: `feature/phase-X-feature-name`
4. Develop & test
5. Submit PR
6. Review & merge
