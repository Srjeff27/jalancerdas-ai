# 🔧 Instalasi Backend API

Panduan lengkap menginstal dan menjalankan backend API server JalanCerdas AI.

---

## 📋 Prerequisites

| Komponen | Versi Minimum | Cek Versi |
|----------|--------------|-----------|
| Python | 3.11+ | `python3 --version` |
| pip | 22+ | `pip --version` |
| PostgreSQL | 15+ | `psql --version` |
| MinIO | Latest | `minio --version` |
| Git | Any | `git --version` |

---

## 🚀 Manual Installation

### 1. Clone Repository

```bash
git clone https://github.com/username/jalancerdas-ai.git
cd jalancerdas-ai/backend
```

### 2. Buat Virtual Environment

```bash
python3 -m venv .venv
source .venv/bin/activate
```

**Verify:**
```bash
which python3
# Harusnya menunjukkan path ke .venv/bin/python3
```

### 3. Install Dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

**Dependencies yang terinstall:**
```
fastapi>=0.110.0       # Async web framework
uvicorn[standard]      # ASGI server
sqlalchemy[asyncio]    # Async ORM
asyncpg                # PostgreSQL async driver
pydantic-settings      # Environment variable management
python-jose[cryptography]  # JWT tokens
passlib[bcrypt]        # Password hashing
python-multipart       # File upload support
minio                  # S3-compatible object storage client
alembic                # Database migrations
bcrypt                 # Password hashing backend
```

### 4. Konfigurasi Environment Variables

```bash
cp .env.example .env
```

Edit file `.env` sesuai kebutuhan:

```env
# Database
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/jalancerdas

# MinIO Object Storage
MINIO_ENDPOINT=localhost:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_BUCKET=road-detections
MINIO_SECURE=false

# JWT Authentication
JWT_SECRET=super-secret-jalancerdas-key-change-in-production
JWT_ALGORITHM=HS256
JWT_EXPIRE_MINUTES=1440

# Application
APP_NAME=JalanCerdas AI
APP_VERSION=1.0.0
DEBUG=true
```

> ⚠️ **Penting**: Ganti `JWT_SECRET` dengan string random yang kuat di production!

### 5. Setup PostgreSQL

```bash
# Buat database
psql -U postgres -c "CREATE DATABASE jalancerdas;"
```

Atau menggunakan Docker:
```bash
docker run -d \
  --name jalancerdas-db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=jalancerdas \
  -p 5432:5432 \
  postgres:15-alpine
```

### 6. Database Migration / Table Creation

Tables akan otomatis dibuat saat server pertama kali dijalankan (melalui `init_db()` di `database.py`).

Untuk menggunakan Alembic migrations:
```bash
# Generate migration dari model
alembic revision --autogenerate -m "initial tables"

# Apply migration
alembic upgrade head
```

### 7. Seed Data

Setelah server berjalan, jalankan seed endpoint untuk membuat data dummy:

```bash
curl -X POST http://localhost:8000/api/seed
```

**Response:**
```json
{
  "message": "Seed data created successfully",
  "detections_created": 15,
  "admin_created": true,
  "admin_credentials": {
    "username": "admin",
    "password": "admin123"
  }
}
```

### 8. Jalankan Development Server

```bash
# Menggunakan uvicorn langsung
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# Atau menggunakan Python
python -m app.main
```

**Server akan berjalan di:**
- API: http://localhost:8000
- Swagger Docs: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
- Health Check: http://localhost:8000/health

### 9. Verifikasi Instalasi

```bash
# Health check
curl http://localhost:8000/health
# Expected: {"status":"healthy","version":"1.0.0"}

# Login (setelah seed)
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# List detections
curl http://localhost:8000/api/detections
```

---

## 🐳 Docker Installation

### 1. Build Image

```bash
cd backend
docker build -t jalancerdas-backend .
```

**Dockerfile contents:**
```dockerfile
FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 2. Jalankan Container

```bash
# Dengan environment variables
docker run -d \
  --name jalancerdas-api \
  -p 8000:8000 \
  -e DATABASE_URL=postgresql+asyncpg://postgres:postgres@host.docker.internal:5432/jalancerdas \
  -e MINIO_ENDPOINT=host.docker.internal:9000 \
  -e MINIO_ACCESS_KEY=minioadmin \
  -e MINIO_SECRET_KEY=minioadmin \
  -e JWT_SECRET=your-production-secret-here \
  -e DEBUG=false \
  jalancerdas-backend
```

### 3. Docker Compose (Full Stack)

Buat file `docker-compose.yml` di root project:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: jalancerdas
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

  minio:
    image: minio/minio
    command: server /data --console-address ":9001"
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    volumes:
      - miniodata:/data

  backend:
    build: ./backend
    ports:
      - "8000:8000"
    environment:
      DATABASE_URL: postgresql+asyncpg://postgres:postgres@postgres:5432/jalancerdas
      MINIO_ENDPOINT: minio:9000
      MINIO_ACCESS_KEY: minioadmin
      MINIO_SECRET_KEY: minioadmin
      JWT_SECRET: change-me-in-production
      DEBUG: "false"
    depends_on:
      - postgres
      - minio

  dashboard:
    build: ./dashboard
    ports:
      - "3000:3000"
    environment:
      NEXT_PUBLIC_API_URL: http://localhost:8000

volumes:
  pgdata:
  miniodata:
```

Jalankan:
```bash
docker compose up -d
docker compose logs -f backend
```

---

## 🐍 Troubleshooting

### Error: `asyncpg` compilation failed

```bash
# Install system dependencies (Ubuntu/Debian)
sudo apt-get install gcc libpq-dev

# Atau install dengan pip flags
pip install asyncpg --no-cache-dir
```

### Error: `ModuleNotFoundError: No module named 'app'`

```bash
# Pastikan Anda di direktori backend/
cd jalancerdas-ai/backend

# Pastikan virtual environment aktif
source .venv/bin/activate

# Jalankan dari root backend
uvicorn app.main:app --reload
```

### Error: `Connection refused` ke PostgreSQL

```bash
# Cek apakah PostgreSQL berjalan
sudo systemctl status postgresql

# Atau restart
sudo systemctl restart postgresql

# Pastikan database ada
psql -U postgres -c "\l" | grep jalancerdas
```

### Error: MinIO connection refused

MinIO adalah optional. Backend akan fallback ke local path jika MinIO tidak tersedia.

Untuk menjalankan MinIO:
```bash
# Docker
docker run -d -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin \
  minio/minio server /data --console-address ":9001"
```

Akses MinIO Console: http://localhost:9001

### Error: `JWCrypto` atau `jose` installation

```bash
pip install python-jose[cryptography]
# atau
pip install PyJWT[crypto]
```

---

## 📁 Struktur Output yang Diharapkan

Setelah instalasi berhasil, struktur direktori backend:

```
backend/
├── .venv/                  # Virtual environment
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── database.py
│   ├── core/
│   │   ├── __init__.py
│   │   ├── config.py
│   │   └── security.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── detection.py
│   │   └── user.py
│   ├── schemas/
│   │   ├── __init__.py
│   │   ├── detection.py
│   │   └── auth.py
│   ├── services/
│   │   ├── __init__.py
│   │   ├── detection_service.py
│   │   └── minio_service.py
│   └── api/
│       ├── __init__.py
│       ├── auth.py
│       ├── detections.py
│       ├── statistics.py
│       ├── upload.py
│       └── seed.py
├── alembic/
│   └── env.py
├── alembic.ini
├── requirements.txt
├── Dockerfile
├── .env
└── .env.example
```

---

## ✅ Checklist Instalasi

- [ ] Python 3.11+ terinstall
- [ ] Virtual environment dibuat dan aktif
- [ ] Semua dependencies terinstall (`pip install -r requirements.txt`)
- [ ] File `.env` sudah dikonfigurasi
- [ ] PostgreSQL berjalan dan database `jalancerdas` dibuat
- [ ] Server berjalan (`uvicorn app.main:app --reload`)
- [ ] Health check berhasil (`curl localhost:8000/health`)
- [ ] Seed data terbuat (`POST /api/seed`)
- [ ] Login berhasil (`POST /api/auth/login`)
