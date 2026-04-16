from sqlalchemy import Column, Integer, String, Text, ForeignKey, DateTime, Boolean, Float
from sqlalchemy.orm import relationship
from app.database import Base
from datetime import datetime

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String)
    is_active = Column(Boolean, default=True)
    is_premium = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    favorites = relationship("Favorite", back_populates="user", cascade="all, delete-orphan")
    bookmarks = relationship("Bookmark", back_populates="user", cascade="all, delete-orphan")
    settings = relationship("UserSettings", back_populates="user", uselist=False)

class Surah(Base):
    __tablename__ = "surahs"
    
    id = Column(Integer, primary_key=True)
    number = Column(Integer, unique=True, index=True, nullable=False)
    name = Column(String, nullable=False)
    english_name = Column(String, nullable=False)
    english_name_translation = Column(String)
    revelation_type = Column(String)  # Meccan or Medinan
    verses_count = Column(Integer)
    
    verses = relationship("Verse", back_populates="surah", cascade="all, delete-orphan")

class Verse(Base):
    __tablename__ = "verses"
    
    id = Column(Integer, primary_key=True)
    surah_id = Column(Integer, ForeignKey("surahs.id"), nullable=False)
    number = Column(Integer, nullable=False)
    text_arabic = Column(Text, nullable=False)
    text_translation = Column(Text)
    juz = Column(Integer)
    page = Column(Integer)
    
    surah = relationship("Surah", back_populates="verses")

class Favorite(Base):
    __tablename__ = "favorites"
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    surah_id = Column(Integer, ForeignKey("surahs.id"))
    verse_id = Column(Integer, ForeignKey("verses.id"))
    dua_id = Column(Integer)  # For duas
    created_at = Column(DateTime, default=datetime.utcnow)
    
    user = relationship("User", back_populates="favorites")
    surah = relationship("Surah")
    verse = relationship("Verse")

class Bookmark(Base):
    __tablename__ = "bookmarks"
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    surah_id = Column(Integer, ForeignKey("surahs.id"), nullable=False)
    verse_number = Column(Integer, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    user = relationship("User", back_populates="bookmarks")
    surah = relationship("Surah")

class UserSettings(Base):
    __tablename__ = "user_settings"
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    language = Column(String, default="tr")
    theme = Column(String, default="light")
    quran_font_size = Column(Integer, default=24)
    translation_edition = Column(String, default="tr.yildirim")
    prayer_method = Column(Integer, default=13)  # Diyanet method
    notification_enabled = Column(Boolean, default=True)
    
    user = relationship("User", back_populates="settings")

class PrayerTimeCache(Base):
    __tablename__ = "prayer_time_cache"
    
    id = Column(Integer, primary_key=True)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    method = Column(Integer, nullable=False)
    date = Column(String, nullable=False)  # YYYY-MM-DD
    fajr = Column(String)
    sunrise = Column(String)
    dhuhr = Column(String)
    asr = Column(String)
    maghrib = Column(String)
    isha = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
