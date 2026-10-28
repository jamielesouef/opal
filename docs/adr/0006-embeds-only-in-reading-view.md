# 0006 — Embeds show only in Reading view

Date: 28/10/2026. Status: accepted (chosen by the user).

## Context

M4-04 asked for Embeds (`![[Note]]`, `![[Note#Heading]]`, images, PDFs) to show inline in the Editor and in Reading view. In the Editor, that means views or drawn images below a line without changing the text: attachment cells or TextKit 2 layout fragments with extra height. That costs a lot of code and adds risk to the 1 MB scrolling budget (see `docs/FIXLOG.md`, 28/10/2026). The options put to the user were images only in the Editor, full Embeds in the Editor, or Reading view only.

## Decision

Embeds render only in Reading view ([ADR 0005](0005-reading-view-in-swiftui.md)). The Editor shows the Embed as styled text: `![[` and `]]` are marks and the target is coloured like a Link.

## Consequences

- The Editor stays plain text with styling, with no views inside it, so it remains fast for large Notes.
- To see an image or an embedded Note, the user switches to Reading view (⌘E).
- M4-06 (paste and drop images) inserts the Embed text in the Editor. The image appears in Reading view.
