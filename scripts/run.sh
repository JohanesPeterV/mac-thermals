#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

swift build
fan_binary_dir="$(swift build --show-bin-path)"
fan_app_dir="$PWD/.build/Mac Better Fan Control.app"

mkdir -p "$fan_app_dir/Contents/MacOS" "$fan_app_dir/Contents/Resources"
cp "$fan_binary_dir/MacBetterFanControl" "$fan_app_dir/Contents/MacOS/MacBetterFanControl"
cp Resources/Logo.png "$fan_app_dir/Contents/Resources/Logo.png"
cp Resources/AppIcon.icns "$fan_app_dir/Contents/Resources/AppIcon.icns"
cp Resources/Info.plist "$fan_app_dir/Contents/Info.plist"
plutil -lint "$fan_app_dir/Contents/Info.plist"
codesign --force --sign - "$fan_app_dir"
open "$fan_app_dir"
