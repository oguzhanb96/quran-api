"""
Kuran verilerini Al-Quran Cloud API'den çekip kendi veritabanımıza aktaran script.
Çalıştırma: python scripts/import_quran.py
"""

import httpx
import asyncio
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import sys
import os

# Add parent directory to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database import Base, engine, SessionLocal
from app.models import Surah, Verse

# API Base URL
ALQURAN_API = "https://api.alquran.cloud/v1"

# Translation editions to import
TRANSLATIONS = {
    "tr.yildirim": "Turkish - Yildirim",
    "en.sahih": "English - Sahih International",
    "ar": "Arabic",
}

async def fetch_surah_list():
    """Fetch list of all surahs"""
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{ALQURAN_API}/surah")
        response.raise_for_status()
        return response.json()["data"]

async def fetch_surah_verses(surah_number: int, edition: str = "quran-uthmani"):
    """Fetch verses for a specific surah"""
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{ALQURAN_API}/surah/{surah_number}/{edition}")
        response.raise_for_status()
        return response.json()["data"]["ayahs"]

async def fetch_surah_translation(surah_number: int, translation: str = "tr.yildirim"):
    """Fetch translation for a specific surah"""
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{ALQURAN_API}/surah/{surah_number}/{translation}")
        response.raise_for_status()
        return response.json()["data"]["ayahs"]

async def import_quran():
    """Main import function"""
    print("Kuran verileri import ediliyor...")
    
    # Create tables
    Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    
    try:
        # Check if already imported
        existing = db.query(Surah).first()
        if existing:
            print("Veriler zaten import edilmiş. Temizlenip tekrar import edilsin mi? (y/n)")
            response = input().lower()
            if response == 'y':
                db.query(Verse).delete()
                db.query(Surah).delete()
                db.commit()
                print("Eski veriler temizlendi.")
            else:
                print("Import iptal edildi.")
                return
        
        # Fetch surah list
        print("Sure listesi çekiliyor...")
        surahs = await fetch_surah_list()
        
        for surah_data in surahs:
            surah_number = surah_data["number"]
            print(f"Sure {surah_number}/{len(surahs)}: {surah_data['englishName']} import ediliyor...")
            
            # Create Surah
            surah = Surah(
                number=surah_number,
                name=surah_data["name"],
                english_name=surah_data["englishName"],
                english_name_translation=surah_data["englishNameTranslation"],
                revelation_type=surah_data["revelationType"],
                verses_count=surah_data["numberOfAyahs"]
            )
            db.add(surah)
            db.flush()  # Get the ID
            
            # Fetch Arabic verses
            arabic_verses = await fetch_surah_verses(surah_number, "quran-uthmani")
            
            # Fetch Turkish translation
            try:
                translation_verses = await fetch_surah_translation(surah_number, "tr.yildirim")
            except:
                print(f"  Uyarı: Sure {surah_number} için Türkçe çeviri bulunamadı")
                translation_verses = []
            
            # Create verses
            for i, arabic_verse in enumerate(arabic_verses):
                verse_number = arabic_verse["numberInSurah"]
                
                # Get translation if available
                translation_text = None
                if translation_verses and i < len(translation_verses):
                    translation_text = translation_verses[i]["text"]
                
                verse = Verse(
                    surah_id=surah.id,
                    number=verse_number,
                    text_arabic=arabic_verse["text"],
                    text_translation=translation_text,
                    juz=arabic_verse.get("juz"),
                    page=arabic_verse.get("page")
                )
                db.add(verse)
            
            db.commit()
            print(f"  ✓ {len(arabic_verses)} ayet import edildi")
        
        print("\n✅ Import tamamlandı!")
        
    except Exception as e:
        print(f"\n❌ Hata: {e}")
        db.rollback()
        raise
    finally:
        db.close()

if __name__ == "__main__":
    asyncio.run(import_quran())
