"""Statistics API endpoints for dashboard metrics."""

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.services import detection_service

router = APIRouter(prefix="/api/statistics", tags=["statistics"])


@router.get("/")
async def get_statistics(db: AsyncSession = Depends(get_db)):
    """Get aggregate detection statistics for the dashboard.

    Returns counts by status and average confidence score.

    Response:
        - total: Total number of detections
        - baru: Count of 'Baru' status
        - terverifikasi: Count of 'Terverifikasi' status
        - diproses: Count of 'Diproses' status
        - selesai: Count of 'Selesai' status
        - average_confidence: Mean confidence score across all detections
    """
    stats = await detection_service.get_statistics(db)
    return stats
