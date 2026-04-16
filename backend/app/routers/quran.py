from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload
from typing import List
from app.database import get_db
from app.schemas import (
    SurahResponse, SurahListResponse, VerseResponse,
    FavoriteCreate, FavoriteResponse, BookmarkCreate, BookmarkResponse,
    SearchResponse
)
from app.crud_quran import (
    get_surahs, get_surah_with_verses, search_verses,
    get_user_favorites, create_favorite, delete_favorite,
    get_user_bookmarks, create_bookmark, delete_bookmark
)
from app.routers.auth import get_current_user

router = APIRouter(prefix="/quran", tags=["quran"])

@router.get("/surah", response_model=List[SurahListResponse])
def list_surahs(db: Session = Depends(get_db)):
    """Get list of all surahs"""
    surahs = get_surahs(db)
    return surahs

@router.get("/surah/{surah_number}", response_model=SurahResponse)
def get_surah(surah_number: int, db: Session = Depends(get_db)):
    """Get surah with all verses"""
    surah = get_surah_with_verses(db, surah_number)
    if not surah:
        raise HTTPException(status_code=404, detail="Surah not found")
    return surah

@router.get("/search", response_model=SearchResponse)
def search(
    q: str = Query(..., min_length=2, description="Search query"),
    translation: str = Query("tr.yildirim", description="Translation edition"),
    db: Session = Depends(get_db)
):
    """Search verses in translations"""
    results = search_verses(db, q, translation)
    return {
        "query": q,
        "count": len(results),
        "results": results
    }

# Favorites endpoints
@router.get("/favorites", response_model=List[FavoriteResponse])
def list_favorites(
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get user's favorite verses/surahs"""
    return get_user_favorites(db, current_user.id)

@router.post("/favorites", response_model=FavoriteResponse)
def add_favorite(
    favorite: FavoriteCreate,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Add a favorite"""
    return create_favorite(db, current_user.id, favorite)

@router.delete("/favorites/{favorite_id}")
def remove_favorite(
    favorite_id: int,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Remove a favorite"""
    success = delete_favorite(db, current_user.id, favorite_id)
    if not success:
        raise HTTPException(status_code=404, detail="Favorite not found")
    return {"message": "Favorite removed"}

# Bookmarks endpoints
@router.get("/bookmarks", response_model=List[BookmarkResponse])
def list_bookmarks(
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get user's bookmarks"""
    return get_user_bookmarks(db, current_user.id)

@router.post("/bookmarks", response_model=BookmarkResponse)
def add_bookmark(
    bookmark: BookmarkCreate,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Add a bookmark"""
    return create_bookmark(db, current_user.id, bookmark)

@router.delete("/bookmarks/{bookmark_id}")
def remove_bookmark(
    bookmark_id: int,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Remove a bookmark"""
    success = delete_bookmark(db, current_user.id, bookmark_id)
    if not success:
        raise HTTPException(status_code=404, detail="Bookmark not found")
    return {"message": "Bookmark removed"}
