# 📜 Daftar Library dan Lisensi

Daftar lengkap semua dependensi yang digunakan dalam proyek JalanCerdas AI beserta lisensinya.

---

## 📱 Mobile App (Flutter/Dart)

| Library | Versi | Lisensi | Kegunaan |
|---------|-------|---------|----------|
| Flutter SDK | 3.x | BSD-3-Clause | Framework mobile cross-platform |
| Dart SDK | 3.0+ | BSD-3-Clause | Bahasa pemrograman |
| cupertino_icons | ^1.0.6 | MIT | Ikon iOS-style |
| camera | ^0.11.0+2 | Apache-2.0 | Akses kamera device |
| geolocator | ^11.0.0 | MIT | Akses GPS/lokasi |
| permission_handler | ^11.3.0 | MIT | Manajemen runtime permissions |
| dio | ^5.4.3+1 | MIT | HTTP client |
| connectivity_plus | ^6.0.3 | BSD-3-Clause | Monitoring status jaringan |
| hive | ^2.2.3 | Apache-2.0 | NoSQL local database (key-value) |
| hive_flutter | ^1.1.0 | Apache-2.0 | Hive Flutter integration |
| path_provider | ^2.1.3 | BSD-3-Clause | Akses direktori sistem |
| path | ^1.9.0 | BSD-3-Clause | Manipulasi path file |
| intl | ^0.19.0 | BSD-3-Clause | Internationalization & formatting |
| provider | ^6.1.2 | MIT | State management |
| image | ^4.2.0 | BSD-3-Clause | Image processing |
| tflite_flutter | ^0.10.4 | MIT | TensorFlow Lite inference |
| google_fonts | ^6.2.1 | BSD-3-Clause | Custom Google Fonts |
| flutter_speed_dial | ^7.0.0 | MIT | Floating action button menu |
| sqflite | ^2.3.3+1 | BSD-3-Clause | SQLite (backup/optional) |
| flutter_lints | ^4.0.0 | BSD-3-Clause | Lint rules |
| hive_generator | ^2.0.1 | Apache-2.0 | Hive TypeAdapter code gen |
| build_runner | ^2.4.10 | MIT | Code generation runner |
| hive_type_generator | ^2.0.1 | Apache-2.0 | Hive type annotation gen |

---

## 🖥️ Backend (Python)

| Library | Versi | Lisensi | Kegunaan |
|---------|-------|---------|----------|
| FastAPI | ≥0.110.0 | MIT | Async web framework |
| Uvicorn | ≥0.27.0 | BSD-3-Clause | ASGI server |
| SQLAlchemy | ≥2.0.25 | MIT | Async ORM |
| asyncpg | ≥0.29.0 | Apache-2.0 | PostgreSQL async driver |
| Pydantic Settings | ≥2.1.0 | MIT | Environment variable config |
| python-jose | ≥3.3.0 | MIT | JWT token handling |
| passlib | ≥1.7.4 | BSD-3-Clause | Password hashing utilities |
| bcrypt | ≥4.0.0 | Apache-2.0 | Bcrypt hashing backend |
| python-multipart | ≥0.0.6 | BSD-3-Clause | Multipart form data parsing |
| MinIO | ≥7.2.0 | Apache-2.0 | S3-compatible object storage |
| Alembic | ≥1.13.0 | MIT | Database migrations |

### Transitive Dependencies

| Library | Lisensi | Digunakan Oleh |
|---------|---------|----------------|
| starlette | BSD-3 | FastAPI |
| anyio | MIT | FastAPI, Starlette |
| pydantic | MIT | FastAPI |
| typing_extensions | PSF | Pydantic |
| h11 | MIT | Uvicorn |
| click | BSD-3 | Uvicorn |
| greenlet | MIT | SQLAlchemy |
| Mako | MIT | Alembic |
| markupsafe | BSD-3 | Mako |

---

## 💻 Dashboard (JavaScript/TypeScript)

### Dependencies

| Library | Versi | Lisensi | Kegunaan |
|---------|-------|---------|----------|
| Next.js | ^14.2.0 | MIT | React framework (SSR/SSG) |
| React | ^18.3.0 | MIT | UI library |
| React DOM | ^18.3.0 | MIT | React DOM renderer |
| Leaflet | ^1.9.4 | BSD-2-Clause | Peta interaktif |
| react-leaflet | ^4.2.1 | MIT | React wrapper untuk Leaflet |
| Axios | ^1.7.0 | MIT | HTTP client |
| Lucide React | ^0.378.0 | ISC | Ikon library |
| clsx | ^2.1.0 | MIT | Class name utility |
| tailwind-merge | ^2.3.0 | MIT | Tailwind class merger |

### Dev Dependencies

| Library | Versi | Lisensi | Kegunaan |
|---------|-------|---------|----------|
| TypeScript | ^5.4.0 | Apache-2.0 | Type system |
| @types/react | ^18.3.0 | MIT | React type definitions |
| @types/react-dom | ^18.3.0 | MIT | ReactDOM type definitions |
| @types/leaflet | ^1.9.8 | MIT | Leaflet type definitions |
| @types/node | ^20.12.0 | MIT | Node.js type definitions |
| Tailwind CSS | ^4.0.0 | MIT | Utility-first CSS framework |
| @tailwindcss/postcss | ^4.0.0 | MIT | PostCSS plugin untuk Tailwind |
| PostCSS | ^8.4.0 | MIT | CSS transformer |

### Transitive Dependencies (Notable)

| Library | Lisensi | Digunakan Oleh |
|---------|---------|----------------|
| swc | Apache-2.0 | Next.js (bundling) |
| esbuild | MIT | Next.js |
| caniuse-lite | CC-BY-4.0 | PostCSS, Tailwind |
| postcss-selector-parser | MIT | PostCSS |

---

## 🤖 AI / Machine Learning

| Library | Versi | Lisensi | Kegunaan |
|---------|-------|---------|----------|
| Ultralytics (YOLO) | Latest | AGPL-3.0 | Model training & export |
| TensorFlow Lite | Latest | Apache-2.0 | On-device inference |
| tflite_flutter | ^0.10.4 | MIT | TFLite binding untuk Dart |

> ⚠️ **Catatan Lisensi AGPL-3.0 (Ultralytics)**:
> Digunakan hanya untuk training dan export model, bukan untuk distribusi.
> Aplikasi mobile menggunakan TFLite model yang sudah di-export.
> Jika menggunakan Ultralytics dalam produksi, pastikan comply dengan AGPL-3.0 terms.

---

## 🗄️ Infrastructure

| Software | Versi | Lisensi | Kegunaan |
|----------|-------|---------|----------|
| PostgreSQL | 15+ | PostgreSQL License | Relational database |
| MinIO | Latest | AGPL-3.0 | S3-compatible object storage |
| Docker | Latest | Apache-2.0 | Container platform |
| Nginx | Latest | BSD-2-Clause | Reverse proxy (production) |

---

## 📊 Lisensi Summary

| License | Jumlah | Contoh Library |
|---------|--------|----------------|
| MIT | 20+ | FastAPI, React, Next.js, Provider, Dio |
| Apache-2.0 | 8+ | MinIO, camera, asyncpg, bcrypt, TFLite |
| BSD-3-Clause | 8+ | Flutter, geolocator, Uvicorn, image |
| BSD-2-Clause | 3+ | Leaflet, Nginx |
| ISC | 1 | Lucide React |
| AGPL-3.0 | 2 | Ultralytics, MinIO (server) |
| PostgreSQL License | 1 | PostgreSQL |

---

## ⚠️ Lisensi yang Perlu Diperhatikan

### AGPL-3.0 (Ultralytics YOLO)

- Digunakan untuk **training** model saja
- Model yang sudah di-export (TFLite) bisa didistribusikan secara independen
- Backend dan mobile app **tidak** menggunakan Ultralytics secara langsung
- Pastikan tidak ada linking/combining dengan code proyek jika di-deploy sebagai service

### AGPL-3.0 (MinIO Server)

- MinIO server berjalan terpisah sebagai service
- API yang digunakan bersifat network-based (S3 API)
- Tidak memerlukan open-source dari sisi client
- Jika menggunakan MinIO embedded/bundled dalam binary, perlu comply AGPL

### PostgreSQL License

- Sangat permisif, mirip MIT/BSD
- Bisa digunakan komersial tanpa batasan
- Tidak memerlukan disclosure source code

---

## 📝 Catatan untuk Kompetisi

Untuk keperluan kompetisi hackathon/innovation:
- Semua library yang digunakan tersedia secara bebas
- Lisensi MIT/BSD/Apache kompatibel untuk komersial dan kompetisi
- AGPL dependencies (Ultralytics, MinIO) hanya digunakan untuk infrastructure/training
- Tidak ada library proprietari yang digunakan
