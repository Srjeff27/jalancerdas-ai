"""Pydantic schemas for authentication endpoints."""

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


class LoginRequest(BaseModel):
    """Schema for login request body."""

    username: str = Field(..., min_length=3, max_length=100)
    password: str = Field(..., min_length=4, max_length=128)


class TokenResponse(BaseModel):
    """Schema for JWT token response after successful login."""

    access_token: str
    token_type: str = "bearer"
    user: "UserResponse"


class UserResponse(BaseModel):
    """Schema for user data in responses."""

    id: UUID
    username: str
    created_at: datetime

    model_config = {"from_attributes": True}


# Update forward reference
TokenResponse.model_rebuild()
