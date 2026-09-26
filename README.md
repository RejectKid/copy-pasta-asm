# Copy Pasta ASM

Handwritten assembly port of [Copy Pasta](https://github.com/RejectKid/copy-pasta),
starting from `bf070ef`. Native implementations cover Windows x64, Linux x64/X11,
Intel macOS, and Apple Silicon macOS. See [PARITY.md](PARITY.md) for test coverage
and remaining differences; this is not a claim of exhaustive 1:1 equivalence.

Application logic is assembly. Native libraries provide windows, accessibility,
text rendering, file I/O, and allocation. There is no .NET runtime, JIT, Avalonia,
C/C++/Objective-C application source, or compiler-generated assembly. PowerShell,
shell, and Python are used only for builds and tests.

## Build and run

Windows x64 requires Visual Studio C++ Build Tools and the Windows SDK:

```powershell
./scripts/build-windows.ps1 -Test
./build/copy-pasta-asm.exe
```

The script obtains NASM 3.02 when it is not installed. NASM sources use `.s` and
`.inc` extensions. `-Run` optionally launches the app after building.

Linux x64 requires NASM, a linker/compiler driver, and GTK3, X11, and XTest
development packages:

```sh
bash scripts/build-linux.sh --test
./build/copy-pasta-asm
```

macOS requires Apple's command-line developer tools. Intel Macs also need NASM;
Apple Silicon uses the system assembler directly. Build on the target architecture:

```sh
bash scripts/build-macos.sh --test
open 'build/Copy Pasta ASM.app'
```

The script produces a native `.app` and `build/CopyPastaAsm-macos.zip`. The bundle
is ad-hoc signed, not notarized. Capture and global input require the normal macOS
Accessibility permissions; Input Monitoring may also be required by the OS.

GitHub [Actions](https://github.com/RejectKid/copy-pasta-asm/actions) builds all four
targets and uploads executables and macOS bundles as run artifacts.

## Behavior

* Ctrl+Alt+C captures the current selection without the clipboard.
* Ctrl+Alt+V types the selected history item, one character at a time.
* Ctrl+Alt+X cancels typing.
* History holds at most 50 entries and promotes duplicate text/style pairs.
* Native two-pane window with a draggable divider, history, read-only preview,
  Remove/Clear controls, character counts, dates, and typing status.
* Windows captures style metadata through native UI Automation. Imported font,
  size, weight, italic, foreground, and background metadata is displayed on all
  platforms.
* History is JSON in the user's application data/configuration directory under
  `CopyPastaAsm`. `COPY_PASTA_HISTORY` overrides the file for isolated tests.

The original app's history is not modified. The same Text, CapturedAt, and Style
fields are used. Linux retains the original X11/common-ASCII output limitation.

Assembly removes the managed runtime dependency; it does not itself prove better
performance. Comparative startup, memory, and throughput remain unmeasured.

## Verification

Every push runs assembly self-tests, real executable JSON round trips, and native
capture/typing fixtures on disposable GitHub runners. Linux fixtures use Xvfb.
Tests use isolated history files and do not operate the developer's desktop.
The macOS integration fixture reports a skip if its runner lacks Accessibility
permission; check its log when evaluating a new runner environment.

`python tests/history-parity.py build/copy-pasta-asm.exe` runs the Windows file
tests without opening a window. On Unix, use `python3` and omit `.exe`.

## Source layout

* `src/core.inc`: x64 history, Unicode, strict JSON parsing and persistence.
* `src/abi.inc`: x64 calling conventions and Windows unwind metadata.
* `src/windows.s`, `src/windows-capture.inc`: Win32, UI Automation, native edit
  fallback, and SendInput.
* `src/linux.s`: GTK3/Pango, X11 PRIMARY selection, XGrabKey, and XTest.
* `src/macos.s`: Intel Cocoa, Accessibility, and Core Graphics.
* `src/arm64/macos.S`, `src/arm64/json.inc`: native Apple Silicon implementation
  using the same OS services, Foundation serialization, and strict validation.

Native libraries remain OS dependencies. Assembly is CPU- and ABI-specific, so
these are separate native builds. Windows/Linux ARM64 are not implemented.

## License and attribution

MIT, retaining the original project's license. App icon: [Spaghetti icon by
Freepik](https://www.flaticon.com/free-icon/spaghetti_4465494) from Flaticon,
used with attribution.
