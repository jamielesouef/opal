# Architecture review — 28/10/2026, end of Milestone 4

Survey: `ARCHITECTURE.md`, ADRs 0001–0006, `docs/FIXLOG.md` (two new Editor performance entries today), the earlier review the same day, file sizes (largest: `MarkdownNoteParser.swift` 398 lines, `NoteService.swift` 364, `LinkService.swift` 327; no file over 600, no type over 400), the drifted-copies check (none), and churn since M3 (`NoteScreen` 16 changes, `AppGraph` 14).

Baseline: 225 tests in 42 suites pass; Debug and Release build.

The code is in good shape. The `LaunchRequest` refactor from the morning review paid off: `-OpalReadingView` touched three files, as planned. No card is Strong, so in this unattended run nothing is refactored.

## The open Note's rendering pipeline lives inside LinkService  [Worth exploring]

Files: `Modules/OpalKit/Sources/OpalCore/Services/LinkService.swift` (327 lines, 20 functions)
Signal: one service picked up three jobs in M4. It still keeps the Link map, and now also the open Note's analysis (parse, Link colours, style runs), Reading view blocks, and Embed sections.
Problem: the pipeline "text → `ParsedNote` → style runs → reading blocks" is written three times as private statics (`analyse`, `readingConcurrently`, `embedConcurrently`), each with its own sorting and Link-colour merge. Tests can only reach it through a `ServiceHarness` with a fixture Vault.
Proposal: one pure type in Data that takes plain values; `LinkService` keeps the map and the off-main-actor scheduling.

```swift
public enum NoteRenderer {
    public static func analysis(of text: String, at path: NotePath, map: LinkMap) -> OpenNoteLinks
    public static func readingBlocks(_ analysis: OpenNoteLinks, text: String) -> [ReadingBlock]
    public static func section(of text: String, at path: NotePath, subpath: LinkSubpath?, map: LinkMap) -> [ReadingBlock]?
}
```

Benefits: a single place that merges Link colours with Markdown styles. Pipeline tests become text-in, values-out (CLAUDE.md's rule for parsers), and `LinkService` shrinks by about 60 lines.
Proof of same behavior: the 225 tests; `EmbedTests` and `OpenNoteLinksTests` unchanged; the M4 snapshots.
Plan: 1) add `NoteRenderer` with tests; 2) move the three statics over; 3) delete them.

## Editor speed has regressed twice and nothing checks it  [Worth exploring]

Files: `App/Opal/Presentation/Note/MarkdownStyler.swift`, `MarkdownTextViewCoordinator.swift`; `docs/FIXLOG.md` (two entries on 28/10/2026)
Signal: the same kind of bug twice (main-thread work in the Editor for a large Note). Only the user's hands caught the second one.
Problem: the Editor's budgets (scroll step under 16 ms, toggle under 100 ms on a 1 MB Note) live in FIXLOG prose. OpalKit tests cannot host an `NSTextView`, and there is no app test target.
Proposal: keep the scroll probe used for the fix as a Debug-only `-OpalPerfProbe <file>`. It scrolls the open Note down and up, toggles live Markdown, and writes p95 and worst-frame times. A short script runs it on a generated 1 MB Note in a Release build and fails over budget.
Benefits: the next Editor change is measured before the user feels it.
Proof of same behavior: Debug only; Release unchanged.
Plan: 1) add the probe and script; 2) record the budgets in `docs/templates` or the README of `docs/screens`.

## The frontmatter shows twice  [Speculative]

Files: `NoteScreen.swift`, `MarkdownStyler.swift`
Problem: the Properties form and the faint YAML in the Editor show the same lines (M4-03 Later). Hiding lines in TextKit 2 means a layout fragment with zero height, or folding. That is a design decision for when it is built, not a refactor.

## Considered, not recommended

- Splitting `NoteService` (364 lines): the new Property, checkbox and Attachment methods are a few lines each over `edit(_:)`, and they share the draft. It passes the deletion test as one module.
- Splitting `MarkdownNoteParser` (398 lines): unchanged in M4 apart from wider access to its helpers.
- A protocol for `NoteRenderer`: a single pure implementation needs no seam.

## Top recommendation

None is Strong. If you pick one, take the Editor speed probe first, because it guards the area that broke twice today. Then `NoteRenderer`.

## Addendum: main-thread audit (requested by the user after beachballs)  [Strong, done]

Signal: "Opal (not responding)" while opening and typing in Notes. Time Profiler traces of a Debug build on a generated Vault of 5,000 Notes (`/tmp`, never a real Vault) showed where the main actor spent its time per keystroke:

| Work on the main actor | Share of main-thread time while typing |
| --- | --- |
| `[[` suggestions: `QuickSwitcherMatchUseCase.matches` over every Note, plus rebuilding the candidate list on each call | 35% |
| Window layout from views invalidated by every keystroke (toolbar save status, inspector, Properties inset) | 21% |
| Restyling the Editor window after each analysis | 3% |
| Parse, style runs and frontmatter for Notes under 64 KB (synchronous before) | measured separately: 45 ms per keystroke in Debug at 60 KB |

Changes, one theme, in one commit:
- `LinkService.openNoteChanged` analyses every Note off the main actor (`@concurrent`): no pause for small Notes, 200 ms for Notes over 64 KB. The analysis also carries the frontmatter and the Link-only runs, so the Properties form and "live Markdown off" no longer parse or filter in a view body. The Editor applies runs only when their text length matches the text view.
- Property edits re-read the frontmatter from the current draft when the user acts, so a stale analysis can never edit the wrong lines.
- `QuickSwitcherService.results` is stored and computed off the main actor; `linkSuggestions(for:)` is `async`. Candidates are cached by `VaultService.entriesRevision` and `LinkService.mapRevision`.
- Fewer views observe the draft: the toolbar save status reads `NoteService.isUnsaved` (set when the draft or disk text changes) in its own `SaveStatusItem`; the inspector uses `NoteService.isReady` and reads the parsed Note only in the panes that need it; Reading view keys on `NoteService.revision` instead of hashing the text.
- The Editor compares new text against the text it last reported rather than bridging `NSTextView.string` on every update, and restyles 3,000 characters either side of the screen instead of 10,000.
- Image Embeds and dropped image files are read off the main actor.

Proof (Debug build; probe: open a Note, then type 52 characters at 60 ms intervals):

| Case | Before | After |
| --- | --- | --- |
| 33 KB Note, Garden Vault: average per keystroke | 15 ms (11 main-thread gaps over 50 ms) | 3 ms (1 gap) |
| 5,000-Note Vault: average per keystroke | 31–42 ms (up to 29 gaps over 50 ms, worst 238 ms) | 1.6 ms (2 gaps, worst 59 ms) |
| 1 MB Note: average per keystroke | 3 ms | 3 ms |

225 tests pass; tests that read the open Note's analysis now await `waitForOpenNote()`.
