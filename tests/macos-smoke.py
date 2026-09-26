"""Launch the real Cocoa UI on a disposable CI Mac; never grant permissions."""
import os
from pathlib import Path
import subprocess
import time
root = Path(__file__).resolve().parents[1]
env = dict(os.environ, COPY_PASTA_HISTORY=str(root/'build'/'test-history.json'))
p = subprocess.Popen([str(root/'build'/'copy-pasta-asm')], env=env)
try:
    time.sleep(5)
    assert p.poll() is None, f'Cocoa startup failed with exit code {p.returncode}'
    subprocess.run(['screencapture','-x',str(root/'build'/'ui.png')], check=False)
    print('PASS: Cocoa window survives startup without Accessibility permission')
finally:
    if p.poll() is None:
        p.terminate()
        p.wait(timeout=10)
