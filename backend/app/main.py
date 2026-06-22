"""JalanCerdas AI - FastAPI Backend Application.

Main entry point for the pothole detection API.
Provides endpoints for detection CRUD, authentication, file upload,
and statistics for the JalanCerdas AI dashboard.
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.core.config import settings
from app.database import init_db

logger = logging.getLogger(__name__)


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

# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Catch-all exception handler for unhandled errors."""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "detail": "Internal server error",
            "message": str(exc) if settings.DEBUG else "An unexpected error occurred",
        },
    )

# CORS middleware — use configured origins (not wildcard)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
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
