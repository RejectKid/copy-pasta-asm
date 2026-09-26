#!/usr/bin/env bash
# Run under xvfb-run. xterm owns the test work surface; xclip owns PRIMARY.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
export COPY_PASTA_HISTORY="$root/build/integration-history.json"
printf '[]' > "$COPY_PASTA_HISTORY"
build/copy-pasta-asm & app=$!
trap 'kill "$app" ${term:-} 2>/dev/null || true' EXIT
sleep 1
printf 'Assembly PRIMARY selection' | xclip -selection primary
xdotool key ctrl+alt+c
sleep 1
python3 - <<'PY'
import os,json
import re
h=json.load(open(os.environ['COPY_PASTA_HISTORY']))
assert len(h)==1 and h[0]['Text']=='Assembly PRIMARY selection',h
assert re.search(r'T\d\d:\d\d:\d\d\.\d{7}Z$',h[0]['CapturedAt']),h
PY
xdotool key ctrl+alt+c
sleep 0.3
python3 - <<'PY'
import os,json
assert len(json.load(open(os.environ['COPY_PASTA_HISTORY'])))==1
PY
xterm -title AssemblyOutput -e sh -c 'cat > build/typed.txt' & term=$!
sleep 1
target=$(xdotool search --name '^AssemblyOutput$' | head -1)
xdotool windowfocus "$target"
xdotool key ctrl+alt+v
sleep 2
xdotool key Return
sleep 0.2
python3 - <<'PY'
from pathlib import Path
assert Path('build/typed.txt').read_text().strip()=='Assembly PRIMARY selection'
print('PASS: X11 PRIMARY capture, duplicate promotion, and XTest keyboard output')
PY
