#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT/Lumen.xcodeproj"
SCHEME="Lumen"
BUNDLE_ID="com.eulices.lumen"
DERIVED_DATA="$ROOT/build/app-store-derived-data"
OUTPUT_ROOT="$ROOT/build/app-store-screenshots"

resolve_device_id() {
  local device_name

  for device_name in "$@"; do
    local device_id
    device_id="$(
      xcrun simctl list devices available |
        grep -F "$device_name" |
        grep -v unavailable |
        grep -m 1 -oE '[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}'
    )"

    if [[ -n "$device_id" ]]; then
      printf '%s\n' "$device_id"
      return 0
    fi
  done

  return 1
}

IPHONE_ID="${IPHONE_SIMULATOR_ID:-$(resolve_device_id "iPhone 17 Pro Max" "iPhone 16 Pro Max")}"
IPAD_ID="${IPAD_SIMULATOR_ID:-$(resolve_device_id "iPad Pro 13-inch" "iPad Pro 13-inch (M4)")}"

if [[ -z "${IPHONE_ID:-}" || -z "${IPAD_ID:-}" ]]; then
  printf 'Required simulators were not found. Install an available 6.9-inch iPhone and 13-inch iPad runtime, or set IPHONE_SIMULATOR_ID and IPAD_SIMULATOR_ID.\n' >&2
  exit 1
fi

override_status_bar() {
  local device_id="$1"
  xcrun simctl status_bar "$device_id" override \
    --time "9:41" \
    --dataNetwork wifi \
    --wifiMode active \
    --wifiBars 3 \
    --cellularMode active \
    --cellularBars 4 \
    --batteryState charged \
    --batteryLevel 100 >/dev/null
}

clear_status_bar() {
  local device_id="$1"
  xcrun simctl status_bar "$device_id" clear >/dev/null || true
}

boot_device() {
  local device_id="$1"
  xcrun simctl boot "$device_id" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$device_id" -b
  override_status_bar "$device_id"
}

build_and_install() {
  local device_id="$1"
  local derived_path="$2"

  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "id=$device_id" \
    -derivedDataPath "$derived_path" \
    build >/tmp/"$(basename "$derived_path")"-build.log

  local app_path="$derived_path/Build/Products/Debug-iphonesimulator/Lumen.app"
  xcrun simctl install "$device_id" "$app_path"
}

launch_scene() {
  local device_id="$1"
  local scene="$2"
  local delay=3

  if [[ "$scene" == "settings" ]]; then
    delay=5
  fi

  xcrun simctl terminate "$device_id" "$BUNDLE_ID" >/dev/null 2>&1 || true
  SIMCTL_CHILD_LUMEN_CAPTURE_MODE=1 \
    SIMCTL_CHILD_LUMEN_SCREENSHOT_SCENE="$scene" \
    xcrun simctl launch --terminate-running-process "$device_id" "$BUNDLE_ID" >/dev/null

  sleep "$delay"
}

capture_scene() {
  local device_id="$1"
  local scene="$2"
  local output_file="$3"

  launch_scene "$device_id" "$scene"
  xcrun simctl io "$device_id" screenshot "$output_file" >/dev/null
}

mkdir -p "$OUTPUT_ROOT/iphone-6.9" "$OUTPUT_ROOT/ipad-13"

boot_device "$IPHONE_ID"
boot_device "$IPAD_ID"

build_and_install "$IPHONE_ID" "$DERIVED_DATA/iphone"
build_and_install "$IPAD_ID" "$DERIVED_DATA/ipad"

capture_scene "$IPHONE_ID" "chat" "$OUTPUT_ROOT/iphone-6.9/01-chat.png"
capture_scene "$IPHONE_ID" "search" "$OUTPUT_ROOT/iphone-6.9/02-search.png"
capture_scene "$IPHONE_ID" "documents" "$OUTPUT_ROOT/iphone-6.9/03-documents.png"
capture_scene "$IPHONE_ID" "settings" "$OUTPUT_ROOT/iphone-6.9/04-settings.png"

capture_scene "$IPAD_ID" "chat" "$OUTPUT_ROOT/ipad-13/01-chat.png"
capture_scene "$IPAD_ID" "documents" "$OUTPUT_ROOT/ipad-13/02-documents.png"
capture_scene "$IPAD_ID" "settings" "$OUTPUT_ROOT/ipad-13/03-settings.png"

clear_status_bar "$IPHONE_ID"
clear_status_bar "$IPAD_ID"

printf 'Screenshots saved to %s\n' "$OUTPUT_ROOT"
