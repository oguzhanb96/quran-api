# Coolify Deploy Talimatlari

## 1. GitHub Repo'yu Guncelle

Server klasorundeki degisiklikleri push et:

```bash
cd /Users/Oguzhan/Desktop/Projeler/Quran
git add server/
git commit -m "Update server with Supabase token verification"
git push origin main
```

## 2. Coolify'da Environment Variables Ekle

Coolify Dashboard → quran-api projesi → Environment Variables:

| Key | Value | Aciklama |
|-----|-------|----------|
| `PORT` | `8787` | Server portu |
| `ADMIN_TOKEN` | `rastgele-32-karakter-token` | Admin islemleri icin |
| `SUPABASE_URL` | `https://xyuokjpsssdbosljtcpm.supabase.co` | Supabase proje URL |
| `SUPABASE_ANON_KEY` | `sb_publishable_JTO7dUPFQLxPLO3Z6vJ3yA_lMgIgj4A` | Supabase anon key |
| `DATA_DIR` | `./data` | Veri klasoru |

## 3. Build ve Start Komutlari

Coolify'da:
- **Build Command**: `cd server && npm install`
- **Start Command**: `cd server && node src/index.js`
- **Port**: `8787`

## 4. Health Check Test

Deploy sonrasi test et:

```bash
curl http://ruddd40n2hst8yr7ra0rp339.192.227.219.230.sslip.io/api/v1/health
```

## 5. Flutter App Build (Domain Guncelle)

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://xyuokjpsssdbosljtcpm.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_JTO7dUPFQLxPLO3Z6vJ3yA_lMgIgj4A \
  --dart-define=VPS_BASE_URL=http://ruddd40n2hst8yr7ra0rp339.192.227.219.230.sslip.io
```

Not: VPS_BASE_URL'i AppConfig'de degistir veya --dart-define ile ver.

## 6. Supabase Auth Test

Uygulamada kayit olmayi dene. Hata olursa Coolify loglarini kontrol et:
- Coolify Dashboard → Logs

## Guvenlik Kontrol

- [ ] ADMIN_TOKEN rastgele ve uzun (32+ karakter)
- [ ] SUPABASE_ANON_KEY dogru proje anahtari
- [ ] GitHub repo Private (Supabase key gizli kalmali)
