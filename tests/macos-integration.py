"""Native Cocoa fixture on the disposable CI Mac. Never changes TCC settings."""
import json
import os
from pathlib import Path
import subprocess
import time
import AppKit as A
import Foundation as F
import Quartz as Q
import ApplicationServices as AX

if os.environ.get('CI') != 'true' or os.environ.get('RUNNER_OS') != 'macOS':
    raise SystemExit('This test requires an isolated macOS runner.')
if not AX.AXIsProcessTrusted():
    print('SKIP: the runner has not granted Accessibility; no permissions were changed.')
    raise SystemExit(0)

root = Path(__file__).resolve().parents[1]
path = root/'build'/'mac-integration-history.json'
path.write_text('[]')
p = subprocess.Popen([str(root/'build'/'copy-pasta-asm')],
                     env=dict(os.environ,COPY_PASTA_HISTORY=str(path)))
app = A.NSApplication.sharedApplication()
app.setActivationPolicy_(A.NSApplicationActivationPolicyRegular)
app.finishLaunching()
window = A.NSWindow.alloc().initWithContentRect_styleMask_backing_defer_(
    ((30,30),(620,400)), A.NSWindowStyleMaskTitled|A.NSWindowStyleMaskClosable,
    A.NSBackingStoreBuffered, False)
window.setReleasedWhenClosed_(False)
window.setTitle_('Assembly integration fixture')
edit = A.NSTextView.alloc().initWithFrame_(((10,10),(600,380)))
window.contentView().addSubview_(edit)

def pump(seconds=.1):
    deadline=time.monotonic()+seconds
    while time.monotonic()<deadline:
        event=app.nextEventMatchingMask_untilDate_inMode_dequeue_(
            A.NSEventMaskAny,F.NSDate.dateWithTimeIntervalSinceNow_(.01),
            F.NSDefaultRunLoopMode,True)
        if event is not None:
            app.sendEvent_(event)
        app.updateWindows()

def wait(pred,reason,timeout=12):
    deadline=time.monotonic()+timeout
    while time.monotonic()<deadline:
        pump()
        if pred(): return
    print('frontmost pid:',A.NSWorkspace.sharedWorkspace().frontmostApplication().processIdentifier(),
          'fixture pid:',os.getpid(),'assembly pid:',p.pid,flush=True)
    system=AX.AXUIElementCreateSystemWide()
    err,focused=AX.AXUIElementCopyAttributeValue(system,'AXFocusedUIElement',None)
    print('focused AX result:',err,focused,flush=True)
    if focused:
        print('selected text:',AX.AXUIElementCopyAttributeValue(focused,'AXSelectedText',None),flush=True)
    subprocess.run(['screencapture','-x',str(root/'build'/'integration-failure.png')],check=False)
    raise AssertionError(reason)

def foreground():
    window.makeKeyAndOrderFront_(None)
    app.activateIgnoringOtherApps_(True)
    window.makeFirstResponder_(edit)
    pump(.2)

def key(code):
    for down in (True,False):
        event=Q.CGEventCreateKeyboardEvent(None,code,down)
        Q.CGEventSetFlags(event,Q.kCGEventFlagMaskControl|Q.kCGEventFlagMaskAlternate)
        Q.CGEventPost(Q.kCGHIDEventTap,event)
    pump(.1)

try:
    pump(2)
    text='Assembly café\nSecond line!'
    edit.setString_(text)
    foreground()
    edit.setSelectedRange_((0,len(text)))
    key(8)
    wait(lambda: len(json.loads(path.read_text()))==1,'AX selected-text capture failed')
    assert json.loads(path.read_text())[0]['Text']==text
    key(8); pump(.5)
    assert len(json.loads(path.read_text()))==1,'Duplicate promotion failed'
    edit.setString_(''); foreground()
    key(9)
    wait(lambda: str(edit.string())==text,'Core Graphics text output failed')
    longtext='Cancellable assembly output. '*100
    edit.setString_(longtext); foreground()
    edit.setSelectedRange_((0,len(longtext)))
    key(8)
    wait(lambda: len(json.loads(path.read_text()))==2,'Second capture failed')
    edit.setString_(''); foreground(); key(9); pump(.3); key(7); pump(.2)
    stopped=str(edit.string())
    assert 0<len(stopped)<len(longtext)
    pump(.3)
    assert str(edit.string())==stopped,'Cancellation failed'
    print('PASS: macOS AX selection, global hotkeys, duplicate promotion, Unicode output, cancellation')
finally:
    window.orderOut_(None)
    if p.poll() is None:
        p.terminate(); p.wait(timeout=10)
