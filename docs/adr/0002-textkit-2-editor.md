# 0002 — The Editor is an AppKit `NSTextView` on TextKit 2

Date: 27/10/2026. Status: accepted.

## Context

`ARCHITECTURE.md` left open whether the Editor is SwiftUI `TextEditor` or an AppKit `NSTextView` on TextKit 2. Milestone 1 needs plain editing that never changes the user's text. Milestone 4 needs live Markdown styling, Embeds and large Notes (1 MB).

## Decision

The Editor wraps `NSTextView` (TextKit 2) in an `NSViewRepresentable`. In Milestone 1 it is plain text with smart quotes, smart dashes, text replacement and automatic spelling correction off, so typing never rewrites what the user wrote.

## Consequences

- Live styling in Milestone 4 can use TextKit 2 rendering attributes without changing the stored text.
- The representable is the one AppKit view in Presentation, and it takes plain values and closures like any leaf view.
- `TextEditor` would have been less code now, but has no hooks for per-range styling or attachment views.
