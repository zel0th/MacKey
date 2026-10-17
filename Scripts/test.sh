#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CACHE="${TMPDIR:-/tmp/}MacKey-build"
export CLANG_MODULE_CACHE_PATH="$CACHE/clang"
export SWIFTPM_MODULECACHE_OVERRIDE="$CACHE/modules"
FRAMEWORKS="$(xcode-select -p)/Library/Developer/Frameworks"
EXTRA=()
if [ -d "$FRAMEWORKS/Testing.framework" ]; then
  EXTRA=(-Xswiftc -F -Xswiftc "$FRAMEWORKS" -Xlinker -rpath -Xlinker "$FRAMEWORKS")
fi
swift test --package-path "$ROOT" --scratch-path "$CACHE/products" --cache-path "$CACHE/cache" --config-path "$CACHE/config" --security-path "$CACHE/security" --disable-sandbox --build-system native "${EXTRA[@]}"
