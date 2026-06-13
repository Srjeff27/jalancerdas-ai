"""MinIO object storage service for image uploads.

Handles file uploads to MinIO bucket with date-based path organization.
Gracefully handles connection failures when MinIO is unavailable.
"""

import logging
import uuid
from datetime import datetime, timezone
from typing import Optional

from minio import Minio
from minio.error import S3Error

from app.core.config import settings

logger = logging.getLogger(__name__)

# Module-level client (lazy init)
_minio_client: Optional[Minio] = None
_minio_available: Optional[bool] = None


def _get_client() -> Optional[Minio]:
    """Get or create MinIO client. Returns None if connection fails."""
    global _minio_client, _minio_available

    if _minio_available is False:
        return None

    if _minio_client is not None:
        return _minio_client

    try:
        _minio_client = Minio(
            settings.MINIO_ENDPOINT,
            access_key=settings.MINIO_ACCESS_KEY,
            secret_key=settings.MINIO_SECRET_KEY,
            secure=settings.MINIO_SECURE,
        )
        # Test connection
        if _minio_client.bucket_exists(settings.MINIO_BUCKET):
            _minio_available = True
            logger.info(f"MinIO connected. Bucket '{settings.MINIO_BUCKET}' exists.")
        else:
            # Create bucket if it doesn't exist
            _minio_client.make_bucket(settings.MINIO_BUCKET)
            _minio_available = True
            logger.info(f"MinIO connected. Bucket '{settings.MINIO_BUCKET}' created.")

        return _minio_client
    except Exception as e:
        logger.warning(f"MinIO not available: {e}. File uploads will return local paths.")
        _minio_available = False
        _minio_client = None
        return None


def upload_image(file_bytes: bytes, filename: str) -> Optional[str]:
    """Upload an image file to MinIO and return its URL.

    Files are stored in the bucket at path: YYYY/MM/DD/{uuid}.ext

    Args:
        file_bytes: Raw file content.
        filename: Original filename (used for extension).

    Returns:
        Object URL string, or None if upload failed.
    """
    client = _get_client()
    if client is None:
        # Fallback: return a placeholder path
        ext = filename.rsplit(".", 1)[-1] if "." in filename else "jpg"
        placeholder_path = f"uploads/{datetime.now(timezone.utc).strftime('%Y/%m/%d')}/{uuid.uuid4()}.{ext}"
        logger.info(f"MinIO unavailable. Would save to: {placeholder_path}")
        return placeholder_path

    try:
        now = datetime.now(timezone.utc)
        ext = filename.rsplit(".", 1)[-1] if "." in filename else "jpg"
        object_name = f"{now.strftime('%Y/%m/%d')}/{uuid.uuid4()}.{ext}"

        from io import BytesIO

        data_stream = BytesIO(file_bytes)
        result = client.put_object(
            settings.MINIO_BUCKET,
            object_name,
            data_stream,
            length=len(file_bytes),
            content_type="image/jpeg",
        )

        protocol = "https" if settings.MINIO_SECURE else "http"
        url = f"{protocol}://{settings.MINIO_ENDPOINT}/{settings.MINIO_BUCKET}/{object_name}"
        logger.info(f"Uploaded to MinIO: {url}")
        return url

    except S3Error as e:
        logger.error(f"MinIO upload failed: {e}")
        return None
    except Exception as e:
        logger.error(f"Unexpected error during MinIO upload: {e}")
        return None
