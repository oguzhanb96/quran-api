from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime

# User schemas
class UserBase(BaseModel):
    email: EmailStr
    full_name: Optional[str] = None

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(UserBase):
    id: int
    is_active: bool
    is_premium: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

# Token schema
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

# Surah schemas
class VerseResponse(BaseModel):
    id: int
    number: int
    text_arabic: str
    text_translation: Optional[str]
    juz: Optional[int]
    page: Optional[int]
    
    class Config:
        from_attributes = True

class SurahResponse(BaseModel):
    id: int
    number: int
    name: str
    english_name: str
    english_name_translation: Optional[str]
    revelation_type: Optional[str]
    verses_count: Optional[int]
    verses: Optional[List[VerseResponse]] = None
    
    class Config:
        from_attributes = True

class SurahListResponse(BaseModel):
    id: int
    number: int
    name: str
    english_name: str
    verses_count: Optional[int]
    
    class Config:
        from_attributes = True

# Favorite schemas
class FavoriteCreate(BaseModel):
    surah_id: Optional[int] = None
    verse_id: Optional[int] = None
    dua_id: Optional[int] = None

class FavoriteResponse(BaseModel):
    id: int
    surah_id: Optional[int]
    verse_id: Optional[int]
    dua_id: Optional[int]
    surah: Optional[SurahListResponse] = None
    verse: Optional[VerseResponse] = None
    created_at: datetime
    
    class Config:
        from_attributes = True

# Bookmark schemas
class BookmarkCreate(BaseModel):
    surah_id: int
    verse_number: int

class BookmarkResponse(BaseModel):
    id: int
    surah_id: int
    verse_number: int
    surah: SurahListResponse
    created_at: datetime
    
    class Config:
        from_attributes = True

# User Settings schemas
class UserSettingsUpdate(BaseModel):
    language: Optional[str] = None
    theme: Optional[str] = None
    quran_font_size: Optional[int] = None
    translation_edition: Optional[str] = None
    prayer_method: Optional[int] = None
    notification_enabled: Optional[bool] = None

class UserSettingsResponse(BaseModel):
    id: int
    language: str
    theme: str
    quran_font_size: int
    translation_edition: str
    prayer_method: int
    notification_enabled: bool
    
    class Config:
        from_attributes = True

# Prayer Time schemas
class PrayerTimeRequest(BaseModel):
    latitude: float
    longitude: float
    method: int = 13  # Default: Diyanet
    month: int
    year: int

class PrayerTimeDay(BaseModel):
    date: str
    fajr: str
    sunrise: str
    dhuhr: str
    asr: str
    maghrib: str
    isha: str

class PrayerTimeResponse(BaseModel):
    latitude: float
    longitude: float
    method: int
    month: int
    year: int
    days: List[PrayerTimeDay]

# Search schema
class SearchResult(BaseModel):
    surah_number: int
    surah_name: str
    verse_number: int
    verse_text_arabic: str
    verse_text_translation: str

class SearchResponse(BaseModel):
    query: str
    count: int
    results: List[SearchResult]
