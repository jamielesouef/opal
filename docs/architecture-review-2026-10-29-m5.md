# Architecture review — 29/10/2026, before M5-12

Survey: `ARCHITECTURE.md`, ADRs 0001–0007, `docs/FIXLOG.md`, the 28/10 reviews, file sizes, and churn over 30 days. The largest files are `MarkdownNoteParser.swift` (398 lines), `VaultService.swift` (366), `LinkService.swift` (349), `MarkdownTextViewCoordinator.swift` (336) and `NoteDocument.swift` (324). No file is over 600 lines and no type is over 400. The drifted-copies check found nothing. The files that changed most are `NoteScreen` (23 changes), `VaultScreen` (19), `LaunchArguments` (18) and `AppGraph` (18).

Baseline: 274 tests in 53 suites pass, and the Debug build succeeds.

Trigger: before a big feature. M5-12 gives each window its own Vault, Index, Link map, tabs and history. Ask: "What change to the code would make this feature easy?"

## The service graph is built twice and wired in a view  [Strong]

Files: `App/Opal/App/AppGraph.swift`, `Modules/OpalKit/Tests/OpalCoreTests/Services/ServiceHarness.swift`, `App/Opal/Presentation/Root/VaultSync.swift`, plus 5 test files that build `RenameService`, `TemplateService`, `DailyNoteService` or `SettingsService` by hand.
Signal: before a big feature. The 28/10 card "the Index and the Link map follow the Vault from a view" was left for exactly this feature.
Problem:
- The app's graph lives in the App target, where tests can't reach it.
- `ServiceHarness` copies the construction order and the `onExternalChange` closure (Index, then Link map, then open Notes), so the tests don't exercise the app's wiring.
- The harness also leaves out four services, so tests build them by hand.
- Keeping the Index and Link map current depends on `VaultSync`, a zero-size view in `VaultScreen`.

M5-12 needs "one graph per window". Today that means a third copy, built in the App target.
Proposal: one OpalCore type builds every service and wires every follower. The app and the tests both use it, and M5-12 makes one per window.

```swift
@MainActor
public final class ServiceGraph {
    public let vault: VaultService, notes: NoteService, links: LinkService, index: IndexService
    public let navigation: NavigationService, switcher: QuickSwitcherService, search: SearchService
    public let mentions: MentionService, dailyNotes: DailyNoteService, templates: TemplateService
    public let renames: RenameService, settings: SettingsService

    public init(vault: VaultService, makeIndexStore: @escaping @Sendable (URL) throws(IndexError) -> any IndexStoring,
                recents: any RecentNotesStoring, settingsStore: any SettingsStoring,
                clock: any Clocking, saveDelay: Duration = .milliseconds(800))

    public func syncFollowers() async   // Index, then Link map; what VaultSync does today
}
```

Benefits:
- Locality: the construction order and the follower order are written once.
- Leverage: M5-12 becomes "a `ServiceGraph` per window" plus Presentation work.
- `ServiceHarness` shrinks to the stubs plus `ServiceGraph`, and the five tests that hand-build services use the graph's services instead.

Proof of same behaviour:
- All 274 tests pass unchanged at each step, apart from tests that switch from hand-built services to the graph's.
- The Debug build succeeds.
- Snapshots `opal-m5-10-split.png` and `opal-m5-11-settings-files.png` look the same.

Plan:
1. Add `ServiceGraph` to OpalCore and make `ServiceHarness` use it. Tests only.
2. Make `AppGraph` hold a `ServiceGraph` and keep only the app-level values (launch request, appearance, snapshot URL, defaults). Point `EnvironmentValues+Services`, `OpalApp` and `OpalAppDelegate` at it.
3. `VaultSync` calls `graph.syncFollowers()`. Whether a service should start the sync itself is decided in M5-12's ADR.

## Every view falls back to the shared graph  [Worth exploring]

Files: `App/Opal/Presentation/Environment/EnvironmentValues+Services.swift` (12 `@Entry` defaults read `AppDependencies.shared`), `OpalApp.swift` (`OpalCommands` built from the shared services), `OpalAppDelegate.swift` (flushes the shared `NoteService`).
Signal: a dependency that M5-12 needs to replace per window.
Problem: with two windows, a view that forgets an `.environment` line silently uses the first window's services. The menus act on the first window, not the key window.
Proposal: inject one `@Entry var graph: ServiceGraph?` per window. Commands read the key window's graph through `@FocusedValue`. On quit, the delegate flushes every graph.
Why not now: this is M5-12 itself, and its shape depends on that ADR. Do it inside M5-12, after card 1.

## The Editor takes 17 loose parameters  [Worth exploring]

Files: `App/Opal/Presentation/Note/MarkdownTextView.swift` (197 lines), `NoteScreen.swift` (240).
Signal: in M5-10 the build broke because a new closure parameter sat before the trailing closures (FIXLOG-worthy, but caught by the compiler).
Problem: every new Editor capability adds a parameter and threads it through `makeNSView`, `updateNSView` and the coordinator. The trailing-closure order is fragile.
Proposal: group the values into `EditorInput` (text, styles, reveal, insertion, style, focus) and the closures into `EditorActions`. Keep `MarkdownTextView(input:actions:)`.
Why not now: two more parameters wouldn't hurt, and no story in line adds Editor parameters.

## Considered, not recommended

- **`NoteService` forwarding to the focused `NoteDocument`.** It fails the deletion test in part, but it is the deliberate seam from ADR 0007: the inspector, Templates, mentions and about 60 test call sites mean "the focused Note" through it.
- **Splitting `NavigationService` (305 lines).** It mixes tabs and panes with window flags (`isQuickSwitcherShown`, `isInspectorShown`, `sidebarPane`, `isReadingView`). Everything in it is per window, which is exactly what M5-12 wants, so it stays whole.
- **Splitting `MarkdownNoteParser` (398 lines).** It is still one cohesive parser.

## Top recommendation

Card 1, `ServiceGraph` in OpalCore, done in three commits. It is the change that makes M5-12 easy, and it closes the open 28/10 card.

Done on 29/10/2026 in three commits. After each step all 274 tests pass and the Debug build succeeds. The split snapshot shows the same content. A launch with an empty Index folder built the Index, and the Backlinks and unlinked mentions came from the synced Link map. The tests that build `DailyNoteService` (with its own clock) and `SettingsService` (with its own store) still build them by hand on purpose.

## Addendum: end of Milestone 5 (after M5-12)

- Card 2, "Every view falls back to the shared graph", was done in M5-12. Each window injects its own graph, and the menus read the key window's graph through a focused scene value. The environment defaults now fall back to an empty placeholder graph, never to another window's graph. Outside previews, `AppDependencies.shared` gives only app-wide values: the window registry, settings, launch values and defaults.
- Card 3, `MarkdownTextView`'s parameters, stays Worth exploring.
- New finding: a snapshot run's `NSApp.terminate` waits in `_shouldTerminate`, because `applicationShouldTerminate` replies from a main-actor `Task` while the snapshot's own main-actor task is still on the stack. Snapshots are written before this, so the acceptance script kills the app after it writes the PNG. A real ⌘Q does not run inside a main-actor task, so it should not be affected, but that has not been checked by hand. Speculative: reply synchronously when nothing needs saving.
- Baseline at the end of M5: 280 tests in 54 suites pass, and the Debug build succeeds.

