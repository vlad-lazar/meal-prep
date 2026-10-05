#!/usr/bin/env bash
# Builds, signs and installs the app on the first connected physical iPhone (also used for the 7-day refresh).
# Needs Config/Local.xcconfig with your DEVELOPMENT_TEAM (see Config/Local.xcconfig.example).
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(xcode-select -p)" == *CommandLineTools* && -d /Applications/Xcode.app ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
xcodegen generate --quiet
mkdir -p .build
xcrun devicectl list devices --json-output .build/devices.json >/dev/null
DEVICE_ID=$(python3 -c '
import json
devices = json.load(open(".build/devices.json"))["result"]["devices"]
phones = [d for d in devices if d["hardwareProperties"].get("reality") == "physical"
          and d["hardwareProperties"].get("deviceType") == "iPhone"]
print(phones[0]["hardwareProperties"]["udid"] if phones else "")')
[[ -n "$DEVICE_ID" ]] || { echo "No iPhone connected — plug it in and unlock it."; exit 1; }
xcodebuild -project MealPrep.xcodeproj -scheme MealPrep -configuration Debug \
  -destination "id=$DEVICE_ID" -derivedDataPath .build/xcode-device \
  -allowProvisioningUpdates -allowProvisioningDeviceRegistration -quiet build
APP=.build/xcode-device/Build/Products/Debug-iphoneos/MealPrep.app
xcrun devicectl device install app --device "$DEVICE_ID" "$APP"
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$APP/Info.plist")
xcrun devicectl device process launch --device "$DEVICE_ID" "$BUNDLE_ID" \
  || echo "Installed. If it didn't open: iPhone Settings → General → VPN & Device Management → trust your Apple ID, then tap the app."
