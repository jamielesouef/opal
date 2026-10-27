# Architecture review — 28/10/2026, end of Milestone 3

Survey: `CLAUDE.md`, `ARCHITECTURE.md`, `docs/architecture.md`, ADRs 0001–0004, `docs/FIXLOG.md`, the 27/10/2026 review, git history since then (M3-01 … M3-06), file sizes (largest: `MarkdownNoteParser.swift` 398 lines; no file over 600, no type over 400), the drifted-copies check (no `private struct` defined twice), and a read of the Editor ahead of Milestone 4.

Baseline: 178 tests in 32 suites pass; the `Opal` scheme builds in Debug.

The code is in good shape. No file or type is near a size trigger, and the Strong card from the last review (parse the open Note once) is done. One card is Strong because its own trigger, set in the last review, has fired.

## Launch arguments thread through the composition root one by one  [Strong]

Files: `App/Opal/App/LaunchArguments.swift`, `AppDependencies.swift`, `AppGraph.swift`, `OpalApp.swift`, `App/Opal/Presentation/Root/RootScreen.swift`, `App/Opal/Presentation/Environment/EnvironmentValues+Services.swift`
Signal: one feature touched more than 6 files. The 27/10/2026 review said "do it when the next argument is added"; three have been added since (`-OpalIndexFolder`, `-OpalSearch`, `-OpalSidebarPane`). Commit `25bff02` added two arguments and touched five App and Presentation files to do it.
Problem: each acceptance argument is a field in `LaunchArguments`, a parameter and a field in `AppGraph`, an argument in `AppDependencies.makeGraph()`, an argument to `RootScreen` in `OpalApp`, and a property on `RootScreen` (or an `@Entry` for `-OpalTypeText`). Milestone 4 will add more (Reading view, Properties, Embeds shots).
Proposal: one plain Presentation value, built once by `LaunchArguments`, carried through `AppGraph` and the environment unchanged.

```swift
struct LaunchRequest {
    var note: NotePath?
    var quickOpen: String?
    var search: String?
    var sidebarPane: SidebarPane?
    var typeText: String?
}

// LaunchArguments
var request: LaunchRequest       // typeText is nil outside Debug builds
var appearanceName: NSAppearance.Name?

// EnvironmentValues
@Entry var launchRequest = LaunchRequest()
```

`RootScreen` and `NoteScreen` read `launchRequest` from the environment. `LaunchArguments` stays the only reader of the arguments, and Presentation still sees only a plain value (`docs/architecture.md`, App).
Benefits: a new argument touches `LaunchArguments`, `LaunchRequest` and the one view that acts on it. `AppGraph`, `AppDependencies` and `OpalApp` stop changing for acceptance work.
Proof of same behavior: the 178 tests; a Debug build; the same flags parsed to the same values (read side by side in the diff, since this Mac's terminal has no screen recording or accessibility permission for a launch shot).
Plan: one commit (one refactor across six small files).

## Editor colours are Link-only  [Worth exploring]

Files: `App/Opal/Presentation/Note/MarkdownTextViewCoordinator.swift` (`apply(_ highlights:)`), `Modules/OpalKit/Sources/OpalCore/Domain/Link/LinkHighlight.swift`, `OpenNoteLinks.swift`, `LinkMap.highlights(in:from:)`
Signal: before a big feature (M4-01 Live Markdown).
Problem: the open Note's styling is `[LinkHighlight]`, and the coordinator resets the foreground colour of the whole text storage and then colours Links. Live Markdown needs headings, emphasis, Tags, code, quotes and callouts, and fonts as well as colours.
Proposal: a style run in Domain (`TextStyleRun { span; kind }`, with an exhaustive `TextStyleKind` that starts with `.link(isResolved:)`), computed with the Links off the main actor in `LinkService.openNote`, and one place in the Editor that maps a kind to attributes and resets them. Styles stay text storage attributes: TextKit 2 rendering attributes cannot change fonts, so headings could not grow ([ADR 0002](adr/0002-textkit-2-editor.md) still holds — the stored text is unchanged either way).
Why not now: with one kind it is a rename. M4-01 designs the kinds; do it as that story's first commit.

## The Index and the Link map follow the Vault from a view  [Worth exploring]

Files: `App/Opal/Presentation/Vault/VaultScreen.swift` (`.task(id: vaultService.entries) { await index.sync(); await links.sync() }`), `App/Opal/App/AppGraph.swift` and `Modules/OpalKit/Tests/OpalCoreTests/Services/ServiceHarness.swift` (the same `onExternalChange` closure, copied)
Signal: the last review predicted a second follower; M3 added it (`IndexService`).
Problem: whether the Index is current depends on `VaultScreen` being on screen, and the order (Index, then Link map, then the open Note) is written twice, once in the app and once in the tests, so the tests do not exercise the app's wiring.
Proposal: an OpalCore type that builds the services and wires every follower once, used by both `AppGraph` and `ServiceHarness`.
Why not now: it works with one window. M5-08 (more than one window) decides how graphs and windows relate; design it there.

## Considered, not recommended

- `LinkService.link(at:in:)` parses on the main actor when the open Note's length does not match: only inside the short window after typing and before the analysis lands, and only on ⌘-click. Revisit if ⌘-click on a 1 MB Note feels slow.
- Splitting `MarkdownNoteParser` (398 lines): still one cohesive parser. Milestone 4 will add inline styles; split by line kind and inline kind if it passes 600 lines.
- `MockVaultFileStore` (App, previews) and `StubVaultFileStore` (tests) are two fakes of one protocol, but for different hosts; neither has drifted from `VaultFileStoring`.
- Renaming `QuickSwitcherService`: Search did not reuse its candidates, so the third use never came.

## Top recommendation

The first card: one `LaunchRequest` value. The other two are left for M4-01 and M5-08.

Done on 28/10/2026 in one commit. Debug and Release builds succeed (Release checks that `-OpalTypeText` is ignored); OpalKit is unchanged and its 178 tests pass. A launch run with the flags could not be recorded here: this terminal has no screen recording or accessibility permission.
