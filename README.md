# Hidaya (Quran Companion)

Flutter uygulaması; İslami içerik, namaz vakitleri ve Kuran okuma özellikleri.

## Repo yapısı

| Dizin | Amaç |
|--------|------|
| `lib/` | Flutter uygulaması |
| `server/` | Node.js API (Express, Coolify/VPS) — ayrıntı: [server/DEPLOY.md](server/DEPLOY.md) |
| `backend/` | Python API (ayrı servis; bu repoda Flutter’ın doğrudan kullandığı varsayılan API `server/`) |
| `supabase/` | Supabase migration ve edge functions |

## Geliştirme

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=VPS_BASE_URL=http://127.0.0.1:8787
```

`VPS_BASE_URL` verilmezse uygulama, derleme zamanında tanımlı **üretim API kök adresine** (Coolify/VPS) döner; ayarlardan da değiştirebilirsiniz.

Yerel API: `cd server && npm ci && node src/index.js` (varsayılan port `8787`; Coolify’da iç port `8080` olabilir — Flutter tarafında her zaman **dışarıdan erişilen URL** kullanılır).

## Üretim API (Coolify)

Varsayılan kök: `https://ruddd40n2hst8yr7ra0rp339.192.227.219.230.sslip.io` (Traefik → konteyner **8080**). Repo: [oguzhanb96/quran-api](https://github.com/oguzhanb96/quran-api).

## GitHub’a gönder (terminal)

Repo kökünde:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/git-push-main.ps1
```

veya elle: `git remote add origin https://github.com/oguzhanb96/quran-api.git` (yoksa), `git add -A`, `git commit -m "..."`, `git push -u origin main`.

## Yayın / dağıtım

- Sunucu ve Coolify: [server/DEPLOY.md](server/DEPLOY.md)
- Yardımcı script: `deploy.ps1` (gizli anahtarı repoya yazmaz; yalnızca ekrana örnek verir)

## GitHub Actions

`.github/workflows/mobile_ci.yml` — `flutter analyze` ve release derlemesi (gizli anahtar gerektirmez; `--dart-define` CI’da opsiyonel).
