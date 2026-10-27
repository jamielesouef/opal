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
