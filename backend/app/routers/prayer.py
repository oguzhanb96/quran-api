from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List
import httpx
from app.database import get_db
from app.schemas import PrayerTimeRequest, PrayerTimeResponse, PrayerTimeDay
from app.crud_prayer import get_cached_prayer_times, cache_prayer_times

router = APIRouter(prefix="/prayer", tags=["prayer times"])

@router.get("/calendar", response_model=PrayerTimeResponse)
async def get_prayer_calendar(
    latitude: float = Query(..., description="Location latitude"),
    longitude: float = Query(..., description="Location longitude"),
    method: int = Query(13, description="Calculation method (13=Diyanet)"),
    month: int = Query(..., ge=1, le=12, description="Month (1-12)"),
    year: int = Query(..., ge=2020, le=2030, description="Year"),
    db: Session = Depends(get_db)
):
    """
    Get prayer times calendar for a location.
    First checks cache, if not found fetches from Aladhan API.
    """
    # Check cache first
    cached = get_cached_prayer_times(db, latitude, longitude, method, year, month)
    
    if cached and len(cached) > 25:  # Assume month has at least 25 days cached
        days = [
            PrayerTimeDay(
                date=pt.date,
                fajr=pt.fajr,
                sunrise=pt.sunrise,
                dhuhr=pt.dhuhr,
                asr=pt.asr,
                maghrib=pt.maghrib,
                isha=pt.isha
            )
            for pt in cached
        ]
        return PrayerTimeResponse(
            latitude=latitude,
            longitude=longitude,
            method=method,
            month=month,
            year=year,
            days=days
        )
    
    # Fetch from external API if not in cache
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                "https://api.aladhan.com/v1/calendar",
                params={
                    "latitude": latitude,
                    "longitude": longitude,
                    "method": method,
                    "month": month,
                    "year": year
                },
                timeout=30.0
            )
            response.raise_for_status()
            data = response.json()
    except httpx.HTTPError as e:
        raise HTTPException(
            status_code=503,
            detail=f"Failed to fetch prayer times from external API: {str(e)}"
        )
    
    # Parse response
    days_data = []
    for day_data in data.get("data", []):
        timings = day_data.get("timings", {})
        date = day_data.get("date", {}).get("gregorian", {}).get("date", "")
        
        day = {
            "date": date,
            "fajr": timings.get("Fajr", "").split(" ")[0],  # Remove timezone
            "sunrise": timings.get("Sunrise", "").split(" ")[0],
            "dhuhr": timings.get("Dhuhr", "").split(" ")[0],
            "asr": timings.get("Asr", "").split(" ")[0],
            "maghrib": timings.get("Maghrib", "").split(" ")[0],
            "isha": timings.get("Isha", "").split(" ")[0]
        }
        days_data.append(day)
    
    # Cache the results
    cache_prayer_times(db, latitude, longitude, method, days_data)
    
    days = [PrayerTimeDay(**day) for day in days_data]
    
    return PrayerTimeResponse(
        latitude=latitude,
        longitude=longitude,
        method=method,
        month=month,
        year=year,
        days=days
    )

@router.get("/methods")
def get_calculation_methods():
    """Get list of available calculation methods"""
    return {
        "methods": [
            {"id": 1, "name": "University of Islamic Sciences, Karachi"},
            {"id": 2, "name": "Islamic Society of North America (ISNA)"},
            {"id": 3, "name": "Muslim World League"},
            {"id": 4, "name": "Umm Al-Qura University, Makkah"},
            {"id": 5, "name": "Egyptian General Authority of Survey"},
            {"id": 7, "name": "Institute of Geophysics, University of Tehran"},
            {"id": 8, "name": "Gulf Region"},
            {"id": 9, "name": "Kuwait"},
            {"id": 10, "name": "Qatar"},
            {"id": 11, "name": "Majlis Ugama Islam Singapura, Singapore"},
            {"id": 12, "name": "Union Organization islamic de France"},
            {"id": 13, "name": "Diyanet İşleri Başkanlığı, Turkey"},
            {"id": 14, "name": "Spiritual Administration of Muslims of Russia"},
            {"id": 15, "name": "Moonsighting Committee Worldwide"},
        ]
    }
