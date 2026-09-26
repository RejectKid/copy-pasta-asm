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
if [[ "${1:-}" == --test ]]; then
  COPY_PASTA_HISTORY="$PWD/build/test-history.json" build/copy-pasta-asm --self-test
fi
