from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas import (
    UserCreate, UserResponse, UserLogin, Token,
    UserSettingsUpdate, UserSettingsResponse
)
from app.crud_user import (
    get_user_by_email, create_user, update_user_settings, get_user_settings
)
from app.auth import verify_password, create_access_token, verify_token

router = APIRouter(prefix="/auth", tags=["authentication"])

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/v1/auth/login")

def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> UserResponse:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    payload = verify_token(token)
    if payload is None:
        raise credentials_exception
    
    email: str = payload.get("sub")
    if email is None:
        raise credentials_exception
    
    user = get_user_by_email(db, email=email)
    if user is None:
        raise credentials_exception
    
    return user

@router.post("/register", response_model=UserResponse)
def register(user: UserCreate, db: Session = Depends(get_db)):
    db_user = get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )
    return create_user(db=db, user=user)

@router.post("/login", response_model=Token)
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    user = get_user_by_email(db, email=form_data.username)
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token = create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=UserResponse)
def get_me(current_user: UserResponse = Depends(get_current_user)):
    return current_user

# User settings endpoints
@router.get("/settings", response_model=UserSettingsResponse)
def get_settings(
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    settings = get_user_settings(db, current_user.id)
    if not settings:
        raise HTTPException(status_code=404, detail="Settings not found")
    return settings

@router.put("/settings", response_model=UserSettingsResponse)
def update_settings(
    settings_update: UserSettingsUpdate,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    settings = update_user_settings(db, current_user.id, settings_update)
    if not settings:
        raise HTTPException(status_code=404, detail="Settings not found")
    return settings

from pydantic import BaseModel
from fastapi import Header
import os
from supabase import create_client, Client

class PremiumActivate(BaseModel):
    plan: str
    userId: str

# Use the ones discovered from the Flutter configuration
supabase_url = os.environ.get("SUPABASE_URL")
supabase_key = os.environ.get("SUPABASE_ANON_KEY")
if not supabase_url or not supabase_key:
    supabase_client = None
else:
    supabase_client: Client = create_client(supabase_url, supabase_key)

@router.post("/premium/activate")
def activate_premium(
    payload: PremiumActivate,
    authorization: str = Header(None),
    db: Session = Depends(get_db)
):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Unauthorized")
    token = authorization.split(" ")[1]
    
    try:
        if supabase_client is None:
            raise HTTPException(status_code=503, detail="Supabase not configured")
        user_res = supabase_client.auth.get_user(token)
        if not user_res or not user_res.user:
            raise HTTPException(status_code=401, detail="Invalid Supabase Token")
        
        email = user_res.user.email
        
        db_user = get_user_by_email(db, email=email)
        if not db_user:
            from app.auth import get_password_hash
            new_user = UserCreate(email=email, password=get_password_hash("supabase_oauth"), full_name=email.split("@")[0])
            db_user = create_user(db=db, user=new_user)
            
        db_user.is_premium = True
        db.commit()
        return {"message": "Premium activated successfully", "is_premium": True}
        
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Token verification failed: {str(e)}")
