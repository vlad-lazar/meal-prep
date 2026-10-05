#!/usr/bin/env bash
# Runs MealPrepCore tests. With only the Command Line Tools installed, Swift Testing
# needs explicit framework search/rpath flags; with full Xcode a plain `swift test` works.
set -euo pipefail
cd "$(dirname "$0")/../Core"
if [[ "$(xcode-select -p)" == *CommandLineTools* ]]; then
  CLT=/Library/Developer/CommandLineTools/Library/Developer
  exec swift test \
    -Xswiftc -F -Xswiftc "$CLT/Frameworks" \
    -Xlinker -F -Xlinker "$CLT/Frameworks" \
    -Xlinker -rpath -Xlinker "$CLT/Frameworks" \
    -Xlinker -rpath -Xlinker "$CLT/usr/lib" "$@"
fi
exec swift test "$@"
