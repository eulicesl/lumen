#!/usr/bin/env bash
#
# capture_onboarding_and_app_store.sh
# Enhanced screenshot capture for Lumen including onboarding flow + existing App Store scenes
#
# Usage:
#   ./scripts/capture_onboarding_and_app_store.sh          # Capture all (onboarding + app store)
#   ./scripts/capture_onboarding_and_app_store.sh --app-store-only   # Skip onboarding
#   ./scripts/capture_onboarding_and_app_store.sh --onboarding-only # Capture just onboarding
#
# Senior Engineer Notes:
# - Onboarding requires uninstall/reinstall to trigger fresh state
# - Uses simctl io screenshot for Apple-quality captures (no status bar chrome in marketing shots)
# - iPhone 6.9" and iPad 13" are the App Store required sizes
# - Output goes to build/app-store-screenshots/ with organized subdirectories

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT/Lumen.xcodeproj"
SCHEME="Lumen"
BUNDLE_ID="com.eulices.lumen"
DERIVED_DATA="$ROOT/build/app-store-derived-data"
OUTPUT_ROOT="$ROOT/build/app-store-screenshots"

# Flags
APP_STORE_ONLY=false
ONBOARDING_ONLY=false

# Parse args
for arg in "$@"; do
  case "$arg" in
    --app-store-only) APP_STORE_ONLY=true ;;
    --onboarding-only) ONBOARDING_ONLY=true ;;
  esac
done

# Device resolution targets
# iPhone 6.9" (1290x2796) - iPhone 15/16 Pro Max, iPhone 17 Pro Max
# iPad 13" (2064x2752) - iPad Pro 13-inch (M4)

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

log() {
  printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$1"
}

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
  xcrun simctl status_bar "$device_id" clear >/dev/null 2>&1 || true
}

boot_device() {
  local device_id="$1"
  xcrun simctl boot "$device_id" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$device_id" -b
  override_status_bar "$device_id"
}

uninstall_app() {
  local device_id="$1"
  log "Uninstalling app from device $device_id..."
  xcrun simctl uninstall "$device_id" "$BUNDLE_ID" >/dev/null 2>&1 || true
  sleep 1
}

build_and_install() {
  local device_id="$1"
  local derived_path="$2"
  local log_file="/tmp/$(basename "$derived_path")-build.log"

  log "Building for device $device_id..."
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "id=$device_id" \
    -derivedDataPath "$derived_path" \
    build >"$log_file" 2>&1 || {
      log "ERROR: Build failed. See $log_file"
      exit 1
    }

  local app_path="$derived_path/Build/Products/Debug-iphonesimulator/Lumen.app"
  log "Installing app on device $device_id..."
  xcrun simctl install "$device_id" "$app_path"
}

launch_app_fresh() {
  local device_id="$1"
  log "Launching app (fresh install, will trigger onboarding)..."
  xcrun simctl launch --terminate-running-process "$device_id" "$BUNDLE_ID" >/dev/null
}

launch_scene() {
  local device_id="$1"
  local scene="$2"
  local delay="${3:-3}"

  log "Launching scene: $scene"
  xcrun simctl terminate "$device_id" "$BUNDLE_ID" >/dev/null 2>&1 || true
  SIMCTL_CHILD_LUMEN_CAPTURE_MODE=1 \
    SIMCTL_CHILD_LUMEN_SCREENSHOT_SCENE="$scene" \
    xcrun simctl launch --terminate-running-process "$device_id" "$BUNDLE_ID" >/dev/null

  sleep "$delay"
}

capture_screenshot() {
  local device_id="$1"
  local output_file="$2"
  log "Capturing: $output_file"
  xcrun simctl io "$device_id" screenshot "$output_file" >/dev/null
}

# MARK: - Onboarding Flow Capture
# NOTE: The simctl 'tap' command doesn't exist. Instead, we use Lumen's existing
# LUMEN_SCREENSHOT_SCENE mechanism. The app must be modified to support:
# - "onboarding-1" through "onboarding-4" scenes
# - These scenes programmatically advance to specific onboarding pages

capture_onboarding_iphone() {
  local device_id="$1"
  local output_dir="$OUTPUT_ROOT/onboarding/iphone-6.9"
  mkdir -p "$output_dir"

  log "=== Capturing Onboarding Flow (iPhone) ==="
  log "WARNING: Onboarding scenes require app support for LUMEN_SCREENSHOT_SCENE=onboarding-N"
  log "For now, capturing launch state after fresh install..."

  # Uninstall to ensure fresh onboarding state
  uninstall_app "$device_id"
  build_and_install "$device_id" "$DERIVED_DATA/iphone-onboarding"

  # Launch and capture first page (app opens to onboarding page 1 on fresh install)
  log "Launching fresh install to capture onboarding page 1..."
  launch_app_fresh "$device_id"
  sleep 3
  capture_screenshot "$device_id" "$output_dir/01-welcome.png"

  log "Onboarding capture complete for iPhone (page 1 only - manual navigation needed for pages 2-4)"
}

capture_onboarding_ipad() {
  local device_id="$1"
  local output_dir="$OUTPUT_ROOT/onboarding/ipad-13"
  mkdir -p "$output_dir"

  log "=== Capturing Onboarding Flow (iPad) ==="
  log "WARNING: Onboarding scenes require app support for LUMEN_SCREENSHOT_SCENE=onboarding-N"
  log "For now, capturing launch state after fresh install..."

  # Uninstall to ensure fresh onboarding state
  uninstall_app "$device_id"
  build_and_install "$device_id" "$DERIVED_DATA/ipad-onboarding"

  # Launch and capture first page
  log "Launching fresh install to capture onboarding page 1..."
  launch_app_fresh "$device_id"
  sleep 3
  capture_screenshot "$device_id" "$output_dir/01-welcome.png"

  log "Onboarding capture complete for iPad (page 1 only - manual navigation needed for pages 2-4)"
}

# MARK: - App Store Scenes (existing functionality)

# Define capture_scene function (needed for App Store scenes)
capture_scene() {
  local device_id="$1"
  local scene="$2"
  local output_file="$3"

  local delay=3
  if [[ "$scene" == "settings" ]]; then
    delay=5
  fi

  log "Launching scene: $scene"
  xcrun simctl terminate "$device_id" "$BUNDLE_ID" >/dev/null 2>&1 || true
  SIMCTL_CHILD_LUMEN_CAPTURE_MODE=1 \
    SIMCTL_CHILD_LUMEN_SCREENSHOT_SCENE="$scene" \
    xcrun simctl launch --terminate-running-process "$device_id" "$BUNDLE_ID" >/dev/null

  sleep "$delay"
  log "Capturing: $output_file"
  xcrun simctl io "$device_id" screenshot "$output_file" >/dev/null
}

capture_app_store_scenes_iphone() {
  local device_id="$1"
  local output_dir="$OUTPUT_ROOT/iphone-6.9"
  mkdir -p "$output_dir"

  log "=== Capturing App Store Scenes (iPhone) ==="

  # Build and install if not already done
  if [[ ! -d "$DERIVED_DATA/iphone/Build" ]]; then
    build_and_install "$device_id" "$DERIVED_DATA/iphone"
  fi

  # Ensure app is in a known state (not showing onboarding)
  xcrun simctl terminate "$device_id" "$BUNDLE_ID" >/dev/null 2>&1 || true

  capture_scene "$device_id" "chat" "$output_dir/01-chat.png"
  capture_scene "$device_id" "search" "$output_dir/02-search.png"
  capture_scene "$device_id" "documents" "$output_dir/03-documents.png"
  capture_scene "$device_id" "settings" "$output_dir/04-settings.png"
  sleep 2  # Extra delay for settings scene

  log "App Store scenes complete for iPhone"
}

capture_app_store_scenes_ipad() {
  local device_id="$1"
  local output_dir="$OUTPUT_ROOT/ipad-13"
  mkdir -p "$output_dir"

  log "=== Capturing App Store Scenes (iPad) ==="

  # Build and install if not already done
  if [[ ! -d "$DERIVED_DATA/ipad/Build" ]]; then
    build_and_install "$device_id" "$DERIVED_DATA/ipad"
  fi

  # Ensure app is in a known state
  xcrun simctl terminate "$device_id" "$BUNDLE_ID" >/dev/null 2>&1 || true

  capture_scene "$device_id" "chat" "$output_dir/01-chat.png"
  capture_scene "$device_id" "documents" "$output_dir/02-documents.png"
  capture_scene "$device_id" "settings" "$output_dir/03-settings.png"
  sleep 2  # Extra delay for settings scene

  log "App Store scenes complete for iPad"
}

# MARK: - First Chat Experience (requires UI test automation - placeholder)

capture_first_chat_iphone() {
  local device_id="$1"
  local output_dir="$OUTPUT_ROOT/first-chat/iphone-6.9"
  mkdir -p "$output_dir"

  log "=== Capturing First Chat Experience (iPhone) ==="
  log "WARNING: First chat automation requires XCTest UI automation or app scene support"
  log "For now, capturing the chat scene (pre-composed state)..."

  # Launch chat scene
  launch_scene "$device_id" "chat" 3
  capture_screenshot "$device_id" "$output_dir/01-chat-ready.png"

  log "First chat capture complete for iPhone (chat scene only)"
}

# MARK: - Main Execution

main() {
  log "Starting Lumen Screenshot Capture"
  log "Output: $OUTPUT_ROOT"
  log "iPhone Device: $IPHONE_ID"
  log "iPad Device: $IPAD_ID"

  mkdir -p "$OUTPUT_ROOT"

  # Boot devices
  boot_device "$IPHONE_ID"
  boot_device "$IPAD_ID"

  if [[ "$APP_STORE_ONLY" != true ]]; then
    # Onboarding requires fresh installs
    capture_onboarding_iphone "$IPHONE_ID"
    capture_onboarding_ipad "$IPAD_ID"
  fi

  if [[ "$ONBOARDING_ONLY" != true ]]; then
    # App store scenes (reuse existing builds where possible)
    capture_app_store_scenes_iphone "$IPHONE_ID"
    capture_app_store_scenes_ipad "$IPAD_ID"

    # First chat experience
    capture_first_chat_iphone "$IPHONE_ID"
  fi

  # Cleanup
  clear_status_bar "$IPHONE_ID"
  clear_status_bar "$IPAD_ID"

  log "=== Capture Complete ==="
  log "Screenshots saved to:"
  find "$OUTPUT_ROOT" -name "*.png" | sort | while read -r f; do
    printf '  %s\n' "${f#$OUTPUT_ROOT/}"
  done
}

main "$@"