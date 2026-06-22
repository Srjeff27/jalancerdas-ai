"""Tests for detection API endpoints."""

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app


@pytest.fixture
async def client():
    """Create an async test client."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.mark.asyncio
async def test_health_endpoint(client):
    """Test health check endpoint."""
    response = await client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "version" in data


@pytest.mark.asyncio
async def test_root_endpoint(client):
    """Test root endpoint."""
    response = await client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "running"
    assert "JalanCerdas" in data["name"]


@pytest.mark.asyncio
async def test_create_detection_validation(client):
    """Test that create_detection validates input."""
    # Missing required fields
    response = await client.post("/api/detections/", data={})
    assert response.status_code == 422  # Unprocessable Entity


@pytest.mark.asyncio
async def test_list_detections(client):
    """Test list detections endpoint."""
    response = await client.get("/api/detections/")
    assert response.status_code == 200
    data = response.json()
    assert "detections" in data
    assert "total" in data
    assert "limit" in data
    assert "offset" in data


@pytest.mark.asyncio
async def test_list_detections_with_pagination(client):
    """Test list detections with pagination parameters."""
    response = await client.get("/api/detections/?limit=10&offset=0")
    assert response.status_code == 200
    data = response.json()
    assert data["limit"] == 10
    assert data["offset"] == 0


@pytest.mark.asyncio
async def test_list_detections_invalid_status(client):
    """Test list detections with invalid status filter."""
    response = await client.get("/api/detections/?status=InvalidStatus")
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_statistics_endpoint(client):
    """Test statistics endpoint."""
    response = await client.get("/api/statistics/")
    assert response.status_code == 200
    data = response.json()
    assert "total" in data
    assert "average_confidence" in data


@pytest.mark.asyncio
async def test_get_nonexistent_detection(client):
    """Test getting a detection that doesn't exist."""
    fake_id = "00000000-0000-0000-0000-000000000000"
    response = await client.get(f"/api/detections/{fake_id}")
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_auth_login_invalid_credentials(client):
    """Test login with invalid credentials."""
    response = await client.post(
        "/api/auth/login",
        json={"username": "nonexistent", "password": "wrong"},
    )
    assert response.status_code == 401
