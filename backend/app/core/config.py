"""Core configuration for JalanCerdas AI."""

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/jalancerdas"

    # MinIO Object Storage
    MINIO_ENDPOINT: str = "localhost:9000"
    MINIO_ACCESS_KEY: str = "minioadmin"
    MINIO_SECRET_KEY: str = "minioadmin"
    MINIO_BUCKET: str = "road-detections"
    MINIO_SECURE: bool = False

    # JWT Authentication
    JWT_SECRET: str = "super-secret-jalancerdas-key-change-in-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRE_MINUTES: int = 1440

    # Application
    APP_NAME: str = "JalanCerdas AI"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
    }


settings = Settings()
