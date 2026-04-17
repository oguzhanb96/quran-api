#!/usr/bin/env bash
# Run on Ubuntu 22.04/24.04 as root or with sudo.
# Deploys the Node "server/" API (Express) behind nginx + systemd.
set -euo pipefail

APP_NAME="${APP_NAME:-hidaya-api}"
APP_USER="${APP_USER:-hidaya}"
APP_DIR="${APP_DIR:-/opt/${APP_NAME}}"
NODE_MAJOR="${NODE_MAJOR:-20}"
DOMAIN="${DOMAIN:-}" # optional, e.g. api.example.com — if empty, nginx uses default_server + IP

export DEBIAN_FRONTEND=noninteractive

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Run with sudo or as root." >&2
  exit 1
fi

id -u "${APP_USER}" &>/dev/null || useradd --system --home "${APP_DIR}" --shell /usr/sbin/nologin "${APP_USER}"

apt-get update -y
apt-get install -y ca-certificates curl gnupg git nginx ufw

# Node.js LTS (NodeSource)
if ! command -v node >/dev/null 2>&1 || [[ "$(node -v | cut -d. -f1 | tr -d v)" -lt "${NODE_MAJOR}" ]]; then
  curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash -
  apt-get install -y nodejs
fi

mkdir -p "${APP_DIR}"
chown -R "${APP_USER}:${APP_USER}" "${APP_DIR}"

# Firewall: SSH + HTTP/S
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable || true

echo "Bootstrap done. Next:"
echo "1) Copy project 'server/' tree to ${APP_DIR} (rsync/git clone)."
echo "2) Create ${APP_DIR}/.env (see server/.env.example)."
echo "3) Run: sudo -u ${APP_USER} bash ${APP_DIR}/scripts/deploy/app_install.sh"
echo "4) Install systemd + nginx units from scripts/deploy/ (see DEPLOY_STEPS in vps_bootstrap.sh comments)."
