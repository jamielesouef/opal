# Architecture — Model-View (MV) for Apple platforms

A layered Model-View architecture for SwiftUI apps on iOS, iPadOS, macOS, tvOS,
watchOS and visionOS. There are no view models. State lives in `@Observable`
services, decisions live in pure use cases, and views read the state and apply
the decisions.

This document is the contract. A project adopting it should keep a short
`ARCHITECTURE.md` of its own that names its actual services, protocols and
deliberate constraints, and links back here for the rules.

## The shape

```
Domain  ←  Data  ←  Services  ←  Presentation
                         ↑
                        App  (composition root)
```

Dependencies point left. Domain knows about nothing else and imports no SwiftUI.
Presentation knows about Services and Domain, never Data. `App` is the only layer
that knows about everything, and the only place that reads an ambient global.

| Folder | Holds | Rule of thumb |
| --- | --- | --- |
| `Domain/` | Value types and pure use cases | No I/O, no SwiftUI, no `Date()` |
| `Data/` | Protocols and their real implementations | `Sendable`, never `@MainActor` |
| `Services/` | `@MainActor @Observable` state owners | One derived `loadState` each |
| `Presentation/` | Screens and views | Reads state, calls a use case, applies it |
| `App/` | The object graph | Reads ambient globals once, injects everything |
| `Infrastructure/` | `Mock*` doubles and `PreviewGraph` | `#if DEBUG` only |

The layering is enforced by review and, where the project allows, by putting each
layer in its own Swift package target so an illegal import fails to compile.

## Domain

Plain value types (`struct`, `enum`) plus use cases written as `enum`s of
`static func`s. Everything here is testable with no doubles at all, which is why
the bulk of the behaviour should live here.

Rules:

- No `import SwiftUI`, `UIKit` or `AppKit`. `Foundation` value types only.
- No I/O, no singletons, no `Date()`, `UUID()` or `.random` — time, identity and
  randomness are passed in as parameters.
- Every type is `Sendable` and `Equatable`; most are `Hashable` and `Codable`.
- A use case takes values and returns values. If it needs to ask the outside world
  something, the service asks first and passes the answer in.

### Composite types and derived status

When a screen depends on several independent facts, model each fact as its own
type and join them in a composite that *derives* a single status enum the UI
switches on:

```swift
struct TrackedItem: Sendable, Equatable, Identifiable {
    let remote: RemoteItem          // what the server / other devices agree on
    let local: LocalItemState?      // what exists on this device, nil if absent
    let snapshot: ItemSnapshot?     // what was observed a moment ago, nil if not yet

    var status: ItemStatus { ItemStatusUseCase.status(remote: remote, local: local, snapshot: snapshot) }
}
```

Keeping the facts separate is what lets the app distinguish states that a single
merged record would blur — "not on this device yet" versus "deleted", "not loaded
yet" versus "empty".

### Use cases carry the decisions

Name them for the decision they make: `XPlanUseCase` (what an action would do),
`XEligibilityUseCase` (whether it may happen), `XFilterUseCase` and
`XSortUseCase` (what a list shows), `XFormattingUseCase` (how a value reads). If a
decision can only be exercised by launching the app, it is in the wrong layer.

## Data

Every outside dependency is a `Sendable` protocol with one real implementation, so
a test can substitute it.

| Kind of dependency | Protocol shape | Typical real implementation |
| --- | --- | --- |
| Network API | `XAPIClienting` | `URLSessionXAPIClient` |
| Persistence | `XStoring` | `SwiftDataXStore`, `FileXStore` |
| Device-local settings | `LocalSettingsStoring` | `UserDefaultsLocalSettingsStore` |
| Secrets | `CredentialStoring` | `KeychainCredentialStore` |
| System frameworks | `XProviding` | `AVFoundation…`, `CoreLocation…`, `NSWorkspace…` |
| Platform UI that SwiftUI can't drive reliably | `XPresenting` | `UIKit…` / `AppKit…` presenters |
| Subprocesses (macOS) | `CommandRunning` | `ProcessCommandRunner` |
| Time | `Clocking` | `SystemClock` |

Rules:

- Protocols are `Sendable` and their methods are `async throws` where they touch
  the outside world. Implementations are `final class` or `actor`, never
  `@MainActor` — Data does not care which thread asks.
- Name protocols with an `-ing` suffix for the capability (`Storing`, `Clocking`)
  and implementations for the technology (`SwiftData…`, `URLSession…`).
- Errors are typed per boundary and classified close to the source, so a service
  switches on `.unauthorised` rather than parsing an `NSError`.

### Parse at the edge, purely

Anything the app learns from outside — JSON, CLI output, a file format, a
framework callback payload — goes through a pure parser: `String`/`Data` in,
Domain value out. The client does the I/O; the parser does the interpretation.
That way the awkward cases (malformed payloads, partial responses, an error that
looks like success) are tested as input-in, value-out, with no network or
subprocess in sight.

### Separate what travels from what doesn't

If the app syncs state across devices (CloudKit, a backend, a shared container),
split storage in two:

- **Shared** — what every device should agree on. Must be meaningful on a
  different machine. CloudKit-safe models: optional or defaulted properties, no
  unique constraints, optional relationships.
- **Local** — what must *not* travel: absolute paths, device capabilities,
  per-device preferences, caches, anything machine-specific.

Anything added to the shared store has to survive the question "does this mean the
same thing on another device?"

## Services

One `@MainActor @Observable final class` per screen or feature. Each owns its
state, exposes a single derived `loadState`, and is the only writer of what it
owns.

```swift
@MainActor @Observable
final class ItemsService {
    private(set) var items: [TrackedItem] = []
    private(set) var error: ItemsError?
    private(set) var isRefreshing = false

    var loadState: LoadState<[TrackedItem], ItemsError> { /* derived from the above */ }

    init(store: any ItemStoring, api: any ItemAPIClienting, clock: any Clocking) { … }
}
```

Rules:

- **Single writer.** Each piece of state has exactly one owning service. Others
  read it from the owner rather than keeping a copy. Settings in particular have
  one `SettingsService`; every other service reads behaviour from it.
- **One-way dependencies.** If service B needs A's data, B takes it from A and
  hands outcomes back through A's methods. Two services never mutate each other.
- **Derived, not stored, load state.** `loadState` is computed from the
  underlying properties, so it can never disagree with them.
- **No SwiftUI.** A service never imports SwiftUI and never calls
  `withAnimation`. Presentation concerns stay in Presentation.

### Single-flight refresh

Loading goes through a `SingleFlightRefreshing` helper: `refresh()` cancels the
in-flight task, starts a new one and *awaits* it. Callers — including tests — can
`await service.refresh()` and assert immediately. Nothing polls, nothing sleeps.

### Mutations are in place, not reloads

A local change **never** triggers a full reload. Add, remove and update each mutate
the published collection directly, synchronously where nothing is awaited, and
persist in the background.

This is not premature optimisation. A full refresh is usually expensive (network
round trips, disk, per-item work), and because `refresh()` cancels any refresh
already in flight, a second interaction during that window can discard the first
change outright. The symptoms — toggles that appear dead, deletions that appear to
do nothing, inserts that arrive late — all share that one cause.

When a mutation genuinely needs a round trip before it is complete (an identifier
assigned by the server, a value only the remote knows), insert the row immediately
in a `.loading` / `.pending` state and fill it in when the response arrives. Roll
back in place on failure.

## Presentation

Views read a service through `@Environment`, call a use case, and apply the
result. Nothing else.

```swift
struct ItemsScreen: View {
    @Environment(\.itemsService) private var items
    @Environment(\.settingsService) private var settings

    var body: some View {
        let visible = ItemFilterUseCase.visible(items.items, query: settings.query)
        ItemList(items: visible)
            .task { await items.refresh() }
    }
}
```

Rules:

- **Screens** read services; **views** below them take plain values and closures.
  A leaf view should be previewable with a literal.
- No business logic in `body`. If a view contains an `if` that encodes a product
  rule, that rule belongs in a use case.
- `@State` is for view-local, ephemeral UI state only (focus, expansion, a draft
  string). Anything that outlives the view belongs to a service.
- A root view switches on app phase (launching → onboarding → main) rather than
  each screen guarding for it.

### Injection

One `@Entry` environment key per service, each defaulting to the single hoisted
`AppDependencies.shared` graph. Every read returns the same instance, and a
preview or test can override any of them:

```swift
extension EnvironmentValues {
    @Entry var itemsService: ItemsService = AppDependencies.shared.itemsService
}
```

### Things that live here deliberately

Some concerns look like they could sit deeper but must stay in Presentation:

- **Animation.** Animate on stable identities (`items.map(\.id)`) rather than the
  values themselves, so a background refresh that changes row contents redraws
  without the list re-animating. A service calling `withAnimation` would invert the
  layering.
- **Platform presentation quirks.** Where a SwiftUI modifier is unreliable in
  practice (stacked sheets, focus on tvOS, file importers behind other sheets),
  drive the platform API through a `Presenting` protocol from Data rather than
  fighting the modifier. Presentation decides *when*; the presenter does *how*.

## App

`AppDependencies.makeGraph()` is the composition root and the only function that
reads ambient globals: `ProcessInfo`, `Bundle.main`, `FileManager.default`,
`UserDefaults.standard`, `TimeZone.current`, `Locale.current`, environment
variables, launch arguments. It resolves configuration once, builds every real
implementation, wires the services, and hands back an `AppGraph`.

Everything below receives plain values and protocols. A `grep` for
`UserDefaults.standard` or `Bundle.main` outside `App/` should return nothing.

Launch arguments for UI tests and previews (`-uiTesting`, `-resetState`, fixture
selection) are read here and nowhere else, and select a different graph rather
than branching inside services.

## Infrastructure

`#if DEBUG` only. Holds:

- `Mock*` / `Stub*` doubles for every Data protocol — configurable return values,
  recorded calls, no behaviour of their own.
- `PreviewGraph` — a complete graph built from doubles with representative
  fixtures, used by every `#Preview`.
- `ServiceHarness` — assembles a service (or the whole graph) from doubles for
  tests, with the doubles exposed for assertion.

## Testing

The layering is what makes a large unit suite and a small UI suite reasonable.

| Layer | How it's tested | Doubles |
| --- | --- | --- |
| Domain | Swift Testing, value in / value out, parameterised | None |
| Parsers | Fixture strings or files in, Domain values out | None |
| Services | Driven through `ServiceHarness`; `await refresh()` then `#expect` | Data doubles |
| Data | Integration tests against a real but disposable target | None (that's the point) |
| Presentation | Previews for every state; a thin XCUITest smoke suite | `PreviewGraph` |

Integration tests earn their keep where a stub cannot prove the behaviour: that a
write really persisted, that a request really carried the header, that a refused
operation really was refused. Run them against temporary directories, in-memory
stores, or a local test server — never shared state.

Rules:

- Services are tested by calling their public methods and asserting on their
  published state, never by reaching into private storage.
- No `Task.sleep` or polling in tests. If a test needs to wait, the API under
  test is missing an `await`.
- Time is a `Clocking` double; tests advance it explicitly.

## Concurrency

- Swift 6 language mode, complete strict concurrency checking.
- Services are `@MainActor`. Data is `Sendable` and nonisolated. Domain is
  `Sendable` values.
- Work leaves the main actor by awaiting a Data protocol, not by `Task.detached`
  inside a service.
- Long-lived tasks (observation streams, polling) are owned by a service, stored,
  and cancelled when the service is torn down or the scene goes inactive.

## Adding a feature

1. **Domain** — model the facts as value types; write the decisions as use cases;
   test them.
2. **Data** — if it touches anything outside, add a `Sendable` protocol, a real
   implementation, a pure parser for its output, and a `Mock*`.
3. **Service** — add or extend the single owner of the new state; derive
   `loadState`; mutate in place.
4. **App** — construct the implementation and service in `makeGraph()`; add the
   `@Entry` key.
5. **Presentation** — a screen that reads the service and calls the use case;
   leaf views that take values; previews for loading, empty, loaded and error.
6. **Docs** — if it adds a store, a protocol or a deliberate constraint, add a
   line to the project's own `ARCHITECTURE.md`.

## Recording deliberate constraints

Every project has decisions that look like omissions — the sandbox off, a
capability written but not enabled, an operation the app refuses to perform, data
that must never sync. List them in the project's `ARCHITECTURE.md` under
**Deliberate constraints**, each with the one-line reason, so the next person
doesn't "fix" them.