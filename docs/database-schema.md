# 🗄️ Database Schema

Skema database lengkap untuk JalanCerdas AI Backend.

---

## 📊 ER Diagram

```
┌──────────────────────────────┐          ┌──────────────────────────────┐
│         users                │          │        detections            │
├──────────────────────────────┤          ├──────────────────────────────┤
│ id          UUID (PK)        │          │ id            UUID (PK)      │
│ username    VARCHAR(100)     │          │ damage_type   VARCHAR(100)   │
│             UNIQUE, INDEXED  │          │ confidence    FLOAT          │
│ password_hash VARCHAR(255)   │          │ latitude      FLOAT          │
│ created_at  TIMESTAMPTZ      │          │ longitude     FLOAT          │
│             NOT NULL         │          │ image_url     TEXT           │
└──────────────────────────────┘          │ detected_at   TIMESTAMPTZ   │
                                          │ status        VARCHAR(50)   │
                                          │ created_at    TIMESTAMPTZ   │
                                          │               NOT NULL      │
                                          │ updated_at    TIMESTAMPTZ   │
                                          │               NOT NULL      │
                                          └──────────────────────────────┘

Status Flow:
┌─────┐    ┌───────────────┐    ┌──────────┐    ┌─────────┐
│ Baru │───►│ Terverifikasi │───►│ Diproses │───►│ Selesai │
└─────┘    └───────────────┘    └──────────┘    └─────────┘
```

---

## 📋 Tabel: `detections`

Menyimpan data deteksi kerusakan jalan (lubang, retakan, dll).

| Field | Type | Nullable | Default | Deskripsi |
|-------|------|----------|---------|-----------|
| `id` | UUID | ❌ | `uuid4()` | Primary key, auto-generated |
| `damage_type` | VARCHAR(100) | ❌ | — | Tipe kerusakan (Pothole, Crack, dll) |
| `confidence` | FLOAT | ❌ | — | Confidence score model AI (0.0 - 1.0) |
| `latitude` | FLOAT | ❌ | — | Koordinat GPS latitude |
| `longitude` | FLOAT | ❌ | — | Koordinat GPS longitude |
| `image_url` | TEXT | ✅ | `""` | URL/path gambar deteksi |
| `detected_at` | TIMESTAMPTZ | ✅ | `now(utc)` | Waktu deteksi terjadi |
| `status` | VARCHAR(50) | ❌ | `"Baru"` | Status penanganan |
| `created_at` | TIMESTAMPTZ | ❌ | `now(utc)` | Waktu record dibuat |
| `updated_at` | TIMESTAMPTZ | ❌ | `now(utc)` | Waktu record terakhir diupdate |

### Deskripsi Setiap Field

#### `id` (UUID)
Primary key unik untuk setiap deteksi. Auto-generated menggunakan `uuid4()`.

```python
id: Mapped[uuid.UUID] = mapped_column(
    UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
)
```

#### `damage_type` (VARCHAR)
Tipe kerusakan yang terdeteksi oleh model AI.

Valid values:
- `Pothole` — Lubang di permukaan jalan
- `Crack` — Retakan jalan
- `Depression` — Penurunan/cekungan permukaan
- `Bump` — Tonjolan/gundukan
- `Other` — Kerusakan lainnya

#### `confidence` (FLOAT)
Confidence score dari model deteksi. Rentang 0.0 sampai 1.0.

- `> 0.90` — Sangat yakin
- `0.70 - 0.90` — Yakin
- `0.50 - 0.70` — Cukup yakin
- `< 0.50` — Kurang yakin (biasanya difilter oleh model)

#### `latitude` & `longitude` (FLOAT)
Koordinat GPS lokasi deteksi dalam format WGS84.

- Latitude: -90.0 sampai 90.0
- Longitude: -180.0 sampai 180.0

#### `image_url` (TEXT)
URL atau path ke gambar deteksi. Bisa berupa:
- MinIO URL: `http://localhost:9000/road-detections/2025/01/15/uuid.jpg`
- Placeholder URL: `https://via.placeholder.com/400x300/jakarta1.jpg`
- Local path fallback: `uploads/2025/01/15/uuid.jpg`

#### `detected_at` (TIMESTAMPTZ)
Timestamp ketika deteksi terjadi di lapangan. Bisa berbeda dari `created_at` jika data dikirim terlambat (offline mode).

#### `status` (VARCHAR)
Status penanganan kerusakan jalan.

| Status | Deskripsi |
|--------|-----------|
| `Baru` | Deteksi baru, belum ditangani |
| `Terverifikasi` | Telah diverifikasi oleh admin |
| `Diproses` | Sedang dalam proses perbaikan |
| `Selesai` | Perbaikan selesai |

#### `created_at` & `updated_at` (TIMESTAMPTZ)
Timestamp otomatis untuk tracking. `updated_at` di-update otomatis setiap perubahan.

---

## 📋 Tabel: `users`

Menyimpan credentials user untuk autentikasi.

| Field | Type | Nullable | Default | Deskripsi |
|-------|------|----------|---------|-----------|
| `id` | UUID | ❌ | `uuid4()` | Primary key, auto-generated |
| `username` | VARCHAR(100) | ❌ | — | Username unik untuk login |
| `password_hash` | VARCHAR(255) | ❌ | — | Bcrypt hash dari password |
| `created_at` | TIMESTAMPTZ | ❌ | `now(utc)` | Waktu akun dibuat |

### Deskripsi Setiap Field

#### `id` (UUID)
Primary key unik untuk setiap user. Digunakan sebagai `sub` claim di JWT token.

#### `username` (VARCHAR)
Username unik untuk login. Memiliki unique constraint dan index.

```python
username: Mapped[str] = mapped_column(
    String(100), unique=True, nullable=False, index=True
)
```

#### `password_hash` (VARCHAR)
Password yang sudah di-hash menggunakan bcrypt. Tidak menyimpan plaintext.

```python
# Hashing
from passlib.context import CryptContext
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
hashed = pwd_context.hash("admin123")

# Verification
pwd_context.verify("admin123", hashed)  # True
```

---

## 🔍 Indexes

### Indexes yang ada

| Table | Field | Type | Keterangan |
|-------|-------|------|------------|
| `users` | `username` | B-Tree (unique) | Unique lookup untuk login |
| `detections` | `created_at` | B-Tree (implicit) | Sorting by newest |

### Indexes yang disarankan untuk production

```sql
-- Filter by status (query sering)
CREATE INDEX idx_detections_status ON detections(status);

-- Spatial queries (jika pakai PostGIS)
CREATE INDEX idx_detections_location ON detections
  USING GIST (ST_Point(longitude, latitude));

-- Composite index untuk dashboard query
CREATE INDEX idx_detections_status_created
  ON detections(status, created_at DESC);

-- Confidence threshold filter
CREATE INDEX idx_detections_confidence
  ON detections(confidence) WHERE confidence > 0.5;
```

---

## 🌍 PostGIS Extension

Untuk fitur spatial queries di masa depan (nearest pothole, area-based filtering, dll).

### Aktifkan PostGIS

```bash
# Di PostgreSQL
psql -U postgres -d jalancerdas -c "CREATE EXTENSION IF NOT EXISTS postgis;"
```

### Schema dengan PostGIS

```sql
-- Tambah kolom geom
ALTER TABLE detections ADD COLUMN geom GEOMETRY(Point, 4326);

-- Update geom dari lat/lng
UPDATE detections
SET geom = ST_SetSRID(ST_Point(longitude, latitude), 4326)
WHERE geom IS NULL;

-- Index spatial
CREATE INDEX idx_detections_geom ON detections USING GIST(geom);
```

### Contoh Spatial Queries

```sql
-- Cari deteksi dalam radius 5km
SELECT * FROM detections
WHERE ST_DWithin(
  geom::geography,
  ST_SetSRID(ST_Point(106.8456, -6.2088), 4326)::geography,
  5000
);

-- Hitung jarak terdekat
SELECT *, ST_Distance(
  geom::geography,
  ST_SetSRID(ST_Point(106.8456, -6.2088), 4326)::geography
) AS distance_meters
FROM detections
ORDER BY distance_meters
LIMIT 10;
```

---

## 🔄 Migration Instructions

### Menggunakan Alembic

**Setup awal:**
```bash
cd backend

# Generate migration pertama
alembic revision --autogenerate -m "initial tables"

# Apply migration
alembic upgrade head
```

**Update model dan generate migration baru:**
```bash
# 1. Edit model files di app/models/
# 2. Generate migration
alembic revision --autogenerate -m "add new column"
# 3. Review generated file di alembic/versions/
# 4. Apply
alembic upgrade head
```

**Rollback migration:**
```bash
# Undo last migration
alembic downgrade -1

# Undo to specific revision
alembic downgrade <revision_id>
```

**Check current migration:**
```bash
alembic current
alembic history
```

### Auto Table Creation (Development)

Di development, tables dibuat otomatis saat server start:

```python
# app/database.py
async def init_db() -> None:
    """Create all tables defined in models."""
    from app.models import detection, user
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
```

> ⚠️ Gunakan Alembic di production. Auto-create tidak mendeteksi perubahan schema.

---

## 📊 Seed Data

Seed endpoint membuat data berikut:

### Admin User
- Username: `admin`
- Password: `admin123` (bcrypt hashed)

### 15 Dummy Detections

| Kota | damage_type | confidence | Status |
|------|-------------|------------|--------|
| Jakarta | Pothole | 0.92 | Baru |
| Jakarta | Crack | 0.85 | Terverifikasi |
| Jakarta | Pothole | 0.78 | Diproses |
| Bandung | Crack | 0.95 | Selesai |
| Bandung | Pothole | 0.88 | Baru |
| Surabaya | Pothole | 0.91 | Baru |
| Surabaya | Crack | 0.72 | Terverifikasi |
| Yogyakarta | Pothole | 0.83 | Diproses |
| Yogyakarta | Crack | 0.96 | Selesai |
| Medan | Pothole | 0.89 | Baru |
| Medan | Crack | 0.67 | Terverifikasi |
| Makassar | Pothole | 0.93 | Diproses |
| Semarang | Crack | 0.76 | Baru |
| Semarang | Pothole | 0.87 | Selesai |
| Bali | Crack | 0.94 | Baru |

---

## 📝 Model Code Reference

### Detection Model (`app/models/detection.py`)

```python
from sqlalchemy import DateTime, Float, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime, timezone
import uuid

class Detection(Base):
    __tablename__ = "detections"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    damage_type: Mapped[str] = mapped_column(String(100), nullable=False)
    confidence: Mapped[float] = mapped_column(Float, nullable=False)
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    image_url: Mapped[str] = mapped_column(Text, nullable=True, default="")
    detected_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=True,
        default=lambda: datetime.now(timezone.utc)
    )
    status: Mapped[str] = mapped_column(
        String(50), nullable=False, default="Baru"
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False,
        default=lambda: datetime.now(timezone.utc)
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )
```

### User Model (`app/models/user.py`)

```python
class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    username: Mapped[str] = mapped_column(
        String(100), unique=True, nullable=False, index=True
    )
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False,
        default=lambda: datetime.now(timezone.utc)
    )
```
