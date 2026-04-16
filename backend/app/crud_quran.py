from sqlalchemy.orm import Session
from app.models import Surah, Verse, Favorite, Bookmark
from app.schemas import FavoriteCreate, BookmarkCreate
from typing import List, Optional

def get_surahs(db: Session) -> List[Surah]:
    return db.query(Surah).order_by(Surah.number).all()

def get_surah_by_number(db: Session, surah_number: int) -> Optional[Surah]:
    return db.query(Surah).filter(Surah.number == surah_number).first()

def get_surah_with_verses(db: Session, surah_number: int) -> Optional[Surah]:
    return db.query(Surah).filter(Surah.number == surah_number).first()

def search_verses(db: Session, query: str, translation_edition: str = "tr.yildirim") -> List[dict]:
    # Search in translations
    results = db.query(Verse, Surah).join(Surah).filter(
        Verse.text_translation.ilike(f"%{query}%")
    ).limit(50).all()
    
    return [
        {
            "surah_number": surah.number,
            "surah_name": surah.name,
            "verse_number": verse.number,
            "verse_text_arabic": verse.text_arabic,
            "verse_text_translation": verse.text_translation
        }
        for verse, surah in results
    ]

# Favorites CRUD
def get_user_favorites(db: Session, user_id: int) -> List[Favorite]:
    return db.query(Favorite).filter(Favorite.user_id == user_id).all()

def create_favorite(db: Session, user_id: int, favorite: FavoriteCreate) -> Favorite:
    db_favorite = Favorite(
        user_id=user_id,
        surah_id=favorite.surah_id,
        verse_id=favorite.verse_id,
        dua_id=favorite.dua_id
    )
    db.add(db_favorite)
    db.commit()
    db.refresh(db_favorite)
    return db_favorite

def delete_favorite(db: Session, user_id: int, favorite_id: int) -> bool:
    favorite = db.query(Favorite).filter(
        Favorite.id == favorite_id,
        Favorite.user_id == user_id
    ).first()
    if favorite:
        db.delete(favorite)
        db.commit()
        return True
    return False

# Bookmarks CRUD
def get_user_bookmarks(db: Session, user_id: int) -> List[Bookmark]:
    return db.query(Bookmark).filter(Bookmark.user_id == user_id).all()

def create_bookmark(db: Session, user_id: int, bookmark: BookmarkCreate) -> Bookmark:
    # Check if bookmark already exists
    existing = db.query(Bookmark).filter(
        Bookmark.user_id == user_id,
        Bookmark.surah_id == bookmark.surah_id,
        Bookmark.verse_number == bookmark.verse_number
    ).first()
    
    if existing:
        return existing
    
    db_bookmark = Bookmark(
        user_id=user_id,
        surah_id=bookmark.surah_id,
        verse_number=bookmark.verse_number
    )
    db.add(db_bookmark)
    db.commit()
    db.refresh(db_bookmark)
    return db_bookmark

def delete_bookmark(db: Session, user_id: int, bookmark_id: int) -> bool:
    bookmark = db.query(Bookmark).filter(
        Bookmark.id == bookmark_id,
        Bookmark.user_id == user_id
    ).first()
    if bookmark:
        db.delete(bookmark)
        db.commit()
        return True
    return False
