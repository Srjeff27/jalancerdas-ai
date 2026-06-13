# 📚 Dokumentasi JalanCerdas AI

Dokumentasi lengkap untuk sistem deteksi lubang jalan berbasis AI.

## 📁 Struktur Dokumentasi

| No | File | Deskripsi |
|----|------|-----------|
| 1 | [Arsitektur Sistem](arsitektur-sistem.md) | Arsitektur tingkat tinggi, komponen, data flow, dan stack teknologi |
| 2 | [Instalasi Backend](instalasi-backend.md) | Panduan instalasi API server FastAPI + PostgreSQL + MinIO |
| 3 | [Instalasi Dashboard](instalasi-dashboard.md) | Panduan instalasi web dashboard Next.js |
| 4 | [Instalasi Mobile](instalasi-mobile.md) | Panduan instalasi aplikasi mobile Flutter |
| 5 | [API Documentation](api-documentation.md) | Referensi lengkap semua endpoint REST API |
| 6 | [Database Schema](database-schema.md) | Skema database, tabel, index, dan relasi |
| 7 | [User Guide: Mobile](user-guide-mobile.md) | Panduan penggunaan aplikasi mobile |
| 8 | [User Guide: Dashboard](user-guide-dashboard.md) | Panduan penggunaan web dashboard |
| 9 | [Daftar Library & Lisensi](daftar-library-lisensi.md) | Semua dependensi dan lisensi yang digunakan |
| 10 | [Roadmap Pengembangan](roadmap-pengembangan.md) | Rencana pengembangan fase demi fase |

## 🚀 Quick Start

```bash
# 1. Clone repository
git clone https://github.com/username/jalancerdas-ai.git
cd jalancerdas-ai

# 2. Install & jalankan backend
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --reload

# 3. Install & jalankan dashboard
cd ../dashboard
npm install
npm run dev

# 4. Install & jalankan mobile
cd ../mobile
flutter pub get
flutter run
```

## 📋 Prerequisites

- **Backend**: Python 3.11+, PostgreSQL 15+, MinIO
- **Dashboard**: Node.js 18+, npm/yarn
- **Mobile**: Flutter 3.x, Android Studio / Xcode

## 📞 Kontak

Untuk pertanyaan teknis, buka GitHub Issues di repository utama.
