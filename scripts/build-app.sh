#!/usr/bin/env bash
# Generates the Xcode project and builds the app for an available iPhone simulator.
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(xcode-select -p)" == *CommandLineTools* && -d /Applications/Xcode.app ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
command -v xcodegen >/dev/null || { echo "xcodegen missing: brew install xcodegen"; exit 1; }
xcodegen generate --quiet
mkdir -p .build
DEVICE_ID=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"]
ids = [d["udid"] for runtime, ds in devices.items() if "iOS" in runtime for d in ds if d["name"].startswith("iPhone")]
print(ids[-1] if ids else "")')
[[ -n "$DEVICE_ID" ]] || { echo "No iPhone simulator found: xcodebuild -downloadPlatform iOS"; exit 1; }
echo "$DEVICE_ID" > .build/sim-device
xcodebuild -project MealPrep.xcodeproj -scheme MealPrep -destination "id=$DEVICE_ID" \
  -derivedDataPath .build/xcode -quiet build
echo "Build succeeded for simulator $DEVICE_ID"
