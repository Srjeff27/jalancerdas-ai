"""Detection CRUD API endpoints."""

import uuid
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user
from app.database import get_db
from app.schemas.detection import DetectionList, DetectionResponse, DetectionUpdate
from app.services import detection_service, minio_service

router = APIRouter(prefix="/api/detections", tags=["detections"])


@router.post("/", response_model=DetectionResponse, status_code=status.HTTP_201_CREATED)
async def create_detection(
    damage_type: str = Form(...),
    confidence: float = Form(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    detected_at: Optional[str] = Form(None),
    file: Optional[UploadFile] = File(None),
    db: AsyncSession = Depends(get_db),
):
    """Create a new pothole detection record.

    Accepts multipart form data with optional image file upload.
    The image is stored in MinIO and linked to the detection.
    """
    # Input validation
    if not damage_type or len(damage_type.strip()) == 0:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="damage_type cannot be empty",
        )
    if len(damage_type) > 100:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="damage_type must be 100 characters or less",
        )
    if not (0.0 <= confidence <= 1.0):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="confidence must be between 0.0 and 1.0",
        )
    if not (-90.0 <= latitude <= 90.0):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="latitude must be between -90.0 and 90.0",
        )
    if not (-180.0 <= longitude <= 180.0):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="longitude must be between -180.0 and 180.0",
        )

    # File size limit (10MB)
    image_url = ""
    if file and file.filename:
        file_bytes = await file.read()
        if len(file_bytes) > 10 * 1024 * 1024:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail="File size must be less than 10MB",
            )
        uploaded_url = minio_service.upload_image(file_bytes, file.filename)
        if uploaded_url:
            image_url = uploaded_url
        # Reset file pointer for potential re-read
        file_bytes = b""

    parsed_detected_at = None
    if detected_at:
        try:
            parsed_detected_at = datetime.fromisoformat(detected_at)
        except ValueError:
            pass

    detection = await detection_service.create_detection(
        db=db,
        damage_type=damage_type,
        confidence=confidence,
        latitude=latitude,
        longitude=longitude,
        image_url=image_url,
        detected_at=parsed_detected_at,
    )

    return detection


@router.get("/", response_model=DetectionList)
async def list_detections(
    status_filter: Optional[str] = Query(None, alias="status"),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
):
    """List all detections with optional filtering and pagination."""
    if status_filter and status_filter not in {"Baru", "Terverifikasi", "Diproses", "Selesai"}:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid status filter: {status_filter}",
        )

    detections, total = await detection_service.list_detections(
        db=db, status=status_filter, limit=limit, offset=offset
    )
    return DetectionList(
        detections=[DetectionResponse.model_validate(d) for d in detections],
        total=total,
        limit=limit,
        offset=offset,
    )


@router.get("/{detection_id}", response_model=DetectionResponse)
async def get_detection(
    detection_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """Get a single detection by its UUID."""
    detection = await detection_service.get_detection(db, detection_id)
    if detection is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Detection {detection_id} not found",
        )
    return detection


@router.patch("/{detection_id}/status", response_model=DetectionResponse)
async def update_detection_status(
    detection_id: uuid.UUID,
    update: DetectionUpdate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """Update the status of a detection. Requires admin authentication."""
    try:
        detection = await detection_service.update_detection_status(
            db, detection_id, update.status
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )

    if detection is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Detection {detection_id} not found",
        )

    return detection
