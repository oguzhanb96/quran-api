from sqlalchemy.orm import Session
from app.models import User, UserSettings
from app.schemas import UserCreate, UserSettingsUpdate
from app.auth import get_password_hash
from typing import Optional

def get_user_by_email(db: Session, email: str) -> Optional[User]:
    return db.query(User).filter(User.email == email).first()

def get_user_by_id(db: Session, user_id: int) -> Optional[User]:
    return db.query(User).filter(User.id == user_id).first()

def create_user(db: Session, user: UserCreate) -> User:
    hashed_password = get_password_hash(user.password)
    db_user = User(
        email=user.email,
        hashed_password=hashed_password,
        full_name=user.full_name
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    # Create default settings for the user
    settings = UserSettings(user_id=db_user.id)
    db.add(settings)
    db.commit()
    
    return db_user

def update_user_settings(db: Session, user_id: int, settings: UserSettingsUpdate) -> Optional[UserSettings]:
    db_settings = db.query(UserSettings).filter(UserSettings.user_id == user_id).first()
    if not db_settings:
        return None
    
    for field, value in settings.model_dump(exclude_unset=True).items():
        setattr(db_settings, field, value)
    
    db.commit()
    db.refresh(db_settings)
    return db_settings

def get_user_settings(db: Session, user_id: int) -> Optional[UserSettings]:
    return db.query(UserSettings).filter(UserSettings.user_id == user_id).first()
