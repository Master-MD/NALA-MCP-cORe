#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="${NALA_APP_BUNDLE_NAME:-NALA-MCP-cORe-UIStatsPreview}"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
DMG_PATH="$DIST_DIR/$APP_NAME-v0.1.0.dmg"
CHECKSUM_PATH="$DMG_PATH.sha256"

cd "$ROOT_DIR"
NALA_KILL_EXISTING=0 ./script/build_and_run.sh package

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null
fi

rm -f "$DMG_PATH" "$CHECKSUM_PATH"
hdiutil create \
  -volname "$APP_NAME v0.1.0" \
  -srcfolder "$APP_BUNDLE" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

shasum -a 256 "$DMG_PATH" >"$CHECKSUM_PATH"
echo "Created $DMG_PATH"
echo "Created $CHECKSUM_PATH"
