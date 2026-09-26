"""Runs only on a disposable CI desktop, never the owner's active desktop.

The fixture owns every window and file it touches. Tests the actual assembly
UIA capture and SendInput output, including Unicode, duplicates and cancellation.
"""
import ctypes as C
from ctypes import wintypes as W
import json
import re
import os
from pathlib import Path
import subprocess
import time

if os.environ.get('CI') != 'true' or os.environ.get('RUNNER_OS') != 'Windows':
    raise SystemExit('This test requires an isolated GitHub Actions Windows desktop.')

u = C.WinDLL('user32', use_last_error=True)
k = C.WinDLL('kernel32', use_last_error=True)
def bind(dll, name, restype, *args):
    f = getattr(dll, name)
    f.restype, f.argtypes = restype, args
    return f
create = bind(u, 'CreateWindowExW', W.HWND, W.DWORD, W.LPCWSTR, W.LPCWSTR,
              W.DWORD, C.c_int, C.c_int, C.c_int, C.c_int, W.HWND, W.HMENU, W.HINSTANCE, C.c_void_p)
send = bind(u, 'SendMessageW', C.c_ssize_t, W.HWND, W.UINT, C.c_size_t, C.c_ssize_t)
post = bind(u, 'PostMessageW', W.BOOL, W.HWND, W.UINT, C.c_size_t, C.c_ssize_t)
settext = bind(u, 'SetWindowTextW', W.BOOL, W.HWND, W.LPCWSTR)
gettext = bind(u, 'GetWindowTextW', C.c_int, W.HWND, W.LPWSTR, C.c_int)
focus = bind(u, 'SetFocus', W.HWND, W.HWND)
front = bind(u, 'SetForegroundWindow', W.BOOL, W.HWND)
show = bind(u, 'ShowWindow', W.BOOL, W.HWND, C.c_int)
find = bind(u, 'FindWindowW', W.HWND, W.LPCWSTR, W.LPCWSTR)
child = bind(u, 'GetDlgItem', W.HWND, W.HWND, C.c_int)
destroy = bind(u, 'DestroyWindow', W.BOOL, W.HWND)
peek = bind(u, 'PeekMessageW', W.BOOL, C.POINTER(W.MSG), W.HWND, W.UINT, W.UINT, W.UINT)
dispatch = bind(u, 'DispatchMessageW', C.c_ssize_t, C.POINTER(W.MSG))
translate = bind(u, 'TranslateMessage', W.BOOL, C.POINTER(W.MSG))

def pump(seconds=0.1):
    end = time.monotonic() + seconds
    msg = W.MSG()
    while time.monotonic() < end:
        while peek(C.byref(msg), None, 0, 0, 1):
            translate(C.byref(msg)); dispatch(C.byref(msg))
        time.sleep(0.005)

def wait_for(pred, description, timeout=12):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        pump()
        if pred():
            return
    raise AssertionError(description)

def value(hwnd):
    buf = C.create_unicode_buffer(300000)
    gettext(hwnd, buf, len(buf))
    return buf.value

root = Path(__file__).resolve().parents[1]
history = root / 'build' / 'integration-history.json'
history.write_text('[]', encoding='utf-8')
env = dict(os.environ, COPY_PASTA_HISTORY=str(history))
proc = subprocess.Popen([str(root / 'build' / 'copy-pasta-asm.exe')], env=env)
host = edit = None
try:
    wait_for(lambda: find('CopyPastaAssembly', None), 'App did not open')
    app = find('CopyPastaAssembly', None)
    host = create(0, 'STATIC', 'Assembly integration fixture', 0x10CF0000,
                  40, 40, 640, 400, None, None, None, None)
    edit = create(0, 'EDIT', '', 0x50B100C4, 10, 10, 600, 320, host, 1, None, None)
    assert host and edit, C.get_last_error()
    text = 'Assembly café 🍝\r\nSecond line!'
    settext(edit, text)
    front(host); focus(edit)
    send(edit, 0xB1, 0, -1)
    pump()
    post(app, 0x312, 100, 0)
    wait_for(lambda: len(json.loads(history.read_text('utf-8'))) == 1, 'Selection capture failed')
    entry = json.loads(history.read_text('utf-8'))[0]
    assert re.search(r'T\d\d:\d\d:\d\d\.\d{7}Z$', entry['CapturedAt']), entry
    assert entry['Text'] == text, entry
    post(app, 0x312, 100, 0)
    pump(1)
    assert len(json.loads(history.read_text('utf-8'))) == 1, 'Duplicate was not promoted'
    settext(edit, '')
    front(host); focus(edit)
    post(app, 0x312, 101, 0)
    wait_for(lambda: value(edit) == text, f'Unicode/newline typing mismatch: {value(edit)!r}')
    # Snapshot ownership: removing history while typing must not free the text in use.
    longtext = 'Cancellation and owned snapshot. ' * 150
    settext(edit, longtext)
    front(host); focus(edit); send(edit, 0xB1, 0, -1)
    post(app, 0x312, 100, 0)
    wait_for(lambda: len(json.loads(history.read_text('utf-8'))) == 2, 'Second capture failed')
    settext(edit, '')
    front(host); focus(edit)
    post(app, 0x312, 101, 0)
    pump(0.3)
    post(app, 0x111, 10, 0)
    pump(0.2)
    post(app, 0x312, 102, 0)
    pump(0.2)
    stopped = value(edit)
    assert 0 < len(stopped) < len(longtext), len(stopped)
    pump(0.3)
    assert value(edit) == stopped, 'Cancellation did not stop output'
    assert proc.poll() is None, 'App crashed during history removal'
    post(app, 0x111, 11, 0)
    wait_for(lambda: json.loads(history.read_text('utf-8')) == [], 'Clear was not persisted')
    print('PASS: Windows UIA capture, duplicates, Unicode/newline output, cancellation, snapshot ownership, clear')
finally:
    if host:
        destroy(host)
    if proc.poll() is None:
        post(find('CopyPastaAssembly', None), 0x10, 0, 0)
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.terminate()
