#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
if [[ "$(uname -m)" == arm64 ]]; then
  clang -arch arm64 src/arm64/macos.S -framework Cocoa -framework ApplicationServices -o build/copy-pasta-asm
else
  nasm -f macho64 --prefix _ -I src/ src/macos.s -o build/macos.o
  clang -arch x86_64 -Wl,-no_pie build/macos.o -framework Cocoa -framework ApplicationServices -o build/copy-pasta-asm
fi
bundle='build/Copy Pasta ASM.app/Contents'
mkdir -p "$bundle/MacOS" "$bundle/Resources" build/AppIcon.iconset
cp build/copy-pasta-asm "$bundle/MacOS/CopyPastaAsm"
cp assets/Info.plist "$bundle/Info.plist"
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" assets/app-icon.png --out "build/AppIcon.iconset/icon_${size}x${size}.png" >/dev/null
  double=$((size*2))
  sips -z "$double" "$double" assets/app-icon.png --out "build/AppIcon.iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns build/AppIcon.iconset -o "$bundle/Resources/AppIcon.icns"
codesign --force --deep --sign - 'build/Copy Pasta ASM.app'
ditto -c -k --keepParent 'build/Copy Pasta ASM.app' build/CopyPastaAsm-macos.zip
if [[ "${1:-}" == --test ]]; then
  COPY_PASTA_HISTORY="$PWD/build/test-history.json" build/copy-pasta-asm --self-test
fi
