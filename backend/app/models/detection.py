"""Detection SQLAlchemy model for pothole damage records."""

import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, Float, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class Detection(Base):
    """Represents a detected road damage (pothole) entry.

    Stores location data, damage classification, confidence score,
    image reference, and processing status.
    """

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
        DateTime(timezone=True), nullable=True, default=lambda: datetime.now(timezone.utc)
    )
    status: Mapped[str] = mapped_column(String(50), nullable=False, default="Baru")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc)
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    def __repr__(self) -> str:
        return f"<Detection(id={self.id}, type={self.damage_type}, status={self.status})>"
