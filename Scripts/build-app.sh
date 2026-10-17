#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CACHE="${TMPDIR:-/tmp/}MacKey-build"
export CLANG_MODULE_CACHE_PATH="$CACHE/clang"
export SWIFTPM_MODULECACHE_OVERRIDE="$CACHE/modules"
mkdir -p "$CACHE" "$ROOT/build"
swift build --package-path "$ROOT" --scratch-path "$CACHE/products" --cache-path "$CACHE/cache" --config-path "$CACHE/config" --security-path "$CACHE/security" --disable-sandbox --build-system native -c release
BIN_DIR="$(swift build --package-path "$ROOT" --scratch-path "$CACHE/products" --cache-path "$CACHE/cache" --config-path "$CACHE/config" --security-path "$CACHE/security" --disable-sandbox --build-system native -c release --show-bin-path)"
APP="$ROOT/build/MacKey.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/MacKey" "$APP/Contents/MacOS/MacKey"
cp "$ROOT/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Design/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
if xattr -p com.apple.FinderInfo "$APP" >/dev/null 2>&1; then
  xattr -d com.apple.FinderInfo "$APP"
fi
codesign --force --sign - "$APP"
printf 'Built: %s\n' "$APP"
