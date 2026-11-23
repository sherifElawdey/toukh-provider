#!/bin/sh
# Builds dist/havit-desktop-alerts-<version>.zip for the Chrome Web Store
# (or enterprise force-install). Only runtime files go in the package.
set -eu
cd "$(dirname "$0")/.."
VERSION=$(node -p "require('./manifest.json').version")
OUT="dist/havit-desktop-alerts-${VERSION}.zip"
if grep -q "dashboardUrl: ''" src/config.js; then
  echo "warning: CONFIG.dashboardUrl is empty — \"View order\" will open the in-extension order card." >&2
fi
mkdir -p dist
rm -f "$OUT"
zip -qr "$OUT" manifest.json _locales assets src -x '*.DS_Store'
echo "$OUT ($(du -h "$OUT" | cut -f1))"
