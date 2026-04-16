# Push this repo to GitHub (run from repo root:  powershell -ExecutionPolicy Bypass -File scripts/git-push-main.ps1 )

# Git prints progress to stderr; do not use $ErrorActionPreference = Stop for native git.
$ErrorActionPreference = "Continue"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

$remoteUrl = "https://github.com/oguzhanb96/quran-api.git"
$remotes = git remote 2>$null
if (-not ($remotes -contains "origin")) {
  git remote add origin $remoteUrl
  Write-Host "Added origin: $remoteUrl" -ForegroundColor Green
} else {
  Write-Host "Remote origin already exists." -ForegroundColor Yellow
}

git fetch origin --quiet

git add -A
$status = git status --porcelain
if (-not $status) {
  Write-Host "Nothing to commit." -ForegroundColor Yellow
} else {
  git commit -m "chore: deploy config and API defaults"
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

git branch -M main
git push -u origin main
exit $LASTEXITCODE
