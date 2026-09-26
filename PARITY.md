# Parity acceptance record

Reference: RejectKid/copy-pasta commit bf070ef.

This file records implementation and verification separately. An assembled
object file or passing core test does not prove platform integration parity.

| Capability | Windows x64 | Linux x64 | macOS |
| --- | --- | --- | --- |
| Native two-pane UI, Remove/Clear, selection preview | Implemented; visually inspected | Implemented; integration test pending | Pending |
| Resizable window and draggable pane divider | Resize implemented; divider pending | GTK paned widget implemented | Pending |
| 50-item history and duplicate promotion | Core self-test passed | Shared core; CI pending | Pending |
| JSON text/style/time persistence | Core round-trip test passed | Shared core; CI pending | Pending |
| Focused selection and parent/point fallback | Native UIA implementation; end-to-end pending | PRIMARY selection implementation; end-to-end pending | Pending |
| Native edit-control fallback | Implemented; end-to-end pending | Not in reference | Not in reference |
| Style capture and preview | Implemented; fixture preview inspected | No style capture in reference; imported-style preview pending | No style capture in reference |
| Global capture/type/stop hotkeys | Implemented; end-to-end pending | Implemented; end-to-end pending | Pending |
| Unicode typing, newline behavior, cancellation | Implemented; end-to-end pending | Original ASCII limitation; end-to-end pending | Pending |
| Native Apple Silicon executable | N/A | N/A | Pending |
| Icon, appearance details, localized metadata | Pending | Pending | Pending |
| Malformed JSON and allocation-failure hardening | In progress | Shared core | Pending |

Desktop input testing is currently paused while the owner uses the computer.
Tests use their own history path. No performance advantage has been claimed.
