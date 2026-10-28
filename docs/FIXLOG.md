# Fix log

Bugs found while building, with the rule each one taught.

## 27/10/2026 — Heading Link opened the Note but did not reveal the line
- Symptom: following a Backlink or Heading Link opened the right Note with the cursor at the end.
- Cause: opening a Note changes the tree selection, and the selection change called `NavigationService.open` again with no line, which cleared the reveal request.
- Fix: clear the reveal only when a different Note opens.
- Rule: an echo of a state change must be a no-op; never reset state on a call that changes nothing.

## 27/10/2026 — FSEvents changes never matched the Vault
- Symptom: files added by other apps did not appear; the watcher test timed out.
- Cause: FSEvents reports `/private/var/…`; `URL.resolvingSymlinksInPath()` strips `/private`, so no prefix matched.
- Fix: compare against `realpath()` as well as the standardized path.
- Rule: use `realpath()` to get the true path of a folder; never `resolvingSymlinksInPath()`.

## 27/10/2026 — `[[` suggestions inserted a Link while typing
- Symptom: typing `[[dir` produced `[[Soil|Dirt]]` with no list shown.
- Cause: `NSTextView.complete(_:)` inserts the only completion at once.
- Fix: Opal's own suggestion panel, driven from `doCommand(by:)`.
- Rule: never use `NSTextView` completion for a list the user must confirm.

## 27/10/2026 — Quick Switcher ignored the open Note's Folder
- Symptom: with `newFileLocation: current`, ⌘O created Notes in the Vault root.
- Cause: `QuickSwitcherService` passed `openNote: nil` to the placement plan.
- Fix: pass `NavigationService.openNote`.
- Rule: every path that creates a Note uses `NewItemPlanUseCase` with the open Note.

## 27/10/2026 — First index of 10,000 Notes took 56 seconds
- Symptom: the M3-06 performance test indexed 10,000 Notes in 55.6 s (budget 20 s).
- Cause: each upsert ran `DELETE FROM notes_fts WHERE path = ?`; `path` was an UNINDEXED FTS5 column, so every delete scanned the whole table.
- Fix: the FTS row shares its `rowid` with `notes.id`; deletes and joins use the rowid. 5.6 s after the fix.
- Rule: never filter an FTS5 table by an UNINDEXED column; link it to its content table by rowid.

## 27/10/2026 — Listing file dates took 0.7 s for 10,000 Notes
- Symptom: reopening an unchanged 10,000-Note Vault took 1.08 s (budget 1 s).
- Cause: `FileManager.enumerator(atPath:)` with `fileAttributes` stats each file one by one.
- Fix: `enumerator(at:includingPropertiesForKeys:)` with the date, size and type keys (0.12 s); paths are made relative to both the standard and the `realpath` form of the root, since the URL walk reports `/private/var/…`.
- Rule: walk big folders with `enumerator(at:includingPropertiesForKeys:)`, and compare paths against `realpath` as well.

## 28/10/2026: styling a 1 MB Note took 1.3 s on the main actor
- Symptom: during M4-01, one restyle of a 1 MB Note (120,600 style runs) took 1.32 s on the main actor in a Release build.
- Cause: `MarkdownStyler` reset and set attributes over the whole text storage on every analysis.
- Fix: style only a window of 10,000 characters either side of what is on screen, snapped to paragraphs, and restyle as the user scrolls. That takes 7 ms. Runs come sorted from `LinkService`, so the window is found by binary search.
- Rule: never apply text attributes to the whole storage of a large Note. Style a window around the viewport and restyle on scroll.

## 28/10/2026: scrolling a 1 MB Note stuttered, with live Markdown on or off
- Symptom: scrolling `Large Note.md` (1 MB) stuttered in both directions. A scroll probe (Release, 120 pt steps) measured an average of 12 ms per step scrolling down and 21 ms scrolling up, with up to 75 ms per frame. 98 of 150 upward steps took over 16 ms.
- Cause: on every scroll, the Editor compared the new style window with the last one. Any movement meant "not contained", so it reset and restyled 20,000 characters each frame. That forced TextKit 2 to lay them out again. With live Markdown off, it still reset the base attributes.
- Fix: the coordinator keeps an `IndexSet` of what it has styled since the last analysis and styles only the part of the window not yet styled. Now: 3.2 ms average down and 2.5 ms up, at most 1 step over 16 ms. Toggling live Markdown blocks the main actor for at most about 50 ms.
- Rule: work done on scroll must be proportional to what newly came into view, never to the window size.
