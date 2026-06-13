"""Pydantic schemas for Detection CRUD operations."""

import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class DetectionCreate(BaseModel):
    """Schema for creating a new detection record."""

    damage_type: str = Field(..., max_length=100, examples=["Pothole", "Crack"])
    confidence: float = Field(..., ge=0.0, le=1.0)
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    image_url: str = Field(default="")
    detected_at: Optional[datetime] = None


class DetectionUpdate(BaseModel):
    """Schema for updating detection status."""

    status: str = Field(
        ...,
        pattern="^(Baru|Terverifikasi|Diproses|Selesai)$",
        examples=["Baru", "Terverifikasi", "Diproses", "Selesai"],
    )


class DetectionResponse(BaseModel):
    """Schema for returning detection data in API responses."""

    id: uuid.UUID
    damage_type: str
    confidence: float
    latitude: float
    longitude: float
    image_url: str
    detected_at: Optional[datetime] = None
    status: str
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class DetectionList(BaseModel):
    """Paginated list of detections."""

    detections: list[DetectionResponse]
    total: int
    limit: int
    offset: int
