# Architecture review — 29/10/2026, after M6 (Polish)

Survey: `CLAUDE.md`, `ARCHITECTURE.md`, `docs/architecture.md`, ADRs 0001–0008, `docs/FIXLOG.md`, the earlier reviews (latest: `architecture-review-2026-10-29-m5.md`), the M6 commits (`22e74f9..HEAD`, M6-01 to M6-09) and file sizes. No Swift file is over 600 lines. The largest are `MarkdownTextViewCoordinator.swift` (425 lines, the type itself about 412, past the 400-line type signal), `MarkdownNoteParser` (398), `VaultService` (380), `LinkService` (349) and `NavigationService` (339). The drifted-copies check found nothing. In M6 the most-touched files were `RootScreen`, `LaunchArguments`, `NavigationService`, `LaunchRequest`, `NoteScreen`, `MarkdownStyler`, `MarkdownBlockFragment` and the Editor coordinator.

Baseline: 325 tests in 60 suites pass (`cd Modules/OpalKit && xcrun swift test`), and the Debug build succeeds with 7 warnings (card 1).

Trigger: end of a milestone, plus a type over 400 lines.

Not re-proposed from the M5 review: the `ServiceGraph` (done), per-window graphs (done), `NoteService` forwarding, splitting `NavigationService` and `MarkdownNoteParser` (rejected; card 5 and the list below say why this time is or is not different). Card 3 of the M5 review, `MarkdownTextView`'s parameters, is still open and still Worth exploring: M6-08 added `onUnfold` and the fold input, so it now has 18 parameters; no M6 change broke on them.

## Presentation files do not import OpalCore, and the build warns  [Strong]

Files: `App/Opal/Presentation/Note/SaveStatusItem.swift`, `App/Opal/Presentation/Vault/IndexStatusItem.swift`, `App/Opal/Presentation/Vault/VaultSync.swift` (4 warnings), `App/Opal/App/OpalApp.swift` (line 22).
Signal: the same kind of warning showed up in three M6 build logs. CLAUDE.md and the engineer rules say zero warnings.
Problem: a clean build of the App target prints 7 warnings:
- 6 times `cannot use class 'NoteService' (IndexService, ServiceGraph, VaultService, SearchService) in a property declaration member of a type not marked '@_implementationOnly'; 'OpalCore' was not imported by this file`. The three views declare `@Environment(\.…)` properties of OpalCore types, but they get the types only through another file's import. Swift 6 member import visibility makes that an error in a later toolchain.
- 1 time `left side of nil coalescing operator '??' has non-optional type 'UUID'` in `OpalApp`: `WindowGroup(for: UUID.self)` hands the content closure a non-optional `UUID` because the group has a `defaultValue`, so `?? firstWindowID` can never run.
Proposal: add `import OpalCore` to the three views, and drop the dead `?? AppDependencies.shared.windows.firstWindowID` from `OpalApp`. No new types.
Benefits: the build is clean again, so a new warning is noticed. The three views keep working when the toolchain makes the missing import an error.
Proof of same behaviour: the Debug build succeeds with zero warnings (clean build of the App target after touching every App file), and all 325 tests pass. The `??` branch is unreachable, so no behaviour can change.
Plan: one commit.

## The Editor coordinator holds four jobs in one 412-line class  [Worth exploring]

Files: `App/Opal/Presentation/Note/MarkdownTextViewCoordinator.swift` (425 lines; 336 at the M5 review), `MarkdownTextView.swift` (208), `MarkdownBlockFragment.swift` (126), `MarkdownStyler.swift` (192).
Signal: a type over 400 lines. M6-07 and M6-08 added the checkbox drawing, the fold, `enforceFold`, `foldLabel`, `onUnfold` and the layout-manager delegate to the coordinator.
Problem: one `NSObject` is the text view delegate, the layout manager delegate, the content storage delegate, the owner of the `[[` suggestion panel and its task, the fold state, the style window, scroll, insertion and reveal. Its stored state mixes three unrelated groups (suggestion state: 5 properties; fold and marks: 4; request ids: 3). A change to suggestions rereads fold code to find what it shares.
Proposal: move the `[[` suggestion state and the three methods that drive it (`updateSuggestions`, `showSuggestions`, `acceptSuggestion`, about 110 lines) into a `LinkSuggestionController` that the coordinator owns and calls from `textDidChange` and `handleCommand`; leave fold, style and scroll in place.

```swift
@MainActor
final class LinkSuggestionController {
    var suggestions: (String) async -> [LinkSuggestion]
    var insertion: (LinkSuggestion) -> String
    func textChanged(in textView: NSTextView)
    func handle(_ selector: Selector, in textView: NSTextView) -> Bool
    func hide()
}
```

Benefits: locality for `[[` changes, and the coordinator falls to about 300 lines.
Why not now: the only proof is a snapshot, and the suggestion panel appears only while typing, which no snapshot reaches. A behaviour-preserving split of untested AppKit input handling is a bet; M6-08 shows how easily the fold and the caret break in the live Editor. It needs a recorded proof first (for example `-OpalTypeText "[[So"` plus a snapshot of the panel) before anyone moves code.
Plan, when picked: 1. record the `[[` snapshot proof; 2. add `LinkSuggestionController` and move the state; 3. delete the moved code from the coordinator.

## Launch flags are a script inside `RootScreen`'s `.task`  [Worth exploring]

Files: `App/Opal/Presentation/Root/RootScreen.swift`, `LaunchRequest.swift` (24 fields), `LaunchArguments.swift`.
Signal: test hooks in the app target, plus a flaky flag. `-OpalHideInspector` does not always hide the inspector.
Problem: about 60 lines of the `.task` apply the launch request in a fixed order across several `await`s and a one-second `Task.sleep`. `isInspectorShown = false` runs near the end of that sequence, after the window has already drawn the inspector, and `VaultScreen`'s `.inspector(isPresented:)` binding can run before or after it. That ordering is the likely cause of the flakiness, but it is a guess and has not been reproduced. Every new flag adds a field, a parse line and another `if` in the sequence, and none of it is testable outside a running app.
Proposal: a `LaunchRequest.apply(to: ServiceGraph)` in the App layer that runs the sequence, so `RootScreen` calls one function. Set the window flags (`hidesInspector`, `isReadingView`, `sidebarPane`) before the first await, so they are in place when the window draws.
Benefits: the order is written once; the flag order can be read in one place; a flag that is a plain window setting stops racing the view.
Why not now: the flaky flag needs a reproduction first. Moving the code without knowing the cause might leave the flake as it is. No M6 story is waiting on it.

## Property types: the panel infers per Note, the Index already knows the Vault-wide type  [Worth exploring]

Files: `NoteDocument.swift` (line 146), `NoteService.swift` (157), `VaultService.propertyTypes`, `IndexStoring.propertyTypes(declared:)`, `PropertyIndexUseCase.resolvedTypes`.
Signal: a gap M6-09 left on purpose (its Status line says so).
Problem: M6-09 made `GRDBIndexStore.propertyTypes(declared:)` give one type per name across the Vault, but nothing calls it outside tests. The Property panel still calls `PropertyTypeUseCase.type(of:declared: vault.propertyTypes)`, where `vault.propertyTypes` holds only what `.obsidian/types.json` declares. A name with a text value in one Note and a date in another shows two types.
Proposal: the Vault-wide result is published after the Index syncs and read by the panel. The natural seam is `ServiceGraph.syncFollowers()` (Index first, then ask the Index for `propertyTypes(declared:)` and hand the result to `VaultService`), so `VaultService.propertyTypes` becomes the effective types and `NoteService` and `NoteDocument` need no change.
Why not now: it needs a public read of the store from `IndexService`, and `IndexService.swift` holds the user's uncommitted edits. This milestone's rules say not to touch that file. It is a feature, not a refactor.

## `NavigationService` saves the window state at twelve call sites  [Speculative]

Files: `Modules/OpalKit/Sources/OpalCore/Services/NavigationService.swift` (339 lines; 305 at the M5 review).
Signal: M6-04 added `saveWindowState()` after every tab, pane, share and rename change (12 calls).
Problem: a new mutation that forgets the call silently loses the window state on relaunch. The M5 review kept `NavigationService` whole because everything in it is per window; M6-04 adds persistence, which is a second reason to change, but only 15 lines of it.
Proposal: save from a `didSet` on `panes` (the one stored value the state is derived from), and delete the 12 calls.
Why not now: it works, `restoresWindowState` and `WindowStateTests` cover the round trip, and `didSet` on an `@Observable` property fires for every mutation including ones that change nothing worth saving, so it would write to `UserDefaults` more often. Look again if a thirteenth call site appears.

## Considered, not recommended

- **Splitting `NavigationService` (339 lines) into window flags and tabs.** Same reason as the M5 review: everything is per window, and the persistence added in M6-04 is 15 lines.
- **`MarkdownBlockFragment` and `MarkdownStyler` (126 and 192 lines).** Both grew in M6 but each is still one cohesive job (drawing a block, writing attributes). The deletion test says keep them.
- **A protocol seam for the Editor coordinator.** One conformer, no test adapter.
- **`MarkdownNoteParser` (398 lines).** Still one cohesive parser, as before.
- **Making the build fail on warnings (`SWIFT_TREAT_WARNINGS_AS_ERRORS`).** Worth doing later, but it changes the project settings for every contributor, and the Xcode and package builds would both have to be clean first. Card 1 gets the build clean; the setting can follow.

## Top recommendation

Card 1. It is the only card whose proof is complete today, it is mechanical, and it clears the warnings that every M6 story had to explain. It is a small step, not a redesign. The Editor coordinator split (card 2) is the bigger gain, but it needs its `[[` proof recorded first, so it stays for the user to pick.
