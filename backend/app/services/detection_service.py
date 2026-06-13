"""Detection CRUD service for database operations."""

import uuid
from typing import Optional

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.detection import Detection


async def create_detection(
    db: AsyncSession,
    damage_type: str,
    confidence: float,
    latitude: float,
    longitude: float,
    image_url: str = "",
    detected_at=None,
) -> Detection:
    """Create a new detection record.

    Args:
        db: Async database session.
        damage_type: Type of damage detected.
        confidence: Detection confidence (0.0–1.0).
        latitude: GPS latitude.
        longitude: GPS longitude.
        image_url: URL/path to the detection image.
        detected_at: When the detection occurred.

    Returns:
        The newly created Detection instance.
    """
    detection = Detection(
        damage_type=damage_type,
        confidence=confidence,
        latitude=latitude,
        longitude=longitude,
        image_url=image_url,
        detected_at=detected_at,
        status="Baru",
    )
    db.add(detection)
    await db.flush()
    await db.refresh(detection)
    return detection


async def get_detection(db: AsyncSession, detection_id: uuid.UUID) -> Optional[Detection]:
    """Get a single detection by ID.

    Args:
        db: Async database session.
        detection_id: UUID of the detection.

    Returns:
        Detection instance or None.
    """
    result = await db.execute(select(Detection).where(Detection.id == detection_id))
    return result.scalar_one_or_none()


async def list_detections(
    db: AsyncSession,
    status: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
) -> tuple[list[Detection], int]:
    """List detections with optional filtering and pagination.

    Args:
        db: Async database session.
        status: Optional status filter.
        limit: Max results per page.
        offset: Number of results to skip.

    Returns:
        Tuple of (list of Detection, total count).
    """
    query = select(Detection)
    count_query = select(func.count(Detection.id))

    if status:
        query = query.where(Detection.status == status)
        count_query = count_query.where(Detection.status == status)

    # Get total count
    total_result = await db.execute(count_query)
    total = total_result.scalar()

    # Get paginated results, newest first
    query = query.order_by(Detection.created_at.desc()).limit(limit).offset(offset)
    result = await db.execute(query)
    detections = list(result.scalars().all())

    return detections, total


async def update_detection_status(
    db: AsyncSession, detection_id: uuid.UUID, new_status: str
) -> Optional[Detection]:
    """Update the status of a detection.

    Args:
        db: Async database session.
        detection_id: UUID of the detection to update.
        new_status: New status value (must be one of: Baru, Terverifikasi, Diproses, Selesai).

    Returns:
        Updated Detection or None if not found.
    """
    detection = await get_detection(db, detection_id)
    if detection is None:
        return None

    valid_statuses = {"Baru", "Terverifikasi", "Diproses", "Selesai"}
    if new_status not in valid_statuses:
        raise ValueError(f"Invalid status: {new_status}. Must be one of {valid_statuses}")

    detection.status = new_status
    await db.flush()
    await db.refresh(detection)
    return detection


async def get_statistics(db: AsyncSession) -> dict:
    """Get aggregate statistics for all detections.

    Returns:
        Dict with total, status counts, and average confidence.
    """
    total_result = await db.execute(select(func.count(Detection.id)))
    total = total_result.scalar() or 0

    # Status counts
    status_keys = {
        "Baru": "baru",
        "Terverifikasi": "terverifikasi",
        "Diproses": "diproses",
        "Selesai": "selesai",
    }
    stats = {}
    for status_val, key in status_keys.items():
        count_result = await db.execute(
            select(func.count(Detection.id)).where(Detection.status == status_val)
        )
        stats[key] = count_result.scalar() or 0

    # Average confidence
    avg_result = await db.execute(select(func.avg(Detection.confidence)))
    avg_confidence = avg_result.scalar() or 0.0

    return {
        "total": total,
        "baru": stats.get("baru", 0),
        "terverifikasi": stats.get("terverifikasi", 0),
        "diproses": stats.get("diproses", 0),
        "selesai": stats.get("selesai", 0),
        "average_confidence": round(float(avg_confidence), 4),
    }
