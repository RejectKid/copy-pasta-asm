# Parity acceptance record

Reference: RejectKid/copy-pasta commit `bf070ef`.

Application code is handwritten assembly with native platform libraries. Build
and fixture scripts use higher-level languages. Tests establish the behaviors
below, not exhaustive equivalence for every source application or malformed file.

## Implemented behavior

| Capability | Windows x64 | Linux x64/X11 | macOS Intel / Apple Silicon |
| --- | --- | --- | --- |
| Two panes, draggable divider, preview, Remove/Clear | Win32 | GTK3 | Cocoa |
| Capture/type/cancel hotkeys | RegisterHotKey | XGrabKey | CG event tap |
| Selection without clipboard | UI Automation and native edit fallback | PRIMARY selection | Accessibility selected text |
| Character-by-character output | SendInput Unicode | XTest common ASCII | Core Graphics Unicode |
| History cap and duplicate promotion | 50 entries, text plus style | Same | Same |
| Persistence | Atomic JSON replacement | Atomic JSON replacement | Atomic JSON replacement |
| Style capture | UI Automation metadata | Unavailable in reference | Unavailable in reference |
| Imported style preview | Native font/colors | Pango and GTK colors | NSFont and NSColor |
| App icon | Embedded ICO | Embedded PNG | ICNS bundle |

## Automated evidence

The first all-platform passing run after strict ARM64 JSON validation is
[36207965320](https://github.com/RejectKid/copy-pasta-asm/actions/runs/36207965320).
The preview scrolling regression run is
[36208023779](https://github.com/RejectKid/copy-pasta-asm/actions/runs/36208023779).
Timestamp preservation and field validation also passed all four platforms in
[36208155178](https://github.com/RejectKid/copy-pasta-asm/actions/runs/36208155178)
at `bb66d52`; neither macOS integration test was skipped. Later changes use the
same workflow; check the run matching the commit.

* Assembly self-tests: history insertion, duplicate promotion, cap, Unicode,
  persistence, and removal.
* Real executable file tests: UTF-8 and UTF-16 escapes, all six style fields,
  timezone offsets, fractional timestamp preservation and ordering, newest-50
  selection, malformed JSON, invalid field types, and unknown nested fields.
* Windows native fixture: capture, Unicode typing, duplicates, cancellation,
  removing an entry while typing its owned snapshot, and persisted clearing.
* Linux isolated X11 fixture: PRIMARY capture, duplicate promotion, global
  hotkeys, and actual ASCII output to a terminal target.
* Both macOS native fixtures: AX selection, hotkeys, duplicates, Unicode output,
  cancellation, UI startup, and screenshot artifacts.

## Differences and verification limits

* Native widgets replace Avalonia. Layout and controls are similar; font metrics,
  theme behavior, accessibility trees, and date formatting can differ by OS.
* History uses `CopyPastaAsm` rather than `CopyPasta`, keeping original data intact.
  File fields are compatible. `COPY_PASTA_HISTORY` can select a file.
* x64 newly captured dates currently have second precision. Imported timestamp
  strings retain their fractional precision and timezone offsets.
* Windows/Linux target x64; macOS has x64 and ARM64 builds. Other architectures
  are not implemented. Linux retains the original X11/common-ASCII limitation.
* Accessibility depends on the source application and OS permissions. Fixtures
  do not establish compatibility with every editor, browser, elevated window,
  game, remote desktop, or sandboxed application.
* Malformed input has targeted regression coverage. Allocation failure and every
  possible schema/date edge case are not exhaustively tested.
* No performance superiority is claimed. There is no managed runtime dependency,
  but comparative startup, memory, and throughput benchmarks remain unmeasured.

Local mouse, keyboard, clipboard, and GUI testing remain paused while the owner
uses the computer. New desktop integration tests run on disposable CI hosts.
