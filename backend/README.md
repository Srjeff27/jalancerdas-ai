# Backend API — JalanCerdas AI

FastAPI backend untuk menerima dan mengelola data deteksi jalan rusak.

## Quick Start

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## Struktur

```
app/
├── main.py           # FastAPI app
├── database.py       # SQLAlchemy async engine
├── core/
│   ├── config.py     # Environment settings
│   └── security.py   # JWT authentication
├── models/           # SQLAlchemy ORM models
├── schemas/          # Pydantic validation schemas
├── services/         # Business logic (MinIO, CRUD)
└── api/              # Route handlers
```

## Endpoints

Lihat [API Documentation](../docs/api-documentation.md) atau akses `/docs` untuk Swagger UI.

## Seed Data

```bash
# Via API
curl -X POST http://localhost:8000/api/seed

# Via script
python seed_data.py
```
