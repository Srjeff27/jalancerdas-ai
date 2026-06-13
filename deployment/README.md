# JalanCerdas AI — Deployment Guide

Docker Compose deployment for the JalanCerdas AI pothole detection system.

## Architecture

```
                        ┌─────────────┐
                   ┌───▶│  Dashboard   │
                   │    │  :3000       │
┌────────┐         │    └─────────────┘
│  Nginx │─────────┤
│  :80   │         │    ┌─────────────┐
└────────┘         ├───▶│  Backend    │──────▶┌──────────┐
                   │    │  :8000      │       │ PostgreSQL │
                   │    └─────────────┘       │  :5432    │
                   │                          └──────────┘
                   │    ┌─────────────┐       ┌──────────┐
                   └───▶│   MinIO     │       │  MinIO   │
                        │  :9000/:9001│       │   Init   │
                        └─────────────┘       └──────────┘
```

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) ≥ 20.10
- [Docker Compose](https://docs.docker.com/compose/install/) ≥ 2.20
- 4 GB RAM minimum (2 GB for containers + overhead)
- 10 GB free disk space

## Quick Start

```bash
cd deployment/

# 1. Copy and edit environment variables
cp .env.example .env
# Edit .env with your production values

# 2. Build and start all services
docker compose up -d --build

# 3. Wait for health checks to pass
docker compose ps
# All services should show "healthy"

# 4. Seed initial data (optional)
docker compose exec backend python seed_data.py
```

## Accessing Services

| Service       | URL                           | Purpose                |
|---------------|-------------------------------|------------------------|
| Dashboard     | http://localhost               | Web UI                 |
| API           | http://localhost/api           | REST API               |
| API Docs      | http://localhost/api/docs      | Swagger documentation  |
| MinIO Console | http://localhost:9001           | Object storage UI      |
| MinIO API     | http://localhost:9000           | S3-compatible API      |

## Seeding Data

Populate the database with demo detections:

```bash
# Via API endpoint
curl -X POST http://localhost/api/seed

# Or directly inside the container
docker compose exec backend python seed_data.py
```

## Configuration

### Environment Variables

All configuration lives in `.env`. Key variables:

**Database:**
- `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` — PostgreSQL credentials
- `DATABASE_URL` — Connection string for the backend (uses internal hostnames)

**MinIO:**
- `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` — MinIO admin credentials
- `MINIO_BUCKET` — Bucket name for detection data (default: `road-detections`)

**Security:**
- `JWT_SECRET` — Secret key for JWT tokens (change in production!)

Generate a secure JWT secret:
```bash
openssl rand -base64 32
```

**Frontend:**
- `NEXT_PUBLIC_API_URL` — Backend URL the dashboard connects to

### Production Hardening

1. Change all default passwords in `.env`
2. Set a strong `JWT_SECRET` (min 32 chars)
3. Enable SSL (see below)
4. Restrict CORS origins in backend config
5. Remove port mappings for internal services (postgres, minio)

## SSL Setup with Let's Encrypt

### 1. Get a domain name

Point your domain's A record to the server IP.

### 2. Stop nginx temporarily

```bash
docker compose stop nginx
```

### 3. Obtain certificate

```bash
# Install certbot on host
sudo apt install certbot

# Get certificate (standalone mode)
sudo certbot certonly --standalone -d your-domain.com

# Copy certs to deployment
mkdir -p nginx/certs
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem nginx/certs/
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem nginx/certs/
```

### 4. Enable SSL in nginx

Add an SSL server block to `nginx/nginx.conf`:

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate     /etc/nginx/certs/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    # ... same location blocks as HTTP server ...
}
```

### 5. Update Docker Compose for certs

Mount the certificates into nginx:

```yaml
nginx:
    volumes:
      - ./nginx/certs:/etc/nginx/certs:ro
```

### 6. Auto-renewal

```bash
# Add cron job
sudo crontab -e
# Add: 0 3 * * * certbot renew --quiet && docker compose -f /path/to/deployment/docker-compose.yml restart nginx
```

## Common Operations

```bash
# View logs
docker compose logs -f backend
docker compose logs -f postgres

# Restart a single service
docker compose restart backend

# Stop everything
docker compose down

# Stop and remove all data
docker compose down -v

# Rebuild after code changes
docker compose up -d --build backend

# Check service health
docker compose ps

# Database backup
docker compose exec postgres pg_dump -U jalancerdas jalancerdas_db > backup.sql

# Database restore
cat backup.sql | docker compose exec -T postgres psql -U jalancerdas -d jalancerdas_db
```

## Troubleshooting

### Backend won't start

Check if postgres is healthy:
```bash
docker compose ps postgres
docker compose logs postgres
```

The backend waits for postgres and minio health checks before starting.

### MinIO bucket not created

The `minio-init` service creates the bucket automatically. Check its logs:
```bash
docker compose logs minio-init
```

If it failed, recreate it:
```bash
docker compose run --rm minio-init
```

### Dashboard shows "Application error"

Ensure `NEXT_PUBLIC_API_URL` in `.env` points to the correct backend URL. Inside Docker, use the internal hostname (`http://backend:8000`). For local browser access, use `http://localhost:8000`.

### Port conflicts

If ports 80, 443, 5432, 9000, or 9001 are already in use:

```bash
# Find what's using the port
sudo lsof -i :80

# Edit docker-compose.yml to change host port (left side)
# e.g., "8080:80" instead of "80:80"
```

### High memory usage

Reduce resource limits in `docker-compose.yml` or add swap:
```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```
