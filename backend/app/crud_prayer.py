from sqlalchemy.orm import Session
from app.models import PrayerTimeCache
from datetime import datetime, timedelta
from typing import Optional, List
import math

def get_cached_prayer_times(
    db: Session,
    latitude: float,
    longitude: float,
    method: int,
    year: int,
    month: int
) -> Optional[List[PrayerTimeCache]]:
    """Get cached prayer times for a specific location and month"""
    month_prefix = f"{year}-{month:02d}"
    
    # Simple location matching (you may want to add tolerance for lat/lon)
    results = db.query(PrayerTimeCache).filter(
        PrayerTimeCache.latitude == latitude,
        PrayerTimeCache.longitude == longitude,
        PrayerTimeCache.method == method,
        PrayerTimeCache.date.like(f"{month_prefix}%")
    ).order_by(PrayerTimeCache.date).all()
    
    return results if results else None

def cache_prayer_times(
    db: Session,
    latitude: float,
    longitude: float,
    method: int,
    times: List[dict]
):
    """Cache prayer times to database"""
    for day in times:
        # Check if already exists
        existing = db.query(PrayerTimeCache).filter(
            PrayerTimeCache.latitude == latitude,
            PrayerTimeCache.longitude == longitude,
            PrayerTimeCache.method == method,
            PrayerTimeCache.date == day["date"]
        ).first()
        
        if existing:
            continue
        
        cache = PrayerTimeCache(
            latitude=latitude,
            longitude=longitude,
            method=method,
            date=day["date"],
            fajr=day.get("fajr"),
            sunrise=day.get("sunrise"),
            dhuhr=day.get("dhuhr"),
            asr=day.get("asr"),
            maghrib=day.get("maghrib"),
            isha=day.get("isha")
        )
        db.add(cache)
    
    db.commit()

def clean_old_cache(db: Session, days: int = 30):
    """Remove cache entries older than specified days"""
    cutoff = datetime.utcnow() - timedelta(days=days)
    db.query(PrayerTimeCache).filter(PrayerTimeCache.created_at < cutoff).delete()
    db.commit()
