# Copy Pasta ASM

Handwritten assembly port of [Copy Pasta](https://github.com/RejectKid/copy-pasta),
starting from `bf070ef`. This is an **in-progress parity implementation**, not yet
a verified 1:1 replacement. See [PARITY.md](PARITY.md) for the acceptance checklist.

The application code is assembly. OS libraries provide windows, accessibility,
text rendering, file I/O, memory allocation, and input. There is no .NET runtime,
JIT, Avalonia, C/C++/Objective-C application source, or compiler-generated assembly.
PowerShell, shell, and Python are used only for building and testing.

## Build

Windows x64: install Visual Studio C++ Build Tools with the Windows SDK, then run:

```powershell
./scripts/build-windows.ps1 -Test -Run
```

The script obtains NASM 3.02 when it is not installed. Output:
`build/copy-pasta-asm.exe`. Source files use NASM syntax with `.s` and `.inc`
extensions.

Linux x64 (X11): install NASM, a linker/compiler driver, GTK3, X11, and XTest
development packages, then run:

```sh
bash scripts/build-linux.sh --test
./build/copy-pasta-asm
```

## Behavior

* Ctrl+Alt+C captures the selection without the clipboard.
* Ctrl+Alt+V types the selected history entry, one character at a time.
* Ctrl+Alt+X cancels typing.
* History holds at most 50 entries and promotes duplicate text/style pairs.
* Windows captures style metadata through native UI Automation.
* History is JSON in the user's application data/configuration directory under
  `CopyPastaAsm`. `COPY_PASTA_HISTORY` overrides the file for isolated tests.

The original app's history is not modified. The same Text, CapturedAt, and Style
JSON fields are used. Linux has the original X11/common-ASCII output limitation.
Wayland support is outside the original app's supported capabilities.

Assembly removes the managed runtime dependency; it does not by itself prove
better performance. Size, startup, memory, and behavior need measured comparisons.
