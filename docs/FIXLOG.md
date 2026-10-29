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

## 28/10/2026: opening `CLAUDE.md` hung the app (5,092 unlinked mentions)
- Symptom: "Opal (not responding)" on a Note whose name is a common word. The inspector showed 5,092 unlinked mentions.
- Cause: the inspector passed the whole mentions array to SwiftUI views, which compared it with `==` on every update (`AttributeGraph` → `Array.==` → `UnlinkedMention.==` → `String` comparison). That is O(n) string work many times per frame on the main thread.
- Fix: the inspector shows 50 mentions at a time with **Show More**. Rows are identified by `UnlinkedMention.id` (source and offset) instead of hashing the whole value, and the header shows the total.
- Rule: never hand an unbounded array to a SwiftUI view. Page it, and give `ForEach` a cheap stable `id`.

## 28/10/2026: lines disappeared while editing; undo crashed; saves froze a large Vault
- Symptom: while editing `CLAUDE.md` in a real Vault (3,798 Notes), lines vanished until the user scrolled, one undo crashed in `objc_msgSend`, and typing felt laggy.
- Cause, lines: every new analysis reset and re-set the attributes of the whole style window (6,000 characters). TextKit 2 invalidated and re-laid out all of it on every keystroke, and some fragments were not redrawn until a scroll.
- Cause, freeze on save: each save came back as a change from outside (FSEvents), and `VaultService` rebuilt and re-sorted the whole Folder tree on the main actor even though no file was added or removed. That took 205 ms in Debug at 5,000 Notes.
- Cause, crash: not reproduced. The likely cause was that every Editor shared the window's undo manager, so undo could reach a text view that SwiftUI had already thrown away (each Note gets a new Editor).
- Fix: `MarkdownStyler` builds the wanted attributes off to the side and writes only the ranges that differ. Styling waits while the text storage is mid-edit. Each Editor has its own `UndoManager`, cleared when the Editor goes away. A refresh with an unchanged list of entries does nothing, and the tree is built off the main actor.
- Rule: never rewrite text attributes that have not changed. Never mutate the text storage during its own editing pass. Give each `NSTextView` its own undo manager when SwiftUI can recreate it.

## 28/10/2026: each save froze the app for over a second on a Note with thousands of mentions
- Symptom: the user's Instruments trace (`CLAUDE.md`, 22.9 s) spent 2.1 s of 2.8 s of main-thread time in `Array<UnlinkedMention>.==`, down in `_stringCompareSlow` and NFC normalisation.
- Cause: `@Observable` compares an `Equatable` property's old and new value before notifying observers. Every save reloaded about 5,000 mentions, and `MentionService.mentions.setter` compared both arrays string by string (1.4 s). SwiftUI then compared view inputs again. Separately, every save changed `index.revision`, which `VaultScreen` observed, so the sidebar List re-diffed the whole Folder tree.
- Fix: `MentionService` keeps the mentions out of observation and publishes a `mentionsRevision`. `UnlinkedMention` equality and hashing use the source, span and line, never the line's text. The index and Vault-change observers moved into `VaultSync`, and the index status and Folder tree into their own views, so a save no longer rebuilds `VaultScreen`.
- Rule: an observed property that holds a large collection is published through a revision counter, not compared value by value. Value types that reach SwiftUI compare by identity fields, not by long strings.

## 29/10/2026: split view crashed at the default window size
- Symptom: with two panes in a 1,100-point window, both on Notes with Properties, the app threw "needing another Update Constraints in Window pass" and quit. At 1,626 points it worked, so M5-10's snapshots (taken in a wider window) missed it. M5-12 caught it: new windows open at the default size.
- Cause: the panes sat in an `HStack` without flexible frames, so each pane's width followed its content's ideal width. The Properties form and the Editor's scroll view kept renegotiating the split.
- Fix: each pane gets `.frame(minWidth: 0, maxWidth: .infinity)`, so the panes share the width evenly whatever they hold.
- Rule: views placed side by side in an `HStack` get explicit flexible frames. Snapshot new layouts at the default window size, not only at a remembered one.


## 29/10/2026: the Folder tree dropped every Folder below a Folder that held a hidden file
- Symptom: in the user's Vault, `daily` showed only `2026`, and `2026` showed none of its month Folders or Notes, although `daily/2026/01-Jan` to `10-Oct` exist on disk. `daily` holds a `.gitkeep`.
- Cause: `FileSystemVaultStore.walk` called `enumerator.skipDescendants()` for every hidden item. For a file, that call is not a no-op: the enumerator drops the Folder it was about to enter. `.gitkeep` came before `2026`'s contents, so everything below `2026` was lost. Any Vault with `.DS_Store` or `.gitkeep` files could lose Folders this way. Separately, a Vault root that is a symbolic link listed nothing, because the enumerator does not enter a symbolic link given as its start.
- Fix: call `skipDescendants()` only when the skipped item is a directory. The walk starts from the resolved root; paths were already matched against both forms.
- Rule: call `skipDescendants()` only for a directory, and never rely on it for a file. Start a directory walk from the resolved path of its root.
