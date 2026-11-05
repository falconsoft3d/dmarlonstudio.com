#!/bin/sh
# Compila DMarlon Studio (release), la instala en /Applications y la reinicia.
# Uso: sh scripts/install-mac.sh
set -e
cd "$(dirname "$0")/../studio"
flutter build macos --release
APP="build/macos/Build/Products/Release/DMarlon Studio.app"
pkill -f "DMarlon Studio.app/Contents/MacOS" 2>/dev/null || true
sleep 1
rm -rf "/Applications/DMarlon Studio.app"
ditto "$APP" "/Applications/DMarlon Studio.app"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/DMarlon Studio.app"
open "/Applications/DMarlon Studio.app"
echo "DMarlon Studio $(cat ../VERSION) instalada y abierta."
