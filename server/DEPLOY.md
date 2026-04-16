# Hidaya API Server - VPS Deployment Guide

## Net çözüm — sadece Coolify paneli (CLI şart değil)

| Ayar | Değer |
|------|--------|
| Git repository | `https://github.com/oguzhanb96/quran-api` |
| Branch | `main` |
| **Base directory** | `server` |
| **Build command** | *(boş — Nixpacks `server/nixpacks.toml` kullanır)* |
| **Start command** | `node src/index.js` |
| **Port** (uygulama / konteyner) | `8080` *(Traefik’in `loadbalancer.server.port=8080` ile aynı)* |
| Health test | Tarayıcı veya `curl`: `https://SENIN-ALAN/health` |

**Environment (Coolify → uygulama):** `PORT=8080`, `ADMIN_TOKEN`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `DATA_DIR=./data`

**Flutter release:** `--dart-define=VPS_BASE_URL=https://SENIN-ALAN` *(kök URL, path ve sondaki `/` yok; iç port yazma)*

---

## Güvenlik Kontrol Listesi

### Environment Variables (ZORUNLU)
Bu değişkenler `.env` dosyasında AYARLANMALI, kodda hardcoded OLMAMALI:

```bash
# Server — Coolify/Traefik: genelde PORT=8080. Yerel: 8787 veya .env yokken varsayılan.
PORT=8080
ADMIN_TOKEN=your-very-long-random-secret-min-32-chars

# Supabase (Flutter app ile AYNI olmalı)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key

# Data directory
DATA_DIR=./data
```

### Flutter Build Ayarları
Release build için environment variable'ları ayarla:

```bash
# Android
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=VPS_BASE_URL=https://your-api-host

# iOS
flutter build ios --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=VPS_BASE_URL=https://your-api-host
```

`VPS_BASE_URL`: sadece kök adres (path yok, sondaki `/` yok). Örnek: `https://api.example.com` veya `http://203.0.113.10:8787`. Uygulama `/knowledge/...`, `/surah/...`, `/api/v1/auth/...` yollarını buna ekler.

## Coolify (Nixpacks)

Repoda `server/nixpacks.toml` vardır; ikinci `npm ci` (EBUSY) hatasını önlemek için build aşaması no-op’tur.

- **Kaynak dizin / Base directory:** `server` (repo kökü değil)
- **Build Command:** boş bırakın veya Coolify’da kaldırın (yalnızca `nixpacks.toml` yeterli)
- **Install:** Nixpacks `npm ci` çalıştırır
- **Start Command:** `node src/index.js`
- **Port:** `8080` (Traefik’in yönlendirdiği konteyner portu ile aynı; paneldeki “Port” alanı)

Coolify ortam değişkenleri: yukarıdaki `.env` ile aynı anahtarlar (`PORT`, `ADMIN_TOKEN`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `DATA_DIR`).

**Port 8080 vs 8787:** Coolify konteyner içinde `PORT=8080` verebilir; Node `process.env.PORT` ile dinler. Dışarıdan erişim genelde reverse proxy üzerinden **80/443** ile olur; Flutter’da `VPS_BASE_URL` olarak Coolify’ın verdiği **genel adresi** kullanın (`https://...` veya `http://...sslip.io`), iç portu elle yazmayın. Sadece servis doğrudan `http://sunucu:8080` ile yayınlanıyorsa URL’ye `:8080` ekleyin veya uygulama ayarlarından API adresini güncelleyin.

## VPS Deploy Adımları

### 1. Sunucuya Bağlan
```bash
ssh root@YOUR_VPS_IP
```

### 2. Node.js Kur (v20+)
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### 3. Proje Dosyalarını Yükle
```bash
mkdir -p /var/www/hidaya
cd /var/www/hidaya
# SCP veya Git ile dosyaları yükle
git clone <your-repo> .
cd server
```

### 4. Bağımlılıkları Yükle
```bash
npm install
```

### 5. .env Dosyasını Oluştur
```bash
cat > .env << 'EOF'
PORT=8787
ADMIN_TOKEN=$(openssl rand -hex 32)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
DATA_DIR=./data
EOF
```

### 6. PM2 ile Çalıştır
```bash
npm install -g pm2
pm2 start src/index.js --name "hidaya-api"
pm2 save
pm2 startup
```

### 7. Firewall Ayarları
```bash
ufw allow 8787/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```

### 8. Nginx Reverse Proxy (Önerilir)
```bash
apt install nginx
```

`/etc/nginx/sites-available/hidaya-api`:
```nginx
server {
    listen 80;
    server_name api.hidaya.app;

    location / {
        proxy_pass http://localhost:8787;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
ln -s /etc/nginx/sites-available/hidaya-api /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

## Test Endpoint'leri

### Health Check
```bash
curl http://YOUR_VPS_IP:8787/health
curl http://YOUR_VPS_IP:8787/api/v1/health
```

### Premium Activation (Auth gerekli)
```bash
curl -X POST http://YOUR_VPS_IP:8787/api/v1/auth/premium/activate \
  -H "Authorization: Bearer YOUR_SUPABASE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"plan":"monthly","userId":"user-uuid"}'
```

## Güvenlik Kontrolleri

- [ ] `.env` dosyası `.gitignore`'da var
- [ ] `ADMIN_TOKEN` en az 32 karakter, rastgele
- [ ] `SUPABASE_ANON_KEY` doğru proje anahtarı
- [ ] Server sadece `0.0.0.0:8787` dinliyor (dışarıdan erişilebilir)
- [ ] Firewall sadece gerekli portları açık
- [ ] Nginx reverse proxy kullanılıyor (opsiyonel ama önerilir)

## Logları Görüntüle
```bash
pm2 logs hidaya-api
```

## Restart
```bash
pm2 restart hidaya-api
```
