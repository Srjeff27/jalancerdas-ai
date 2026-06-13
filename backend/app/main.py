"""JalanCerdas AI - FastAPI Backend Application.

Main entry point for the pothole detection API.
Provides endpoints for detection CRUD, authentication, file upload,
and statistics for the JalanCerdas AI dashboard.
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.database import init_db


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler — runs on startup and shutdown."""
    # Startup: create tables
    await init_db()
    yield
    # Shutdown: cleanup if needed


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="API backend for JalanCerdas AI - Pothole Detection System",
    lifespan=lifespan,
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins in development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Import and include routers
from app.api.auth import router as auth_router
from app.api.detections import router as detections_router
from app.api.seed import router as seed_router
from app.api.statistics import router as statistics_router
from app.api.upload import router as upload_router

app.include_router(auth_router)
app.include_router(detections_router)
app.include_router(statistics_router)
app.include_router(upload_router)
app.include_router(seed_router)


@app.get("/")
async def root():
    """Health check / root endpoint."""
    return {
        "name": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "running",
    }


@app.get("/health")
async def health():
    """Detailed health check endpoint."""
    return {"status": "healthy", "version": settings.APP_VERSION}


# For running with uvicorn directly
if __name__ == "__main__":
    import uvicorn

    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
