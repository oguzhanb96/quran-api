#!/usr/bin/env bash
# Run as the app user. Resolves repo root from this script location.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SRV="${REPO_ROOT}/server"

cd "${SRV}"

if [[ ! -f package.json ]]; then
  echo "No package.json in ${SRV}" >&2
  exit 1
fi

npm ci --omit=dev 2>/dev/null || npm install --omit=dev
