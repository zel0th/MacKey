#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMP="$(mktemp -d "${TMPDIR:-/tmp/}mackey-performance.XXXXXX")"
trap 'rm -rf "$TEMP"' EXIT
swiftc -parse-as-library -swift-version 6 -O -module-cache-path "$TEMP/cache" "$ROOT"/Sources/MacKeyCore/*.swift "$ROOT/Sources/MacKey/LayoutCatalog.swift" "$ROOT/Sources/MacKey/TrainingStore.swift" "$ROOT/Scripts/check-performance.swift" -o "$TEMP/check-performance"
"$TEMP/check-performance"
