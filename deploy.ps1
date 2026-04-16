# Optional helper: prints release build and server env template. Does not commit or push.

param(
  [string]$VpsBaseUrl = "",
  [string]$SupabaseUrl = "",
  [switch]$SkipFlutterHint
)

Write-Host "=== Hidaya deploy helper ===" -ForegroundColor Green

if (-not $SupabaseUrl) {
  $SupabaseUrl = Read-Host "Supabase URL (https://xxx.supabase.co)"
}
$supabaseKeySecure = Read-Host "Supabase Anon Key" -AsSecureString
$supabaseKeyPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
  [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($supabaseKeySecure)
)

if (-not $VpsBaseUrl) {
  $VpsBaseUrl = Read-Host "VPS API base URL (no trailing slash), e.g. https://api.example.com or http://IP:8787"
}

$adminToken = -join ((48..57) + (97..122) | Get-Random -Count 32 | ForEach-Object { [char]$_ })

if (-not $SkipFlutterHint) {
  Write-Host "`n=== Flutter (copy as one block) ===" -ForegroundColor Yellow
  Write-Host @"
flutter build apk --release `
  --dart-define=SUPABASE_URL=$SupabaseUrl `
  --dart-define=SUPABASE_ANON_KEY=$supabaseKeyPlain `
  --dart-define=VPS_BASE_URL=$VpsBaseUrl
"@
}

Write-Host "`n=== server/.env (VPS or local) ===" -ForegroundColor Yellow
Write-Host @"
PORT=8787
ADMIN_TOKEN=$adminToken
SUPABASE_URL=$SupabaseUrl
SUPABASE_ANON_KEY=$supabaseKeyPlain
DATA_DIR=./data
"@

Write-Host "`nADMIN_TOKEN (save securely):" -ForegroundColor Magenta
Write-Host $adminToken
Write-Host "`nDocs: server/DEPLOY.md" -ForegroundColor Cyan
