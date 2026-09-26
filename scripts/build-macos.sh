#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
nasm -f macho64 --prefix _ -I src/ src/macos.s -o build/macos.o
clang -arch x86_64 -Wl,-no_pie build/macos.o -framework Cocoa -framework ApplicationServices -o build/copy-pasta-asm
if [[ "${1:-}" == --test ]]; then
  COPY_PASTA_HISTORY="$PWD/build/test-history.json" build/copy-pasta-asm --self-test
fi
