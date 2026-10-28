# Opal architecture

The rules are in [docs/architecture.md](docs/architecture.md). This file names
Opal's pieces and its deliberate constraints.

**Status: Milestones 1 to 4 built; Milestone 5 in progress** (open a Vault and write a Note; Links; Find; see
[docs/user-stories.md](docs/user-stories.md)). Lines marked _built_ exist on
`HEAD`; everything else is still the target shape. When code lands, replace a
planned line with what was built, and add each new protocol, store and
constraint here.

## Built in Milestone 1

| Layer | Built |
| --- | --- |
| Domain | `Vault`, `NotePath`, `VaultEntry`, `VaultItemKind`, `VaultTreeNode`, `Note`, `ObsidianAppSettings`, `NewFileLocation`, `VaultError`. Use cases: `VaultTreeUseCase` (tree, Finder order, hidden items), `NewItemPlanUseCase` (where and what a new Note or Folder is called), `NoteSaveDecisionUseCase` (write, skip, adopt, recreate or conflict), `DetailContentUseCase`, `WindowTitleUseCase` |
| Data | `FileSystemVaultStore` (actor), `ObsidianAppSettingsParser` + `ObsidianAppSettingsDTO`, `SecurityScopedVaultAccess`, `UserDefaultsVaultLocationStore` |
| Services | `VaultService` (open, create, reopen, tree, new Note and Folder, reload), `NoteService` (open Note, edits, debounced autosave, conflict), `SingleFlightRefreshing` |
| Design | `AppSpacing`, `EditorMetrics` |
| Presentation | `RootScreen`, `WelcomeView`, `VaultScreen`, `FolderTreeView` + `FolderTreeRow`, `NoteScreen`, `MarkdownTextView` (TextKit 2, [ADR 0002](docs/adr/0002-textkit-2-editor.md)), `ConflictBanner`, `AttachmentView`, `SaveStatusView`, `OpalCommands`, `VaultActions` |
| App | `OpalApp` (one `Window`), `OpalAppDelegate` (saves on quit and on resign active), `AppDependencies`, `AppGraph`, `LaunchArguments` (and `LaunchRequest` in Presentation) |
| Infrastructure | `MockVaultFileStore`, `MockVaultAccess`, `MockVaultLocationStore`, `PreviewGraph` |

## Built in Milestone 2

| Layer | Built |
| --- | --- |
| Domain | `Link`, `LinkSubpath`, `LinkStyle`, `Heading`, `Block`, `ParsedNote`, `TextSpan`, `Backlink`, `BacklinkGroup`, `OutgoingLink`, `TextStyleRun` + `TextStyleKind` (was `LinkHighlight`), `LinkDestination`, `LinkQuery`, `LinkSuggestion`, `LinkResolver` (path, relative path, name with shortest path, Alias), `LinkMap` (in-memory Backlinks and Unresolved targets), `NavigationHistory`, `RevealRequest`, `SwitcherCandidate`, `SwitcherMatch`. Use cases: `LinkFollowUseCase`, `BacklinkGroupUseCase`, `LinkSuggestionUseCase`, `QuickSwitcherMatchUseCase`, `TextLineUseCase` |
| Data | `MarkdownNoteParser` (pure: Links, Embeds, Headings, Blocks, `aliases`; skips code and frontmatter), `FSEventsVaultWatcher` ([ADR 0003](docs/adr/0003-fsevents-dispatch-queue-exception.md)), `UserDefaultsRecentNotesStore` |
| Services | `LinkService` (the Link map, rebuilt off the main actor; `openNote`, the open Note's parsed Links, Headings and Link colours, which `NoteService` keeps current), `NavigationService` (open, follow, back and forward, reveal a line, recent Notes, inspector and Quick Switcher visibility), `QuickSwitcherService` (query, results, create, `[[` suggestions; results and suggestions are computed off the main actor from cached candidates). `VaultService` gains `entries`, `createNote(at:)`, the watcher and `onExternalChange`; `NoteService` gains `reloadIfUnchanged` and tells `LinkService` after each save |
| Design | `EditorMetrics` inspector, switcher and suggestion sizes |
| Presentation | `InspectorView` + `InspectorPane`, `BacklinksView`, `OutgoingLinksView`, `OutlineView`, `QuickSwitcherView` + `QuickSwitcherRow`, `LinkSuggestionPanel` + `LinkSuggestionList` + `LinkSuggestionRow`; the Editor colours Links, follows them on ⌘-click and reveals a line; Go menu (⌘O, ⌘[, ⌘]) and Toggle Inspector (⌥⌘0) |

## Built in Milestone 3

| Layer | Built |
| --- | --- |
| Domain | `FileStamp`, `IndexedNote`, `IndexSyncPlan` + `IndexSyncPlanUseCase`, `IndexError`, `TagNode` + `TagTreeUseCase`, `SearchQuery` + `SearchQueryUseCase`, `SearchHit`, `SearchResult`, `SearchLine`, `SearchSnippetUseCase`, `UnlinkedMention` + `UnlinkedMentionUseCase`, `SidebarPane`. `ParsedNote` gains `tags` and `skippedSpans` and is `Codable` |
| Data | `GRDBIndexStore` (GRDB 7, SQLite, FTS5; [ADR 0004](docs/adr/0004-index-in-sqlite-with-grdb.md)), `FTSQueryBuilder`, `IndexLocation`. `FileSystemVaultStore` gains `noteStamps()` and `stamp(of:)`, walking with `enumerator(at:includingPropertiesForKeys:)` |
| Services | `IndexService` (sync by file stamps, in batches, with progress; updates on saves and outside changes), `SearchService` (query, debounce, results), `MentionService` (unlinked mentions, link after confirmation). `LinkService` loads parsed Notes from a ready Index; the Link map also builds the Tag tree |
| Presentation | Sidebar panes (Files, Search, Tags), `SearchView`, `TagsView`, `IndexStatusView`, `UnlinkedMentionsSection`; ⇧⌘F |

## Built in Milestone 4

| Layer | Built |
| --- | --- |
| Domain | `TextStyleRun` + `TextStyleKind` (Links, marks, Headings, emphasis, code, quotes, callouts, lists, checkboxes, rules, Tags, frontmatter, done tasks). `CheckboxToggleUseCase` + `CheckboxToggle` (the one character a click changes). `TextSpan.shifted(by:)`, `TextLineUseCase.line(atOffset:in:)`. Reading view: `ReadingBlock` + `ReadingBlockKind`, `ReadingInline` + `ReadingInlineStyle`, `CodeToken` + `CodeTokenKind`, `ReadingBlockID`. Embeds: `EmbedContent`, `EmbedMedia`, `EmbedUseCase` (media kind, `|width`, the lines of a Heading's section or a Block's paragraph). Attachments: `AttachmentUseCase` (folder from `attachmentFolderPath`, pasted-image name, a free name, Embed text in the Vault's `LinkFormat`). `ObsidianAppSettings` gains `newLinkFormat`. Properties: `Frontmatter`, `Property`, `PropertyValue`, `PropertyType`, `PropertyTypeUseCase` (value, name, `types.json`), `PropertyEditUseCase` (set, add, remove: only that Property's lines change). `TagTreeUseCase.searchQuery(forTag:)` |
| Data | `MarkdownStyleParser` (pure: text and `ParsedNote` in, style runs out; shares line, fence and code helpers with `MarkdownNoteParser`), `MarkdownReadingParser` + `ReadingInlineBuilder` (reading blocks from the same parse, [ADR 0005](docs/adr/0005-reading-view-in-swiftui.md)), `CodeTokenizer` (keywords, strings, numbers, comments for Swift, Python, JavaScript, JSON, YAML, shell), `FrontmatterParser` (Properties with their source lines; YAML it cannot read is kept as it is), `ObsidianTypesParser` + `ObsidianTypesDTO` (`.obsidian/types.json`, read only). `VaultFileStoring.createFile(at:data:)` (never replaces a file). `Clocking` |
| Services | `LinkService.openNote`: Link colours plus Markdown style runs (sorted by location), the Link-only runs and the frontmatter, always computed off the main actor (200 ms debounce over 64 KB). Not stored in the Index. `LinkService.readingBlocks(of:text:)` builds reading blocks off the main actor; `LinkService.embed(_:from:chain:)` resolves and reads an Embed ([ADR 0006](docs/adr/0006-embeds-only-in-reading-view.md)); `mapRevision`. `NavigationService.isReadingView` and `editorTopOffset`. `VaultService.propertyTypes`; `NoteService.frontmatter`, `type(of:)`, `setProperty`, `removeProperty`, `addProperty`, `toggleCheckbox(onLine:)`, `attach(_:named:)`; `VaultService.createAttachment` |
| Design | `EditorMetrics` Heading scales, code scale, block indent and bar width |
| Presentation | `MarkdownStyler` (style kind to text storage attributes, only in a window around what is on screen; mark fading), `MarkdownBlock` + `MarkdownBlockFragment` (TextKit 2 layout fragments draw quote bars, callout and code block backgrounds), `EditorPreferences`; View › Live Markdown; clicking a checkbox toggles it as one undo step. `ReadingView` + `ReadingBlockView` + `ReadingText` + `CalloutStyle` + `ReadingKey` + `EmbedView` + `EmbedKey` + `PDFEmbedView` (Presentation/Reading); View › Reading View (⌘E) and a toolbar button. `PropertiesView` + `PropertyRow` + `PropertyType+Display` above the Editor and Reading view; `NoteTagsView`, the inspector's Tags tab |
| App | Debug-only `-OpalSnapshot <png>` draws the window to a PNG and quits; `-OpalReadingView` opens in Reading view. `SystemClock` (the only reader of the date and time zone) |

## Built in Milestone 5

| Layer | Built |
| --- | --- |
| Domain | `DailyNoteSettings`, `MomentFormatUseCase` (Moment date tokens), `DailyNotePlanUseCase` (path and Template path), `TemplateFillUseCase` (`{{date}}`, `{{time}}`, `{{title}}`, with formats), `TemplateSettings`, `TextInsertion`. Rename: `RenameUseCase` (new name checks), `RenameProblem`, `RenamePlan` (every moved file and the Notes that link to them), `LinkRewriteUseCase` (rewrites Links to moved files, keeping style, subpath, alias and relative form). `NotePath.appendingNoteExtension`, `replacingPrefix(_:with:)`, `NavigationHistory.move` |
| Data | `ObsidianDailyNotesParser` + DTO (`.obsidian/daily-notes.json`), `ObsidianTemplatesParser` + DTO (`.obsidian/templates.json`); both read only. `VaultFileStoring.moveItem(from:to:)` (case-only renames go through a temporary name) |
| Services | `DailyNoteService` (open or create today's Daily Note through `Clocking`); `RenameService` (plan a rename or move, then move the file, rewrite Links in each linking Note atomically, and update the open Note, history and Index); `TemplateService` (Templates in the Templates Folder, fill for the open Note, an insertion request the Editor applies at the cursor); `VaultService.dailyNoteSettings`, `templateSettings`, `createNote(at:text:)` |
| Presentation | Go › Today's Daily Note (⌥⌘D) and a toolbar button; Edit › Insert Template… (⌥⌘T) and `TemplatePickerView`; Folder tree: Rename… and Return rename in place (`FolderTreePane`, `FolderTreeActions`), with an "Update Links in N Notes?" dialog; drag a row onto a Folder or Move to… (`MoveToFolderView`) to move; `-OpalDailyNote`, `-OpalTemplates`, `-OpalRename <path>`, `-OpalMove <path>`. `-OpalSnapshot` also writes an attached sheet as `*.sheet.png` |

Built protocols: `Clocking`, `VaultFileStoring`, `VaultAccessGranting`, `VaultLocationStoring`, `VaultWatching`, `RecentNotesStoring`, `IndexStoring`.
Tests: `Modules/OpalKit/Tests/OpalCoreTests` (`xcrun swift test`, or the `Opal`
scheme's test action).

Launch arguments for acceptance runs, read only in `AppDependencies`:
`-OpalVaultPath <folder>` opens that folder without remembering it, and
`-OpalDefaultsSuite <name>` keeps Opal's preferences in that suite instead of
the app's own domain, `-OpalOpenNote <path>` opens a Note, `-OpalAppearance
light|dark` forces the look, `-OpalQuickOpen <query>` opens the Quick Switcher,
`-OpalTypeText <text>` (Debug builds only) types into the Editor,
`-OpalIndexFolder <folder>` keeps the Index there, `-OpalSearch <query>` runs a
Search, and `-OpalSidebarPane files|search|tags` picks the sidebar pane.
Debug-only `-OpalSnapshot <png>` draws the window to a PNG and quits, and
`-OpalReadingView` opens the Note in Reading view.
`LaunchArguments` turns the arguments that act on the window into one
`LaunchRequest` value, which `RootScreen` and `NoteScreen` read from the
environment; a new argument touches `LaunchArguments`, `LaunchRequest` and the
view that acts on it.

## Layers

| Layer | Where | What lives there |
| --- | --- | --- |
| Domain | `Modules/OpalKit/Sources/OpalCore/Domain/` | Value types: `Vault`, `Note`, `NotePath`, `Link`, `LinkTarget`, `Heading`, `Block`, `Tag`, `Property`, `Attachment`. Pure use cases: Link resolution (name, Alias, path, case), Backlinks, unlinked mentions, rename plan (which Links change), Daily Note name and place, search ranking, Quick Switcher match |
| Data | `Modules/OpalKit/Sources/OpalCore/Data/` | The Vault file store, the file watcher, pure parsers (Markdown, frontmatter, Links, Tags), the Obsidian settings reader, the Index store |
| Services | `Modules/OpalKit/Sources/OpalCore/Services/` | `VaultService` (open Vault, file tree, changes), `NoteService` (the open Note, edits, save), `LinkService` (Backlinks, unlinked mentions, rename), `SearchService`, `QuickSwitcherService`, `DailyNoteService`, `SettingsService` |
| Design | `Modules/OpalKit/Sources/OpalDesign/` | Design tokens. A leaf module: depends on nothing in the package |
| Presentation | `App/Opal/Presentation/` | The window (sidebar, Editor, inspector), the Quick Switcher, the Command Palette, Settings, the `@Entry` keys |
| App | `App/Opal/App/` | The composition root. The only place that reads the home folder, saved Vault folder access and other ambient globals |
| Infrastructure | `App/Opal/Infrastructure/` | `#if DEBUG` mocks and `PreviewGraph` |

## Planned protocols

| Protocol | Real implementation | Notes |
| --- | --- | --- |
| `VaultFileStoring` | `FileSystemVaultStore` (actor) | Lists, reads and writes files inside the Vault root only. Atomic writes. Never follows a link out of the Vault |
| `VaultWatching` | `FSEventsVaultWatcher` | Reports file changes made outside Opal (Obsidian, git, sync tools) as an `AsyncStream` |
| `NoteParsing` | `MarkdownNoteParser` | Pure: Note text in, Headings, Links, Embeds, Tags, Properties and Blocks out |
| `ObsidianSettingsReading` | `ObsidianSettingsFile` | Reads `.obsidian/app.json`, `daily-notes.json` and `templates.json` when present. Read only |
| `IndexStoring` | `GRDBIndexStore` | The derived Index. Rebuilt from the Vault when missing, damaged or a different schema version |
| `Clocking` | `SystemClock` | Today's date for Daily Notes |

## Deliberate constraints

- **The Vault is the source of truth.** Notes are plain `.md` files. Opal adds no
  hidden file to a Note and no sidecar beside it. Everything Opal knows about a
  Note comes from its file.
- **The Index is derived.** It lives outside the Vault (planned:
  `~/Library/Application Support/Opal/Indexes/<vault-id>/`). Deleting it loses
  nothing; Opal rebuilds it on the next open.
- **Opal never writes inside `.obsidian/`.** It reads Obsidian's settings so a
  Vault behaves the same in both apps. Opal's own settings live outside the Vault.
- **Opal changes only what it was asked to change.** A save writes the user's text
  as it is. Opal never reformats frontmatter, line endings or whitespace in a part
  of the file the user did not edit.
- **A rename that updates Links asks first.** It shows how many Notes will change,
  then writes each one atomically.
- **Changes from outside win when the Note has no unsaved edits.** When a Note has
  unsaved edits and its file changes on disk, Opal keeps both and asks the user.
- **Obsidian syntax is kept**: wikilinks with alias, Heading and Block targets,
  Embeds, nested Tags, YAML Properties, `aliases`. Opal may render more, but it
  never writes syntax that Obsidian cannot read.
- **No network.** v1 needs no server and no account.
- **Sandboxed, with a security-scoped bookmark per Vault** ([ADR 0001](docs/adr/0001-sandboxed-app-with-security-scoped-vault-bookmarks.md)).
- **Symbolic links are skipped.** The Folder tree leaves them out and the store
  refuses to read or write through one, so nothing outside the Vault is touched.
- **A Note must be UTF-8.** Opal refuses to open any other encoding rather than
  risk rewriting it. A byte order mark is kept.
- **Saves never overwrite a change Opal did not see.** Before writing, the store
  re-reads the file; if it differs from what Opal last loaded or saved,
  `NoteSaveDecisionUseCase` reports a conflict and nothing is written.
- **Atomic writes replace the file.** Extended attributes on a Note are not
  carried over in M1.
- **Editor substitutions are off.** Smart quotes, smart dashes, text
  replacement and automatic spelling correction would change text the user did
  not type differently. They become settings in M5.
- **One window, one Vault** until M5-08. `Window`, not `WindowGroup`.
- **The Vault is watched with FSEvents.** `FSEventsVaultWatcher` owns the one
  `DispatchQueue` in Opal ([ADR 0003](docs/adr/0003-fsevents-dispatch-queue-exception.md)).
  Hidden paths are dropped; an open Note reloads only when it has no unsaved
  edits and the disk differs from what Opal last wrote.
- **The Index lives outside the Vault**, one SQLite file per Vault under
  Application Support (`-OpalIndexFolder` in tests and acceptance runs). It is
  versioned with `PRAGMA user_version`; any mismatch or damage deletes and
  rebuilds it. GRDB is imported only in `GRDBIndexStore`.
- **The Link map is held in memory** and built from the Index when it is
  ready, from the files otherwise.
- **Performance budget (10,000 Notes, Release):** first index under 20 s,
  reopen under 1 s, Search under 100 ms. `OPAL_PERF=1 xcrun swift test -c
  release -Xswiftc -enable-testing --filter LargeVaultPerformanceTests`.
- **Presentation never parses a Note.** The Editor and the inspector read
  `LinkService.openNote`. A Note over 64 KB is parsed off the main actor 200 ms
  after typing stops; a smaller one at once (review 27/10/2026).
- **Recent Notes live in Opal's preferences**, keyed by the Vault folder, never
  in the Vault.
- **`[[` suggestions use Opal's own panel**, not `NSTextView` completion, which
  inserts the only match at once while the user is still typing.
- **`UserDefaultsVaultLocationStore` is `@unchecked Sendable`.** `UserDefaults`
  is documented as thread-safe but not marked `Sendable`.
- **Panels and Finder actions are called from Presentation.** `VaultPanels`
  (`NSOpenPanel`, `NSSavePanel`) and `WorkspaceActions` (`NSWorkspace`) are
  `@MainActor` AppKit calls that Data, which is never `@MainActor`, cannot own.

## Open questions

- **Plugins.** Not in v1. Obsidian's JavaScript plugins will not run in Opal.
