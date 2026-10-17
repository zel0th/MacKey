#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMP="$(mktemp -d "${TMPDIR:-/tmp/}mackey-layouts.XXXXXX")"
trap 'rm -rf "$TEMP"' EXIT
swiftc -parse-as-library -swift-version 6 -module-cache-path "$TEMP/cache" "$ROOT"/Sources/MacKeyCore/*.swift "$ROOT/Sources/MacKey/LayoutCatalog.swift" "$ROOT/Scripts/check-layouts.swift" -o "$TEMP/check-layouts"
"$TEMP/check-layouts"
