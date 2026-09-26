#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
nasm -f elf64 -g -F dwarf -I src/ src/linux.s -o build/linux.o
cc -no-pie -Wl,-z,noexecstack build/linux.o $(pkg-config --libs gtk+-3.0 x11 xtst) -o build/copy-pasta-asm
if [[ "${1:-}" == --test ]]; then
  COPY_PASTA_HISTORY="$PWD/build/test-history.json" build/copy-pasta-asm --self-test
fi
