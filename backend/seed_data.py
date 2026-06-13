"""Standalone seed script for JalanCerdas AI database.

Creates 15 dummy detection records and a default admin user.
Can be run directly: python seed_data.py

Usage:
    # With .env in current directory
    python seed_data.py

    # With custom DATABASE_URL
    DATABASE_URL=postgresql+asyncpg://... python seed_data.py
"""

import asyncio
import random
from datetime import datetime, timedelta, timezone

import psycopg2
from app.core.config import settings
from app.core.security import hash_password

# Detect database URL (strip +asyncpg for psycopg2 sync connection)
SYNC_DB_URL = settings.DATABASE_URL.replace("+asyncpg", "")

# 15 dummy detections across Indonesia
SEED_DATA = [
    # Jakarta
    {"damage_type": "Pothole", "confidence": 0.92, "latitude": -6.2088, "longitude": 106.8456, "status": "Baru"},
    {"damage_type": "Crack", "confidence": 0.85, "latitude": -6.1751, "longitude": 106.8650, "status": "Terverifikasi"},
    {"damage_type": "Pothole", "confidence": 0.78, "latitude": -6.2297, "longitude": 106.6895, "status": "Diproses"},
    # Bandung
    {"damage_type": "Crack", "confidence": 0.95, "latitude": -6.9175, "longitude": 107.6191, "status": "Selesai"},
    {"damage_type": "Pothole", "confidence": 0.88, "latitude": -6.9059, "longitude": 107.6132, "status": "Baru"},
    # Surabaya
    {"damage_type": "Pothole", "confidence": 0.91, "latitude": -7.2575, "longitude": 112.7521, "status": "Baru"},
    {"damage_type": "Crack", "confidence": 0.72, "latitude": -7.2892, "longitude": 112.7393, "status": "Terverifikasi"},
    # Yogyakarta
    {"damage_type": "Pothole", "confidence": 0.83, "latitude": -7.7956, "longitude": 110.3695, "status": "Diproses"},
    {"damage_type": "Crack", "confidence": 0.96, "latitude": -7.8010, "longitude": 110.3643, "status": "Selesai"},
    # Medan
    {"damage_type": "Pothole", "confidence": 0.89, "latitude": 3.5952, "longitude": 98.6722, "status": "Baru"},
    {"damage_type": "Crack", "confidence": 0.67, "latitude": 3.6246, "longitude": 98.6571, "status": "Terverifikasi"},
    # Makassar
    {"damage_type": "Pothole", "confidence": 0.93, "latitude": -5.1477, "longitude": 119.4327, "status": "Diproses"},
    # Semarang
    {"damage_type": "Crack", "confidence": 0.76, "latitude": -6.9666, "longitude": 110.4196, "status": "Baru"},
    {"damage_type": "Pothole", "confidence": 0.87, "latitude": -6.9932, "longitude": 110.4203, "status": "Selesai"},
    # Bali
    {"damage_type": "Crack", "confidence": 0.94, "latitude": -8.6500, "longitude": 115.2167, "status": "Baru"},
]


def seed():
    """Execute seed SQL inserts directly via psycopg2."""
    print(f"Connecting to: {SYNC_DB_URL}")
    conn = psycopg2.connect(SYNC_DB_URL)
    cur = conn.cursor()

    try:
        # Create admin user
        cur.execute("SELECT id FROM users WHERE username = 'admin'")
        if cur.fetchone() is None:
            pw_hash = hash_password("admin123")
            cur.execute(
                "INSERT INTO users (id, username, password_hash, created_at) "
                "VALUES (gen_random_uuid(), 'admin', %s, NOW())",
                (pw_hash,),
            )
            print("Created admin user (admin / admin123)")
        else:
            print("Admin user already exists, skipping.")

        # Check if detections exist
        cur.execute("SELECT COUNT(*) FROM detections")
        count = cur.fetchone()[0]
        if count > 0:
            print(f"Database already has {count} detections. Skipping seed.")
            return

        # Insert detections
        now = datetime.now(timezone.utc)
        for data in SEED_DATA:
            detected = now - timedelta(days=random.randint(1, 30))
            cur.execute(
                "INSERT INTO detections "
                "(id, damage_type, confidence, latitude, longitude, image_url, "
                "detected_at, status, created_at, updated_at) "
                "VALUES (gen_random_uuid(), %s, %s, %s, %s, %s, %s, %s, %s, %s)",
                (
                    data["damage_type"],
                    data["confidence"],
                    data["latitude"],
                    data["longitude"],
                    f"https://via.placeholder.com/400x300/{data['damage_type'].lower()}.jpg",
                    detected,
                    data["status"],
                    now,
                    now,
                ),
            )

        conn.commit()
        print(f"Inserted {len(SEED_DATA)} detection records across Indonesia.")

    except Exception as e:
        conn.rollback()
        print(f"Error seeding database: {e}")
        raise
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    seed()
