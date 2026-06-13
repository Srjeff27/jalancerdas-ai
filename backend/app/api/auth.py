"""Authentication API endpoints."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, get_current_user, verify_password
from app.database import get_db
from app.models.user import User
from app.schemas.auth import LoginRequest, TokenResponse, UserResponse

router = APIRouter(prefix="/api/auth", tags=["auth"])


@router.post("/login", response_model=TokenResponse)
async def login(
    request: LoginRequest,
    db: AsyncSession = Depends(get_db),
):
    """Authenticate user with username and password.

    Returns a JWT access token valid for 24 hours.

    Raises:
        401: If credentials are invalid.
    """
    result = await db.execute(select(User).where(User.username == request.username))
    user = result.scalar_one_or_none()

    if user is None or not verify_password(request.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password",
        )

    access_token = create_access_token(data={"sub": str(user.id)})

    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        user=UserResponse.model_validate(user),
    )


@router.get("/me", response_model=UserResponse)
async def get_me(
    current_user=Depends(get_current_user),
):
    """Get current authenticated user information.

    Requires valid JWT in Authorization header.

    Raises:
        401: If not authenticated.
    """
    return UserResponse.model_validate(current_user)
