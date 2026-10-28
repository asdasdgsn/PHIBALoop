#!/bin/zsh
set -euo pipefail

script_dir="${0:A:h}"
project_dir="${script_dir:h}"
app_dir="$project_dir/dist/PHIBALoop.app"

swift build --package-path "$project_dir" -c release
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
cp "$project_dir/.build/release/PHIBALoop" "$app_dir/Contents/MacOS/PHIBALoop"
cp "$project_dir/Packaging/Info.plist" "$app_dir/Contents/Info.plist"
cp "$project_dir/Packaging/AppIcon.icns" "$app_dir/Contents/Resources/AppIcon.icns"
chmod +x "$app_dir/Contents/MacOS/PHIBALoop"
codesign --force --deep --sign - "$app_dir"
plutil -lint "$app_dir/Contents/Info.plist"
test -x "$app_dir/Contents/MacOS/PHIBALoop"
test -s "$app_dir/Contents/Resources/AppIcon.icns"
echo "$app_dir"
