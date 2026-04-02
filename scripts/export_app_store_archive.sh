#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCHIVE_PATH="${ARCHIVE_PATH:-$ROOT_DIR/build/Lumen.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-$ROOT_DIR/build/app-store-export}"
EXPORT_OPTIONS_PLIST="${EXPORT_OPTIONS_PLIST:-$ROOT_DIR/exportOptions-appstore.plist}"

# Force Apple's system toolchain first. Homebrew rsync ahead of /usr/bin can break
# xcodebuild's IPA packaging step with a generic "Copy failed" error.
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

rm -rf "$EXPORT_PATH"

xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
  -exportPath "$EXPORT_PATH"
