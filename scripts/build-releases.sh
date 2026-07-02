#!/usr/bin/env bash
set -euo pipefail

# Build release binaries for macOS (arm64) and Windows (amd64).
# Output artifacts are written to ./dist.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="print-agent"

mkdir -p "$DIST_DIR"
rm -f "$DIST_DIR"/*

echo "Building release binaries into: $DIST_DIR"

build() {
  local goos="$1"
  local goarch="$2"
  local ext="$3"
  local outfile="$DIST_DIR/${APP_NAME}-${goos}-${goarch}${ext}"

  echo "-> ${goos}/${goarch}"
  (
    cd "$ROOT_DIR"
    CGO_ENABLED=0 GOOS="$goos" GOARCH="$goarch" \
      go build -trimpath -ldflags="-s -w" -o "$outfile" .
  )

  echo "   created: $(basename "$outfile")"
}

build darwin arm64 ""
build windows amd64 ".exe"

if command -v zip >/dev/null 2>&1; then
  (
    cd "$DIST_DIR"
    zip -q "${APP_NAME}-windows-amd64.zip" "${APP_NAME}-windows-amd64.exe"
  )
  echo "   package: ${APP_NAME}-windows-amd64.zip"
fi

if command -v tar >/dev/null 2>&1; then
  (
    cd "$DIST_DIR"
    tar -czf "${APP_NAME}-darwin-arm64.tar.gz" "${APP_NAME}-darwin-arm64"
  )
  echo "   package: ${APP_NAME}-darwin-arm64.tar.gz"
fi

if command -v sha256sum >/dev/null 2>&1; then
  (
    cd "$DIST_DIR"
    sha256sum * > SHA256SUMS
  )
  echo "   checksum: SHA256SUMS"
elif command -v shasum >/dev/null 2>&1; then
  (
    cd "$DIST_DIR"
    shasum -a 256 * > SHA256SUMS
  )
  echo "   checksum: SHA256SUMS"
fi

echo "Done. Artifacts:"
ls -lh "$DIST_DIR"
