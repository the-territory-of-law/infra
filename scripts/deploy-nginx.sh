#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SRC="$PROJECT_DIR/nginx/sites-available/app.conf"
DST="/etc/nginx/sites-available/app.conf"

if [ ! -f "$SRC" ]; then
  echo "Nginx config not found: $SRC"
  exit 1
fi

sudo cp "$SRC" "$DST"
sudo ln -sf "$DST" /etc/nginx/sites-enabled/app.conf
sudo rm -f /etc/nginx/sites-enabled/default

sudo nginx -t
sudo systemctl reload nginx

echo "Nginx config deployed successfully"
