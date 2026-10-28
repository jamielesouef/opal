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
