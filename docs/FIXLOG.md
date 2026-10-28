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

## 28/10/2026: beachballs when opening and typing in Notes
- Symptom: "Opal (not responding)" while opening Notes and typing in them, worst in a large Vault and in Debug builds.
- Cause: per-keystroke work on the main actor. The `[[` suggestion matcher ran over every Note, and the Quick Switcher recomputed `results` on every read. Notes under 64 KB were analysed synchronously (45 ms in Debug at 60 KB). The frontmatter was parsed in view bodies. Every keystroke invalidated the toolbar and the inspector.
- Fix: analysis, matching and suggestions are `@concurrent` with stored results; fewer views observe the draft. Typing in a 5,000-Note Vault went from 31–42 ms to 1.6 ms per keystroke (see the 28/10/2026 M4 review addendum).
- Rule: nothing that grows with the Note or the Vault runs on the main actor per keystroke. Compute it off the main actor into stored state, and let only the view that shows a value observe it.

## 28/10/2026: a test script copied files into the real Vault
- Symptom: `Big.md` and `Mid.md` (test files) appeared in the user's real Obsidian Vault.
- Cause: the acceptance script took its source Vault from `${VAULT:-fixture}`. The user's shell exports `VAULT` pointing at their real Vault, so the "copy" was a symlink to it. Nothing was typed into a real Note (the probe found no Note to type into), and Opal never writes `.obsidian`.
- Fix: the two files were moved to the Trash, identical to the test copies. The scripts now use `OPAL_TEST_VAULT`, refuse any source outside `/private/tmp` or the repo fixtures, copy with `cp -RL`, stop if the copy is a symlink, and kill only test apps by full path.
- Rule: test scripts never read generic environment variables for paths. Check the resolved source against an allow-list before copying.
