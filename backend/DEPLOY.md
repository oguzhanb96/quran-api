# Deployment Guide

## 1. Sunucu Hazırlığı

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y python3-pip python3-venv postgresql postgresql-contrib nginx

# PostgreSQL kullanıcısı oluştur
sudo -u postgres psql -c "CREATE USER misbah WITH PASSWORD 'your_password';"
sudo -u postgres psql -c "CREATE DATABASE misbah_db OWNER misbah;"
```

## 2. Backend Kurulumu

```bash
# Proje dizinine git
cd /var/www/misbah/backend

# Sanal ortam
python3 -m venv venv
source venv/bin/activate

# Paketler
pip install -r requirements.txt

# Ortam değişkenleri
cat > .env << EOF
DATABASE_URL=postgresql://misbah:your_password@localhost:5432/misbah_db
SECRET_KEY=your-super-secret-key-change-this
EOF

# Veritabanı tabloları
alembic upgrade head

# Kuran verilerini import et
python scripts/import_quran.py
```

## 3. Systemd Service

```bash
sudo tee /etc/systemd/system/misbah-api.service << EOF
[Unit]
Description=Misbah API
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/var/www/misbah/backend
Environment="PATH=/var/www/misbah/backend/venv/bin"
Environment="DATABASE_URL=postgresql://misbah:your_password@localhost:5432/misbah_db"
Environment="SECRET_KEY=your-super-secret-key"
ExecStart=/var/www/misbah/backend/venv/bin/uvicorn main:app --host 127.0.0.1 --port 8000

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable misbah-api
sudo systemctl start misbah-api
```

## 4. Nginx Reverse Proxy

```bash
sudo tee /etc/nginx/sites-available/misbah << EOF
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/misbah /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## 5. SSL (Let's Encrypt)

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d api.yourdomain.com
```

## 6. Flutter'da API URL Değişikliği

`lib/core/network/app_dio.dart` dosyasında:

```dart
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: 'https://api.yourdomain.com/api/v1',  // Kendi sunucunuz
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ),
  );
});
```

## API Endpoint'leri

| Endpoint | Method | Açıklama |
|----------|--------|----------|
| `/api/v1/auth/register` | POST | Kayıt ol |
| `/api/v1/auth/login` | POST | Giriş yap |
| `/api/v1/auth/me` | GET | Kullanıcı bilgisi |
| `/api/v1/auth/settings` | GET/PUT | Kullanıcı ayarları |
| `/api/v1/quran/surah` | GET | Sure listesi |
| `/api/v1/quran/surah/{id}` | GET | Sure detayları |
| `/api/v1/quran/search?q=...` | GET | Arama |
| `/api/v1/quran/favorites` | GET/POST | Favoriler |
| `/api/v1/quran/bookmarks` | GET/POST | Yer imleri |
| `/api/v1/prayer/calendar` | GET | Namaz vakitleri |
| `/api/v1/prayer/methods` | GET | Hesaplama yöntemleri |

## Dokümantasyon

API çalıştığında otomatik dokümantasyon:
- Swagger UI: `http://api.yourdomain.com/docs`
- ReDoc: `http://api.yourdomain.com/redoc`
