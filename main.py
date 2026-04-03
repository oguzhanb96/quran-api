from fastapi import FastAPI, HTTPException, Query, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
import httpx
import random
from datetime import date, datetime, timedelta
from typing import Optional
import asyncpg
import os
import jwt
import bcrypt
import uuid

app = FastAPI(title="Quran API", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:password@localhost:5432/quran_db")
JWT_SECRET = os.getenv("JWT_SECRET", "change-this-secret")
JWT_EXPIRE_DAYS = 30

ALQURAN_BASE = "https://api.alquran.cloud/v1"
EDITIONS = {
    "ar": "quran-uthmani",
    "tr": "tr.diyanet",
    "en": "en.asad",
    "de": "de.aburida",
    "fr": "fr.hamidullah",
    "ru": "ru.kuliev",
    "id": "id.indonesian",
}

async def get_db():
    conn = await asyncpg.connect(DATABASE_URL)
    try:
        yield conn
    finally:
        await conn.close()

def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

def verify_password(password: str, hashed: str) -> bool:
    return bcrypt.checkpw(password.encode(), hashed.encode())

def create_token(user_id: str) -> str:
    payload = {
        "sub": user_id,
        "exp": datetime.utcnow() + timedelta(days=JWT_EXPIRE_DAYS)
    }
    return jwt.encode(payload, JWT_SECRET, algorithm="HS256")

async def get_current_user(authorization: str = Header(...), conn=Depends(get_db)):
    try:
        token = authorization.replace("Bearer ", "")
        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        user_id = payload["sub"]
    except:
        raise HTTPException(401, "Geçersiz token")
    user = await conn.fetchrow("SELECT * FROM users WHERE id = $1", uuid.UUID(user_id))
    if not user:
        raise HTTPException(401, "Kullanıcı bulunamadı")
    return user

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    display_name: Optional[str] = None

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class GoogleAuthRequest(BaseModel):
    google_id: str
    email: Optional[str] = None
    display_name: Optional[str] = None

class FavoriteRequest(BaseModel):
    surah_number: int
    ayah_number: int

class HistoryRequest(BaseModel):
    surah_number: int
    ayah_number: int

class PurchaseRequest(BaseModel):
    purchase_token: str
    product_id: str

@app.post("/auth/register")
async def register(req: RegisterRequest, conn=Depends(get_db)):
    existing = await conn.fetchrow("SELECT id FROM users WHERE email = $1", req.email)
    if existing:
        raise HTTPException(400, "Bu email zaten kayıtlı")
    hashed = hash_password(req.password)
    user = await conn.fetchrow(
        "INSERT INTO users (email, password_hash, display_name) VALUES ($1, $2, $3) RETURNING *",
        req.email, hashed, req.display_name
    )
    token = create_token(str(user["id"]))
    return {"token": token, "user": {"id": str(user["id"]), "email": user["email"], "display_name": user["display_name"], "is_premium": user["is_premium"]}}

@app.post("/auth/login")
async def login(req: LoginRequest, conn=Depends(get_db)):
    user = await conn.fetchrow("SELECT * FROM users WHERE email = $1", req.email)
    if not user or not user["password_hash"]:
        raise HTTPException(401, "Email veya şifre hatalı")
    if not verify_password(req.password, user["password_hash"]):
        raise HTTPException(401, "Email veya şifre hatalı")
    token = create_token(str(user["id"]))
    return {"token": token, "user": {"id": str(user["id"]), "email": user["email"], "display_name": user["display_name"], "is_premium": user["is_premium"]}}

@app.post("/auth/google")
async def google_auth(req: GoogleAuthRequest, conn=Depends(get_db)):
    user = await conn.fetchrow("SELECT * FROM users WHERE google_id = $1", req.google_id)
    if not user:
        user = await conn.fetchrow(
            "INSERT INTO users (google_id, email, display_name) VALUES ($1, $2, $3) RETURNING *",
            req.google_id, req.email, req.display_name
        )
    token = create_token(str(user["id"]))
    return {"token": token, "user": {"id": str(user["id"]), "email": user["email"], "display_name": user["display_name"], "is_premium": user["is_premium"]}}

@app.get("/auth/me")
async def get_me(user=Depends(get_current_user)):
    return {"id": str(user["id"]), "email": user["email"], "display_name": user["display_name"], "is_premium": user["is_premium"], "premium_expires_at": str(user["premium_expires_at"]) if user["premium_expires_at"] else None}

@app.get("/favorites")
async def get_favorites(user=Depends(get_current_user), conn=Depends(get_db)):
    rows = await conn.fetch("SELECT * FROM favorites WHERE user_id = $1 ORDER BY created_at DESC", user["id"])
    return {"favorites": [dict(r) for r in rows]}

@app.post("/favorites")
async def add_favorite(req: FavoriteRequest, user=Depends(get_current_user), conn=Depends(get_db)):
    existing = await conn.fetchrow(
        "SELECT id FROM favorites WHERE user_id = $1 AND surah_number = $2 AND ayah_number = $3",
        user["id"], req.surah_number, req.ayah_number
    )
    if existing:
        raise HTTPException(400, "Zaten favorilerde")
    row = await conn.fetchrow(
        "INSERT INTO favorites (user_id, surah_number, ayah_number) VALUES ($1, $2, $3) RETURNING *",
        user["id"], req.surah_number, req.ayah_number
    )
    return dict(row)

@app.delete("/favorites/{surah_number}/{ayah_number}")
async def remove_favorite(surah_number: int, ayah_number: int, user=Depends(get_current_user), conn=Depends(get_db)):
    await conn.execute(
        "DELETE FROM favorites WHERE user_id = $1 AND surah_number = $2 AND ayah_number = $3",
        user["id"], surah_number, ayah_number
    )
    return {"success": True}

@app.post("/history")
async def add_history(req: HistoryRequest, user=Depends(get_current_user), conn=Depends(get_db)):
    await conn.execute(
        "INSERT INTO reading_history (user_id, surah_number, ayah_number) VALUES ($1, $2, $3)",
        user["id"], req.surah_number, req.ayah_number
    )
    return {"success": True}

@app.get("/history")
async def get_history(user=Depends(get_current_user), conn=Depends(get_db)):
    rows = await conn.fetch(
        "SELECT DISTINCT ON (surah_number, ayah_number) * FROM reading_history WHERE user_id = $1 ORDER BY surah_number, ayah_number, read_at DESC",
        user["id"]
    )
    return {"history": [dict(r) for r in rows]}

@app.post("/premium/verify")
async def verify_purchase(req: PurchaseRequest, user=Depends(get_current_user), conn=Depends(get_db)):
    expires_at = datetime.utcnow() + timedelta(days=365)
    await conn.execute(
        "INSERT INTO subscriptions (user_id, purchase_token, product_id, expires_at) VALUES ($1, $2, $3, $4) ON CONFLICT (purchase_token) DO NOTHING",
        user["id"], req.purchase_token, req.product_id, expires_at
    )
    await conn.execute(
        "UPDATE users SET is_premium = TRUE, premium_expires_at = $1 WHERE id = $2",
        expires_at, user["id"]
    )
    return {"success": True, "premium_expires_at": str(expires_at)}

@app.get("/premium/status")
async def premium_status(user=Depends(get_current_user), conn=Depends(get_db)):
    is_active = user["is_premium"] and (user["premium_expires_at"] is None or user["premium_expires_at"] > datetime.utcnow())
    return {"is_premium": is_active, "expires_at": str(user["premium_expires_at"]) if user["premium_expires_at"] else None}

@app.get("/surahs")
async def get_surahs():
    async with httpx.AsyncClient() as client:
        r = await client.get(f"{ALQURAN_BASE}/surah")
        data = r.json()
    if data["code"] != 200:
        raise HTTPException(500, "Veri alınamadı")
    return {"surahs": data["data"]}

@app.get("/surah/{surah_number}")
async def get_surah(surah_number: int, lang: str = "ar"):
    edition = EDITIONS.get(lang, "quran-uthmani")
    async with httpx.AsyncClient() as client:
        r = await client.get(f"{ALQURAN_BASE}/surah/{surah_number}/{edition}")
        data = r.json()
    if data["code"] != 200:
        raise HTTPException(404, "Sure bulunamadı")
    return data["data"]

@app.get("/surah/{surah_number}/translations")
async def get_surah_with_translations(surah_number: int, langs: str = Query("ar,tr,en")):
    lang_list = [l.strip() for l in langs.split(",")]
    editions = ",".join([EDITIONS.get(l, "quran-uthmani") for l in lang_list])
    async with httpx.AsyncClient() as client:
        r = await client.get(f"{ALQURAN_BASE}/surah/{surah_number}/editions/{editions}")
        data = r.json()
    if data["code"] != 200:
        raise HTTPException(404, "Sure bulunamadı")
    return {"surah_number": surah_number, "editions": data["data"]}

@app.get("/ayah/{surah_number}/{ayah_number}")
async def get_ayah(surah_number: int, ayah_number: int, lang: str = "ar"):
    edition = EDITIONS.get(lang, "quran-uthmani")
    ref = f"{surah_number}:{ayah_number}"
    async with httpx.AsyncClient() as client:
        r = await client.get(f"{ALQURAN_BASE}/ayah/{ref}/{edition}")
        data = r.json()
    if data["code"] != 200:
        raise HTTPException(404, "Ayet bulunamadı")
    return data["data"]

@app.get("/search")
async def search(q: str = Query(...), lang: str = "tr", surah: Optional[int] = None):
    edition = EDITIONS.get(lang, "tr.diyanet")
    surah_param = str(surah) if surah else "all"
    async with httpx.AsyncClient() as client:
        r = await client.get(f"{ALQURAN_BASE}/search/{q}/{surah_param}/{edition}")
        data = r.json()
    if data["code"] != 200:
        return {"results": [], "count": 0}
    return {"query": q, "count": data["data"]["count"], "results": data["data"]["matches"]}

@app.get("/daily-ayah")
async def daily_ayah(lang: str = "tr"):
    today = date.today()
    seed = today.year * 10000 + today.month * 100 + today.day
    random.seed(seed)
    surah_num = random.randint(1, 114)
    async with httpx.AsyncClient() as client:
        r = await client.get(f"{ALQURAN_BASE}/surah/{surah_num}")
        surah_data = r.json()
    ayah_count = surah_data["data"]["numberOfAyahs"]
    ayah_num = random.randint(1, ayah_count)
    edition_ar = EDITIONS["ar"]
    edition_lang = EDITIONS.get(lang, "tr.diyanet")
    ref = f"{surah_num}:{ayah_num}"
    async with httpx.AsyncClient() as client:
        r = await client.get(f"{ALQURAN_BASE}/ayah/{ref}/editions/{edition_ar},{edition_lang}")
        data = r.json()
    return {
        "date": str(today),
        "reference": ref,
        "surah_number": surah_num,
        "ayah_number": ayah_num,
        "arabic": data["data"][0]["text"],
        "translation": data["data"][1]["text"],
        "surah_name": data["data"][0]["surah"]["englishName"],
        "surah_name_ar": data["data"][0]["surah"]["name"],
    }

@app.get("/languages")
async def get_languages():
    return {"languages": list(EDITIONS.keys()), "editions": EDITIONS}

@app.get("/")
async def root():
    return {"name": "Quran API", "version": "2.0.0", "status": "running"}
