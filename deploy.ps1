# Hidaya VPS Deploy Script
# PowerShell -ExecutionPolicy Bypass -File deploy.ps1

Write-Host "=== Hidaya API Deploy ===" -ForegroundColor Green

# Bilgileri al
$vpsIP = Read-Host "VPS IP adresini gir (ornek: 192.227.219.230)"
$supabaseUrl = Read-Host "Supabase URL gir (ornek: https://xyuokjpsssdbosljtcpm.supabase.co)"
$supabaseKey = Read-Host "Supabase Anon Key gir" -AsSecureString
$adminToken = -join ((48..57) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})

Write-Host "`n=== GitHub'a Push ===" -ForegroundColor Yellow
cd "$PSScriptRoot"
git add server/
git commit -m "Update server config"
git push origin main

Write-Host "`n=== Flutter Build ===" -ForegroundColor Yellow
Write-Host "Asagidaki komutu kopyala-yapistir:" -ForegroundColor Cyan
Write-Host @"
flutter build apk --release `
  --dart-define=SUPABASE_URL=$supabaseUrl `
  --dart-define=SUPABASE_ANON_KEY=$([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($supabaseKey))) `
  --dart-define=VPS_BASE_URL=http://$vpsIP`:8787
"@

Write-Host "`n=== VPS Deploy Komutlari (SSH ile baglan, sonra bu komutlari calistir) ===" -ForegroundColor Yellow
Write-Host @"
cd /var/www/hidaya
git pull origin main
cd server
npm install

# .env dosyasi olustur
cat > .env << 'EOF'
PORT=8787
ADMIN_TOKEN=$adminToken
SUPABASE_URL=$supabaseUrl
SUPABASE_ANON_KEY=YOUR_SUPABASE_KEY_HERE
DATA_DIR=./data
EOF

# PM2 ile baslat
pm2 restart hidaya-api || pm2 start src/index.js --name "hidaya-api"
pm2 save
"@

Write-Host "`nTamamlandi!" -ForegroundColor Green
Write-Host "ADMIN_TOKEN: $adminToken" -ForegroundColor Magenta
Write-Host "Bu token'i not al, premium admin islemleri icin lazim olacak."
