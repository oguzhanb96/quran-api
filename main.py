from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
import httpx
import random
from datetime import date
from typing import Optional

app = FastAPI(title="Quran API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

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

# --- Sureler ---
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
async def get_surah_with_translations(
    surah_number: int,
    langs: str = Query("ar,tr,en", description="Virgülle ayrılmış dil kodları")
):
    lang_list = [l.strip() for l in langs.split(",")]
    editions = ",".join([EDITIONS.get(l, "quran-uthmani") for l in lang_list])
    async with httpx.AsyncClient() as client:
        r = await client.get(f"{ALQURAN_BASE}/surah/{surah_number}/editions/{editions}")
        data = r.json()
    if data["code"] != 200:
        raise HTTPException(404, "Sure bulunamadı")
    return {"surah_number": surah_number, "editions": data["data"]}


# --- Ayetler ---
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


@app.get("/ayah/{surah_number}/{ayah_number}/translations")
async def get_ayah_translations(
    surah_number: int,
    ayah_number: int,
    langs: str = Query("ar,tr,en")
):
    lang_list = [l.strip() for l in langs.split(",")]
    editions = ",".join([EDITIONS.get(l, "quran-uthmani") for l in lang_list])
    ref = f"{surah_number}:{ayah_number}"
    async with httpx.AsyncClient() as client:
        r = await client.get(f"{ALQURAN_BASE}/ayah/{ref}/editions/{editions}")
        data = r.json()
    if data["code"] != 200:
        raise HTTPException(404, "Ayet bulunamadı")
    return {"reference": ref, "translations": data["data"]}


# --- Arama ---
@app.get("/search")
async def search(
    q: str = Query(..., description="Aranacak kelime"),
    lang: str = "tr",
    surah: Optional[int] = None
):
    edition = EDITIONS.get(lang, "tr.diyanet")
    surah_param = str(surah) if surah else "all"
    async with httpx.AsyncClient() as client:
        r = await client.get(f"{ALQURAN_BASE}/search/{q}/{surah_param}/{edition}")
        data = r.json()
    if data["code"] != 200:
        return {"results": [], "count": 0}
    return {
        "query": q,
        "count": data["data"]["count"],
        "results": data["data"]["matches"]
    }


# --- Günlük Ayet ---
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


# --- Desteklenen diller ---
@app.get("/languages")
async def get_languages():
    return {"languages": list(EDITIONS.keys()), "editions": EDITIONS}


@app.get("/")
async def root():
    return {
        "name": "Quran API",
        "version": "1.0.0",
        "endpoints": [
            "/surahs",
            "/surah/{n}",
            "/surah/{n}/translations",
            "/ayah/{surah}/{ayah}",
            "/ayah/{surah}/{ayah}/translations",
            "/search?q=kelime",
            "/daily-ayah",
            "/languages",
        ]
    }
