#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP=build/Framewing-dev.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/Player "$APP/Contents/MacOS/Framewing"
cp Resources/Info.plist "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy \
  -c "Set :CFBundleName Framewing-dev" \
  -c "Set :CFBundleDisplayName Framewing-dev" \
  -c "Set :CFBundleIdentifier io.github.ruslan-palahin.framewing.dev" \
  "$APP/Contents/Info.plist"
mkdir -p "$APP/Contents/Resources"
cp -R Resources/*.lproj "$APP/Contents/Resources/"
codesign --force --sign - "$APP"

echo "Built $APP"
