# 📡 API Documentation

Referensi lengkap REST API JalanCerdas AI Backend.

---

## Base URL

```
Development:  http://localhost:8000
Production:   https://api.jalancerdas.com
```

## API Reference

- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`
- **OpenAPI JSON**: `http://localhost:8000/openapi.json`

---

## 🔐 Authentication

### Login

```
POST /api/auth/login
```

**Request:**
```json
{
  "username": "admin",
  "password": "admin123"
}
```

| Field | Type | Required | Min Length | Max Length |
|-------|------|----------|------------|------------|
| username | string | ✅ | 3 | 100 |
| password | string | ✅ | 4 | 128 |

**Response 200:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "admin",
    "created_at": "2025-01-15T10:30:00Z"
  }
}
```

**Response 401:**
```json
{
  "detail": "Invalid username or password"
}
```

### Menggunakan Token

Setelah login, sertakan token di header setiap request yang membutuhkan autentikasi:

```
Authorization: Bearer <access_token>
```

### Get Current User

```
GET /api/auth/me
```

**Headers:** `Authorization: Bearer <token>`

**Response 200:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "username": "admin",
  "created_at": "2025-01-15T10:30:00Z"
}
```

**Response 401:**
```json
{
  "detail": "Could not validate credentials"
}
```

---

## 🕳️ Detections

### Create Detection

```
POST /api/detections
Content-Type: multipart/form-data
```

**Form Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| damage_type | string | ✅ | Tipe kerusakan (Pothole, Crack, Depression, Bump, Other) |
| confidence | float | ✅ | Confidence score (0.0 - 1.0) |
| latitude | float | ✅ | GPS latitude (-90.0 - 90.0) |
| longitude | float | ✅ | GPS longitude (-180.0 - 180.0) |
| detected_at | string | ❌ | ISO 8601 datetime |
| file | file | ❌ | Image file (JPEG, PNG, WebP) |

**Example (curl):**
```bash
curl -X POST http://localhost:8000/api/detections \
  -F "damage_type=Pothole" \
  -F "confidence=0.92" \
  -F "latitude=-6.2088" \
  -F "longitude=106.8456" \
  -F "detected_at=2025-01-15T10:30:00Z" \
  -F "file=@/path/to/image.jpg"
```

**Response 201:**
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "damage_type": "Pothole",
  "confidence": 0.92,
  "latitude": -6.2088,
  "longitude": 106.8456,
  "image_url": "http://localhost:9000/road-detections/2025/01/15/a1b2c3d4.jpg",
  "detected_at": "2025-01-15T10:30:00Z",
  "status": "Baru",
  "created_at": "2025-01-15T10:30:01Z",
  "updated_at": "2025-01-15T10:30:01Z"
}
```

> 📝 **Catatan**: Endpoint ini tidak memerlukan autentikasi.

---

### List Detections

```
GET /api/detections?status=Baru&limit=50&offset=0
```

**Query Parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| status | string | — | Filter: `Baru`, `Terverifikasi`, `Diproses`, `Selesai` |
| limit | int | 50 | Max results per page (1-200) |
| offset | int | 0 | Number of results to skip |

**Example:**
```bash
curl "http://localhost:8000/api/detections?status=Baru&limit=10"
```

**Response 200:**
```json
{
  "detections": [
    {
      "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "damage_type": "Pothole",
      "confidence": 0.92,
      "latitude": -6.2088,
      "longitude": 106.8456,
      "image_url": "https://example.com/image.jpg",
      "detected_at": "2025-01-15T10:30:00Z",
      "status": "Baru",
      "created_at": "2025-01-15T10:30:01Z",
      "updated_at": "2025-01-15T10:30:01Z"
    }
  ],
  "total": 15,
  "limit": 10,
  "offset": 0
}
```

**Response 400 (invalid status):**
```json
{
  "detail": "Invalid status filter: InvalidStatus"
}
```

---

### Get Detection by ID

```
GET /api/detections/{detection_id}
```

**Path Parameters:**

| Param | Type | Description |
|-------|------|-------------|
| detection_id | UUID | ID unik detection |

**Example:**
```bash
curl http://localhost:8000/api/detections/a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

**Response 200:**
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "damage_type": "Pothole",
  "confidence": 0.92,
  "latitude": -6.2088,
  "longitude": 106.8456,
  "image_url": "https://example.com/image.jpg",
  "detected_at": "2025-01-15T10:30:00Z",
  "status": "Baru",
  "created_at": "2025-01-15T10:30:01Z",
  "updated_at": "2025-01-15T10:30:01Z"
}
```

**Response 404:**
```json
{
  "detail": "Detection a1b2c3d4-e5f6-7890-abcd-ef1234567890 not found"
}
```

---

### Update Detection Status

```
PATCH /api/detections/{detection_id}/status
Authorization: Bearer <token>
```

**Request Body:**

| Field | Type | Required | Values |
|-------|------|----------|--------|
| status | string | ✅ | `Baru`, `Terverifikasi`, `Diproses`, `Selesai` |

**Example:**
```bash
curl -X PATCH http://localhost:8000/api/detections/a1b2c3d4/status \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"status": "Terverifikasi"}'
```

**Response 200:**
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "damage_type": "Pothole",
  "confidence": 0.92,
  "latitude": -6.2088,
  "longitude": 106.8456,
  "image_url": "https://example.com/image.jpg",
  "detected_at": "2025-01-15T10:30:00Z",
  "status": "Terverifikasi",
  "created_at": "2025-01-15T10:30:01Z",
  "updated_at": "2025-01-15T11:00:00Z"
}
```

> 🔒 **Memerlukan autentikasi JWT yang valid.**

---

## 📤 File Upload

### Upload Image

```
POST /api/upload
Content-Type: multipart/form-data
```

**Form Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| file | file | ✅ | Image file (JPEG, PNG, WebP) |

**Example:**
```bash
curl -X POST http://localhost:8000/api/upload \
  -F "file=@pothole.jpg"
```

**Response 200:**
```json
{
  "image_url": "http://localhost:9000/road-detections/2025/01/15/uuid.jpg"
}
```

**Response 400 (empty file):**
```json
{
  "detail": "Empty file"
}
```

**Response 422 (wrong type):**
```json
{
  "detail": "File type 'application/pdf' not allowed. Use JPEG or PNG."
}
```

---

## 📊 Statistics

### Get Statistics

```
GET /api/statistics
```

**Example:**
```bash
curl http://localhost:8000/api/statistics
```

**Response 200:**
```json
{
  "total": 15,
  "baru": 6,
  "terverifikasi": 4,
  "diproses": 3,
  "selesai": 4,
  "average_confidence": 0.8613
}
```

---

## 🌱 Seed Data

### Seed Database

```
POST /api/seed
```

Membuat 15 data dummy deteksi + admin user.

**Example:**
```bash
curl -X POST http://localhost:8000/api/seed
```

**Response 200 (first run):**
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

**Response 200 (already seeded):**
```json
{
  "message": "Seed data already exists",
  "detections_count": 15,
  "admin_created": false
}
```

> ⚠️ **Endpoint ini untuk development/testing saja. Hapus atau protect di production.**

---

## 🏥 Health Check

### Root

```
GET /
```

**Response 200:**
```json
{
  "name": "JalanCerdas AI",
  "version": "1.0.0",
  "status": "running"
}
```

### Health

```
GET /health
```

**Response 200:**
```json
{
  "status": "healthy",
  "version": "1.0.0"
}
```

---

## ⚠️ Error Codes

| HTTP Code | Deskripsi | Kemungkinan Penyebab |
|-----------|-----------|---------------------|
| 400 | Bad Request | Status filter invalid, request body malformed |
| 401 | Unauthorized | Token tidak valid / expired, credentials salah |
| 404 | Not Found | Detection ID tidak ditemukan |
| 422 | Unprocessable Entity | File type tidak didukung |
| 500 | Internal Server Error | MinIO upload gagal, database error |

### Error Response Format

Semua error mengikuti format:
```json
{
  "detail": "Deskripsi error dalam bahasa Inggris"
}
```

---

## 📏 Rate Limiting

Saat ini belum ada rate limiting yang aktif.

**Planned:**
- Auth endpoints: 10 requests/minute per IP
- Upload endpoints: 30 requests/minute per user
- Read endpoints: 100 requests/minute per IP

---

## 📐 Response Schema Reference

### DetectionResponse

```json
{
  "id": "uuid",
  "damage_type": "string (max 100 chars)",
  "confidence": "float (0.0 - 1.0)",
  "latitude": "float (-90.0 - 90.0)",
  "longitude": "float (-180.0 - 180.0)",
  "image_url": "string (text)",
  "detected_at": "datetime (ISO 8601, nullable)",
  "status": "string (Baru|Terverifikasi|Diproses|Selesai)",
  "created_at": "datetime (ISO 8601)",
  "updated_at": "datetime (ISO 8601)"
}
```

### DetectionList

```json
{
  "detections": "[DetectionResponse]",
  "total": "int",
  "limit": "int",
  "offset": "int"
}
```

### TokenResponse

```json
{
  "access_token": "string (JWT)",
  "token_type": "string (bearer)",
  "user": "UserResponse"
}
```

### UserResponse

```json
{
  "id": "uuid",
  "username": "string",
  "created_at": "datetime (ISO 8601)"
}
```

---

## 🔄 Workflow: Complete Detection Flow

```bash
# 1. Seed data (development only)
curl -X POST http://localhost:8000/api/seed

# 2. Login
TOKEN=$(curl -s -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | jq -r '.access_token')

# 3. Upload image
IMAGE_URL=$(curl -s -X POST http://localhost:8000/api/upload \
  -F "file=@pothole.jpg" | jq -r '.image_url')

# 4. Create detection
curl -X POST http://localhost:8000/api/detections \
  -F "damage_type=Pothole" \
  -F "confidence=0.92" \
  -F "latitude=-6.2088" \
  -F "longitude=106.8456" \
  -F "detected_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# 5. List all detections
curl "http://localhost:8000/api/detections?limit=10"

# 6. Get statistics
curl http://localhost:8000/api/statistics

# 7. Update status (requires auth)
DETECTION_ID=$(curl -s http://localhost:8000/api/detections | jq -r '.detections[0].id')
curl -X PATCH "http://localhost:8000/api/detections/$DETECTION_ID/status" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status": "Terverifikasi"}'
```
