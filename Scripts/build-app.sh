#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CACHE="${TMPDIR:-/tmp/}MacKey-build"
export CLANG_MODULE_CACHE_PATH="$CACHE/clang"
export SWIFTPM_MODULECACHE_OVERRIDE="$CACHE/modules"
mkdir -p "$CACHE" "$ROOT/build"
swift build --package-path "$ROOT" --scratch-path "$CACHE/products" --cache-path "$CACHE/cache" --config-path "$CACHE/config" --security-path "$CACHE/security" --disable-sandbox --build-system native -c release
BIN_DIR="$(swift build --package-path "$ROOT" --scratch-path "$CACHE/products" --cache-path "$CACHE/cache" --config-path "$CACHE/config" --security-path "$CACHE/security" --disable-sandbox --build-system native -c release --show-bin-path)"
STAGE="$(mktemp -d "$CACHE/package.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
APP="$STAGE/MacKey.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp -X "$BIN_DIR/MacKey" "$APP/Contents/MacOS/MacKey"
cp -X "$ROOT/Info.plist" "$APP/Contents/Info.plist"
cp -X "$ROOT/Design/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$APP"
codesign --verify --deep --strict "$APP"
# iCloud can add FinderInfo to a bundle while it is being signed. Package the
# verified temporary bundle before copying the convenient .app into the workspace.
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")"
ARCHIVE="MacKey-$VERSION-macOS-$(uname -m).zip"
RELEASE_DIR="$ROOT/build/releases"
mkdir -p "$RELEASE_DIR"
ditto -c -k --norsrc --noextattr --keepParent "$APP" "$RELEASE_DIR/$ARCHIVE"
(cd "$RELEASE_DIR" && shasum -a 256 "$ARCHIVE") > "$RELEASE_DIR/SHA256SUMS.txt"
ditto --norsrc --noextattr "$APP" "$ROOT/build/MacKey.app"
printf 'Built: %s\nArchive: %s\n' "$ROOT/build/MacKey.app" "$RELEASE_DIR/$ARCHIVE"
