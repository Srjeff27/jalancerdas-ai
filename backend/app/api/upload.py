"""File upload API endpoints."""

from fastapi import APIRouter, File, HTTPException, UploadFile, status

from app.services import minio_service

router = APIRouter(prefix="/api/upload", tags=["upload"])


@router.post("/")
async def upload_image(file: UploadFile = File(...)):
    """Upload an image file to object storage.

    Accepts image files (JPEG, PNG). Returns the stored URL.

    Raises:
        400: If no file provided or file is empty.
        422: If file is not an image type.

    Returns:
        Dict with image_url key.
    """
    if not file.filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No file provided",
        )

    # Validate file type
    allowed_types = {"image/jpeg", "image/png", "image/webp", "image/jpg"}
    if file.content_type and file.content_type not in allowed_types:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"File type '{file.content_type}' not allowed. Use JPEG or PNG.",
        )

    file_bytes = await file.read()
    if len(file_bytes) == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Empty file",
        )

    # File size limit (10MB) — consistent with create_detection endpoint
    if len(file_bytes) > 10 * 1024 * 1024:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="File size must be less than 10MB",
        )

    uploaded_url = minio_service.upload_image(file_bytes, file.filename)

    if uploaded_url is None:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to upload file to storage",
        )

    return {"image_url": uploaded_url}
