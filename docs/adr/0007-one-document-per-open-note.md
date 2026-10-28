# 0007 — One document per open Note, shared by every pane

Date: 29/10/2026. Status: accepted.

## Context

M5-10 adds a second Editor pane. Until now `NoteService` held one Note: one draft, one disk text, one save queue. `LinkService` held one analysis (`openNote`). The story asks that the same Note in both panes shows one text, and that it is saved once.

There were two cheaper ways to do this, and both fail:

1. **A second `NoteService` for the second pane.** With the same Note in both panes there are two drafts and two writes. Each service would see the other's write as a change from outside and show a conflict.
2. **One `NoteService` that reopens the Note on every focus change.** Opening resets the draft and rebuilds the Editor. Clicking into the other pane would lose the click, the caret, the selection and undo. The pane that is not focused would also go stale when the file changes outside Opal.

## Decision

`NoteDocument` holds the state of one open Note: its draft, disk text, load state, saves and conflict. It has a fixed path. `NoteService` keeps a `NoteDocument` for each Note a pane shows, keyed by path, so two panes on one Note share one document. `NoteService.show(_:alsoShowing:)` takes the focused Note and the Notes the other panes show. It saves and drops the documents no pane shows any more, and creates the missing ones.

`NoteService`'s existing API keeps meaning "the focused pane's Note". The inspector, window title, save status, Templates, unlinked mentions and commands follow the focused pane without any change.

`LinkService` keeps one analysis per open document. `openNote` is the focused one.

`NavigationService` keeps the panes in `EditorPanes`, a value type with one `TabList` per pane and the focused pane. `tabs` is the focused pane's list.

## Consequences

- Edits in one pane show in the other at once, and there is one save queue for each file.
- The pane that is not focused keeps its own caret, selection and undo. It reloads when its file changes outside Opal, the same way the focused pane does.
- At most two panes. Only the first pane's tabs are remembered between launches; the split itself is not restored.
- M5-12 (one service graph per window) builds on this: each window has its own `NoteService`, and with it its own documents.
