"""Seed data API endpoint for development/testing."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.security import get_current_user, hash_password
from app.database import get_db
from app.models.detection import Detection
from app.models.user import User

router = APIRouter(prefix="/api/seed", tags=["seed"])

# 15 dummy detections across Indonesia
SEED_DETECTIONS = [
    # Jakarta
    {"damage_type": "Pothole", "confidence": 0.92, "latitude": -6.2088, "longitude": 106.8456, "status": "Baru", "image_url": "https://via.placeholder.com/400x300/jakarta1.jpg"},
    {"damage_type": "Crack", "confidence": 0.85, "latitude": -6.1751, "longitude": 106.8650, "status": "Terverifikasi", "image_url": "https://via.placeholder.com/400x300/jakarta2.jpg"},
    {"damage_type": "Pothole", "confidence": 0.78, "latitude": -6.2297, "longitude": 106.6895, "status": "Diproses", "image_url": "https://via.placeholder.com/400x300/jakarta3.jpg"},
    # Bandung
    {"damage_type": "Crack", "confidence": 0.95, "latitude": -6.9175, "longitude": 107.6191, "status": "Selesai", "image_url": "https://via.placeholder.com/400x300/bandung1.jpg"},
    {"damage_type": "Pothole", "confidence": 0.88, "latitude": -6.9059, "longitude": 107.6132, "status": "Baru", "image_url": "https://via.placeholder.com/400x300/bandung2.jpg"},
    # Surabaya
    {"damage_type": "Pothole", "confidence": 0.91, "latitude": -7.2575, "longitude": 112.7521, "status": "Baru", "image_url": "https://via.placeholder.com/400x300/surabaya1.jpg"},
    {"damage_type": "Crack", "confidence": 0.72, "latitude": -7.2892, "longitude": 112.7393, "status": "Terverifikasi", "image_url": "https://via.placeholder.com/400x300/surabaya2.jpg"},
    # Yogyakarta
    {"damage_type": "Pothole", "confidence": 0.83, "latitude": -7.7956, "longitude": 110.3695, "status": "Diproses", "image_url": "https://via.placeholder.com/400x300/jogja1.jpg"},
    {"damage_type": "Crack", "confidence": 0.96, "latitude": -7.8010, "longitude": 110.3643, "status": "Selesai", "image_url": "https://via.placeholder.com/400x300/jogja2.jpg"},
    # Medan
    {"damage_type": "Pothole", "confidence": 0.89, "latitude": 3.5952, "longitude": 98.6722, "status": "Baru", "image_url": "https://via.placeholder.com/400x300/medan1.jpg"},
    {"damage_type": "Crack", "confidence": 0.67, "latitude": 3.6246, "longitude": 98.6571, "status": "Terverifikasi", "image_url": "https://via.placeholder.com/400x300/medan2.jpg"},
    # Makassar
    {"damage_type": "Pothole", "confidence": 0.93, "latitude": -5.1477, "longitude": 119.4327, "status": "Diproses", "image_url": "https://via.placeholder.com/400x300/makassar1.jpg"},
    # Semarang
    {"damage_type": "Crack", "confidence": 0.76, "latitude": -6.9666, "longitude": 110.4196, "status": "Baru", "image_url": "https://via.placeholder.com/400x300/semarang1.jpg"},
    {"damage_type": "Pothole", "confidence": 0.87, "latitude": -6.9932, "longitude": 110.4203, "status": "Selesai", "image_url": "https://via.placeholder.com/400x300/semarang2.jpg"},
    # Bali
    {"damage_type": "Crack", "confidence": 0.94, "latitude": -8.6500, "longitude": 115.2167, "status": "Baru", "image_url": "https://via.placeholder.com/400x300/bali1.jpg"},
]


@router.post("/")
async def seed_data(
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """Seed the database with 15 dummy detections across Indonesia.

    Requires admin authentication. Only works when DEBUG=true.
    Also creates default admin user (admin/admin123) if not exists.
    Safe to call multiple times — skips if data already exists.

    Returns:
        Dict with creation status and counts.
    """
    # Safety: only allow seeding in debug mode
    if not settings.DEBUG:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seed endpoint is only available in DEBUG mode",
        )

    # Create admin user if not exists
    admin_result = await db.execute(select(User).where(User.username == "admin"))
    admin = admin_result.scalar_one_or_none()
    admin_created = False
    if admin is None:
        admin = User(
            username="admin",
            password_hash=hash_password("admin123"),
        )
        db.add(admin)
        await db.flush()
        admin_created = True

    # Check if detections already exist
    count_result = await db.execute(select(Detection.id))
    existing = count_result.scalars().all()
    if len(existing) > 0:
        return {
            "message": "Seed data already exists",
            "detections_count": len(existing),
            "admin_created": admin_created,
        }

    # Create detection records
    from datetime import datetime, timezone, timedelta
    import random

    created_detections = []
    for i, data in enumerate(SEED_DETECTIONS):
        detected = datetime.now(timezone.utc) - timedelta(days=random.randint(1, 30))
        detection = Detection(
            damage_type=data["damage_type"],
            confidence=data["confidence"],
            latitude=data["latitude"],
            longitude=data["longitude"],
            image_url=data["image_url"],
            detected_at=detected,
            status=data["status"],
        )
        db.add(detection)
        created_detections.append(data["damage_type"])

    await db.flush()

    return {
        "message": "Seed data created successfully",
        "detections_created": len(created_detections),
        "admin_created": admin_created,
        "admin_credentials": {"username": "admin", "password": "admin123"} if admin_created else None,
    }
