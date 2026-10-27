# Architecture review — 27/10/2026, end of Milestone 2

Survey: `CLAUDE.md`, `ARCHITECTURE.md`, ADRs 0001–0003, `docs/FIXLOG.md`, git history (one day old, so churn says little), file sizes (largest: `MarkdownNoteParser.swift` 355 lines; no file over 600), and a timing probe of the parser on a 0.9 MB Note.

Timing probe (0.9 MB Note, 21,600 Links, 10,000-path Vault):

| Build | `MarkdownNoteParser.parse` | `LinkMap.highlights` |
| --- | --- | --- |
| Release | 138 ms | 35 ms |
| Debug | 244 ms | 77 ms |

## The open Note is parsed on the main actor on every key press  [Strong]

Files: `App/Opal/Presentation/Note/NoteScreen.swift`, `App/Opal/Presentation/Inspector/InspectorView.swift`, `Modules/OpalKit/Sources/OpalCore/Services/LinkService.swift`
Signal: slow work on the main thread; the design brief requires Notes of 1 MB to feel instant (M3-05).
Problem: each edit re-renders `NoteScreen`, which calls `links.parse(note.text)` for Link colours. With the Outgoing or Outline tab open, `InspectorView` parses the same text again. ⌘-click parses a third time. A 1 MB Note costs ~0.3 s of main-thread work per key press in a release build.
Proposal: `LinkService` owns one derived value for the open Note, kept up to date by `NoteService`:

```swift
public struct OpenNoteLinks: Sendable, Equatable {
    public let path: NotePath
    public let textLength: Int
    public let parsed: ParsedNote
    public let highlights: [LinkHighlight]
}

// LinkService
public private(set) var openNote: OpenNoteLinks?
public func openNoteChanged(_ path: NotePath?, text: String)   // small Notes now, large Notes debounced off the main actor
```

Views read `links.openNote`; nobody calls `parse` from Presentation. A Link map rebuild recomputes `highlights` for the open Note.
Benefits: one parse per edit instead of three; Notes over 64 KB are parsed off the main actor after typing pauses. Presentation loses its knowledge of parsing (locality). Outline, Outgoing and colours always agree.
Proof of same behavior: all 132 tests; new `LinkService` tests for small and large Notes and for a map rebuild; the timing probe repeated to show zero parse work on the main actor for a large Note.
Plan: 1) add `OpenNoteLinks` and `LinkService.openNoteChanged` with tests; 2) `NoteService` calls it on open, edit, reload and conflict resolution; 3) move `NoteScreen` and `InspectorView` to `links.openNote`, delete `LinkService.parse`.

## The Link map is synced by a view task  [Worth exploring]

Files: `App/Opal/Presentation/Vault/VaultScreen.swift` (`.task(id: vaultService.entries) { await links.sync() }`), `App/Opal/App/AppGraph.swift` (`onExternalChange` wiring)
Signal: before a big feature. The M3 Index must follow the same Vault changes.
Problem: whether the Link map is current depends on `VaultScreen` being on screen. M3 adds a second follower (the Index), so the wiring would be copied.
Proposal: `VaultService` publishes one `entriesChanged` hook (like `onExternalChange`), and the composition root subscribes `LinkService` and later the Index. Better still, in M3 the Index becomes the source of parsed Notes and `LinkService` reads it.
Decide when M3-01 is designed; doing it now would be redone then.

## Link suggestions live in `QuickSwitcherService`  [Speculative]

Files: `Modules/OpalKit/Sources/OpalCore/Services/QuickSwitcherService.swift`
Problem: the name no longer says what the service does. It shares the candidate list, which is why it is there.
Proposal: rename to `NoteFinderService` or split out `LinkSuggestionService` if a third use of the candidates appears (M3 Search may be one).

## Launch arguments thread through `AppGraph` one by one  [Speculative]

Files: `App/Opal/App/AppGraph.swift`, `AppDependencies.swift`, `LaunchArguments.swift`, `OpalApp.swift`
Problem: each acceptance argument (`-OpalOpenNote`, `-OpalQuickOpen`, `-OpalTypeText`, `-OpalAppearance`) adds a field in four files.
Proposal: pass one `LaunchOptions` value. Small gain; do it when the next argument is added.

## Top recommendation

The first card: parse the open Note once, in `LinkService`, off the main actor for large Notes.

Done on 27/10/2026 in three commits (Refactor 1/3 … 3/3). 137 tests pass; Link colours and the Outline look the same in the running app. A large Note now costs no parse on the main actor per key press.

## Considered, not recommended

- Splitting `MarkdownNoteParser` (355 lines): one cohesive parser with private helpers; it passes the deletion test.
- A protocol for `LinkService`: no second adapter is needed; tests use the real service on a fixture Vault.
- Moving `NavigationService.isInspectorShown` / `isQuickSwitcherShown` into Presentation: the menu commands and the toolbar both need them, and they are not persisted.
