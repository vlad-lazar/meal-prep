#!/usr/bin/env bash
# Usage: scripts/run-sim.sh <screenshot.png> [launch args...]   (run scripts/build-app.sh first)
# Example: scripts/run-sim.sh .build/detail.png -hasOnboarded YES -debugOpenRecipe chicken-curry
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(xcode-select -p)" == *CommandLineTools* && -d /Applications/Xcode.app ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
DEVICE_ID=$(cat .build/sim-device)
BUNDLE_ID=$(grep -E '^MEALPREP_BUNDLE_ID' Config/Local.xcconfig 2>/dev/null | sed 's/.*= *//' || true)
BUNDLE_ID=${BUNDLE_ID:-dk.vlla.mealprep}
SHOT=$1; shift
APP=.build/xcode/Build/Products/Debug-iphonesimulator/MealPrep.app
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE_ID" -b >/dev/null
xcrun simctl install "$DEVICE_ID" "$APP"
xcrun simctl privacy "$DEVICE_ID" grant location "$BUNDLE_ID" || true
xcrun simctl location "$DEVICE_ID" set 55.6867,12.5530
xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID" "$@" >/dev/null
sleep "${WAIT:-10}"
xcrun simctl io "$DEVICE_ID" screenshot "$SHOT" >/dev/null
echo "Screenshot saved to $SHOT"
