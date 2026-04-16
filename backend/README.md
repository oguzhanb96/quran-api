# Misbah Backend API

FastAPI + PostgreSQL ile Kuran ve namaz vakitleri API'si.

## Kurulum

```bash
# Sanal ortam oluştur
python -m venv venv
source venv/bin/activate  # Linux/Mac
# veya
venv\Scripts\activate  # Windows

# Paketleri kur
pip install -r requirements.txt

# Veritabanı migrasyonları
cd backend
alembic upgrade head

# Sunucuyu başlat
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## API Endpoint'leri

- `GET /api/v1/quran/surah/{surah_number}` - Sure detayları
- `GET /api/v1/quran/search?q={query}` - Kuran'da arama
- `GET /api/v1/prayer/calendar` - Namaz vakitleri takvimi
- `POST /api/v1/auth/register` - Kullanıcı kaydı
- `POST /api/v1/auth/login` - Kullanıcı girişi
- `GET /api/v1/user/favorites` - Favorileri listele
- `POST /api/v1/user/favorites` - Favori ekle
