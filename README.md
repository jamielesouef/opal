# Opal

Opal is a native Mac app for writing and linking Notes in plain Markdown. It is inspired by [Obsidian](https://obsidian.md), and it works on Obsidian Vaults as they are. Opal is not made by or affiliated with Obsidian.

Opal looks and works like a Mac app should. It uses the system sidebar, toolbar, fonts and colours, and follows light and dark mode.

> **Status:** Milestones 1 to 3 are built. The rest of the roadmap is listed at the end of this file.

## Why Opal

- **Your files stay yours.** A Vault is a folder of `.md` files on disk. Opal adds no hidden file, database or sidecar to your Notes.
- **Works with Obsidian.** Open an existing Obsidian Vault, and Obsidian can still open it. Opal reads Obsidian's settings but never writes inside `.obsidian/`.
- **Fast.** Opal keeps a search index beside your Vault, not inside it. Opal is built for Vaults of 10,000 Notes or more.
- **Private.** Opal has no account, no sign-in and no network code.
- **Safe.** Opal never overwrites a change it did not see. If a Note changes on disk while you have unsaved edits, Opal keeps both and asks you what to do.

## Features

### Vaults

- Open an existing folder as a Vault, with or without `.obsidian/`.
- Create a new, empty Vault.
- Reopen the last Vault at launch.
- Browse the Vault in a Folder tree in the sidebar, in Finder order. Hidden items and symbolic links are left out.
- Reveal any Note or Folder in Finder.
- Create Notes and Folders. New Notes go where Obsidian's settings say they should.
- An empty Vault shows a clear starting point.

### Writing

- Edit Markdown in a native text editor. Opal saves as you type, with a short delay, and saves again when you quit or switch apps.
- Opal writes only the text you change. Frontmatter, line endings and whitespace you did not touch stay the same.
- Links are coloured as you type. Unresolved Links look different from Links to Notes that exist.
- Notes must be UTF-8. Opal refuses to open other encodings rather than risk changing them.

### Links

- **Links and Aliases.** Opal reads `[[Note]]`, `[[Note|alias]]`, `[[Note#Heading]]`, `[[Note#^block]]` and Markdown links. It resolves them by path, relative path, name, or the `aliases` Property.
- **Follow a Link.** ⌘-click a Link to open it. Following an Unresolved Link creates the Note.
- **Link suggestions.** Type `[[` to get a list of Notes, Aliases and Headings. Choose one to insert the Link.
- **Backlinks.** The inspector lists every Note that links to the open Note, grouped by Note with the matching line in context.
- **Outgoing Links and outline.** The inspector lists the Links in the open Note and its Headings.
- **Unlinked mentions.** The inspector finds text that matches another Note's name or Alias but is not yet a Link. Turn one into a Link after you confirm it.
- **Back and forward.** Move through the Notes you have visited with ⌘[ and ⌘].

### Finding things

- **Quick Switcher (⌘O).** Find and open a Note by name or Alias with fuzzy matching. Recent Notes come first.
- **Search (⇧⌘F).** Full-text search across the Vault, with results grouped by Note and the match shown in context. Quoted phrases are supported.
- **Tags.** Opal reads `#tags` in the body and the `tags` Property. Nested tags such as `#project/opal` appear as a tree in the sidebar.
- **Index.** Opal builds an index of your Notes, Links, Tags, Properties and search text. The first build shows its progress in the sidebar. Opal keeps the index up to date as you save and as files change outside Opal.

### Working with other apps

- Changes made in Obsidian, git or a sync tool appear in Opal within a second.
- An open Note with no unsaved edits reloads when its file changes on disk.
- Changes in hidden folders such as `.obsidian/` and `.git/` are ignored.

### Mac integration

- An inspector you can show or hide (⌥⌘0).
- Light and dark mode follow the system setting.
- Sandboxed. Opal reads only the Vault folder you choose, through a security-scoped bookmark.

### Syntax Opal keeps

Opal reads and writes Obsidian syntax without change:

- Wikilinks, with aliases, Heading targets and Block targets
- Embeds, written as `![[Name]]`
- Nested `#tags`
- YAML frontmatter Properties, including `aliases` and `tags`

## Requirements

- macOS 26 (Tahoe) or later
- Xcode 26 or later, with the Swift 6.2 toolchain
- [XcodeGen](https://github.com/yonaskolb/XcodeGen), to generate the Xcode project from `project.yml`
- [GRDB.swift](https://github.com/groue/GRDB.swift) 7.10 or later. Swift Package Manager downloads it for you.

## Build and run

Opal's Xcode project is generated. Do not edit `Opal.xcodeproj` by hand.

```sh
xcodegen generate
open Opal.xcodeproj
```

Then choose the **Opal** scheme and press ⌘R. You can also build from the command line:

```sh
xcodebuild -scheme Opal -configuration Debug build
```

## Run the tests

The tests live in the local package `Modules/OpalKit`:

```sh
cd Modules/OpalKit
xcrun swift test
```

The tests use fixture Vaults copied to a temporary folder. They never touch a real Vault or Opal's real settings.

Performance tests for large Vaults run in Release with an environment variable:

```sh
OPAL_PERF=1 xcrun swift test -c release -Xswiftc -enable-testing --filter LargeVaultPerformanceTests
```

## Project layout

| Path | What is there |
| --- | --- |
| `App/Opal/` | The app: windows, the Editor, the inspector, commands and the composition root |
| `Modules/OpalKit/Sources/OpalCore/` | Domain rules, data access (files, parsers, Index) and services |
| `Modules/OpalKit/Sources/OpalDesign/` | Design tokens: spacing and editor metrics |
| `Modules/OpalKit/Tests/` | Swift Testing tests and fixture Vaults |
| `docs/` | Architecture decisions, user stories, the design brief and templates |

Start with [ARCHITECTURE.md](ARCHITECTURE.md), [GLOSSARY.md](GLOSSARY.md) and [docs/architecture.md](docs/architecture.md). The decisions behind the big choices are in [docs/adr/](docs/adr/).

## Roadmap

Opal is built in milestones. The full list of stories is in [docs/user-stories.md](docs/user-stories.md).

- **Milestone 4: Rich Editor.** Live Markdown, Reading view, a Properties form, Embeds, checkboxes, and pasting or dropping images.
- **Milestone 5: Daily work.** Daily Notes, Templates, rename with Link updates, delete, the Command Palette, tabs and split view, Settings, more than one window, and move and duplicate.

Not planned for v1: Graph view, Canvas, plugins, sync, publishing, and iOS or iPadOS.

## Contributing

Opal is a personal project for now. Issues and pull requests are welcome. Please read [CLAUDE.md](CLAUDE.md) and [docs/architecture.md](docs/architecture.md) first, because they set the rules for layers, state and file headers.

## Licence

Opal is released under the MIT Licence. See [LICENSE](LICENSE).

Obsidian is a trademark of its owner. Opal is not affiliated with or endorsed by Obsidian.
