# Obsidian reference screens

Screenshots of Obsidian 1.14.5 on macOS, taken on 27/10/2026 to plan Opal. They show what an Obsidian user already knows, not what Opal must look like: Opal follows [the design brief](../../design-brief.md) and the macOS Human Interface Guidelines.

How they were taken: Obsidian ran with its own temporary profile (`--user-data-dir` in a temporary folder) on a copy of the `Garden` fixture Vault from `Modules/OpalKit/Tests/OpalCoreTests/Fixtures/Vaults/Garden`. No real Vault was opened. The PNGs are ignored by git (`docs/screens/*.png` in `.gitignore`); this index is not.

| File | Screen | What to take from it | Story |
| --- | --- | --- | --- |
| `obsidian-01-vault-chooser.png` | First launch: create, open or sync a vault | Opal needs only Create and Open. No account, no sync | M1-01, M1-02 |
| `obsidian-02-vault-empty-tab.png` | Vault open, no Note open | Folder tree, Vault name at the foot of the sidebar, empty Editor with New Note | M1-04, M1-10 |
| `obsidian-03-note-live-preview.png` | A Note in Live Preview | Inline title, Properties form, styled Headings, checkboxes, callout, Embed, status bar (Backlinks, words, characters) | M1-05, M4 |
| `obsidian-04-note-reading-view.png` | Reading view | Rendered Note, Heading Links shown as `Note > Heading` | M4 |
| `obsidian-05-command-palette.png` | Command Palette | Every command by name with its shortcut | M5 |
| `obsidian-06-note-source-mode.png` | Source mode | The raw Markdown and YAML Opal must keep exactly | M1-06 |
| `obsidian-07-quick-switcher.png` | Quick Switcher, query `so` | Fuzzy match on path, Unresolved Link targets listed, ⇧↩ creates | M2 |
| `obsidian-08-backlinks-and-unlinked-mentions.png` | Inspector: Backlinks | Linked mentions grouped by Note with context, then unlinked mentions | M2, M3 |
| `obsidian-09-outgoing-links-pane.png` | Inspector: outgoing Links | Note, Heading and Attachment targets | M2 |
| `obsidian-10-tags-pane.png` | Inspector: Tags | Nested Tags with counts | M3 |
| `obsidian-11-all-properties-pane.png` | Inspector: all Properties | Property names, inferred types, counts | M4 |
| `obsidian-12-outline-pane.png` | Inspector: outline | Headings of the open Note | M2 |
| `obsidian-13-search.png` | Search, query `soil` | Results grouped by Note, match in context, sort menu | M3 |
| `obsidian-14-link-suggestions.png` | `[[` suggestions in the Editor | Notes, Unresolved targets, hints for `#`, `^`, `\|` | M2 |
| `obsidian-15-file-context-menu.png` | Folder tree context menu | Open in new tab, Duplicate, Move, Reveal in Finder, Rename, Delete | M1-09, M5 |
| `obsidian-16-rename-inline.png` | Inline rename in the Folder tree | Rename in place | M5 |
| `obsidian-17-graph-view-out-of-scope.png` | Graph | Out of scope for v1 | — |
| `obsidian-18-daily-note.png` | Today's Daily Note | Breadcrumb `Daily Notes / 2026-10-27` in the header | M5 |
| `obsidian-19-vault-switcher.png` | Vault menu | Switch Vault, manage Vaults | M1-03 |
| `obsidian-20-settings-general.png` | Settings: General | Mostly account and updates; not needed | M5 |
| `obsidian-21-settings-editor.png` | Settings: Editor | Default view, Live Preview, readable line length, Properties display | M5 |
| `obsidian-22-settings-files-and-links.png` | Settings: Files and links | New Note location (`Inbox` from `app.json`), Attachment folder, Link format | M1-07, M5 |
| `obsidian-23-settings-appearance.png` | Settings: Appearance | Follow system, accent colour, fonts | M5 |
| `obsidian-24-settings-hotkeys.png` | Settings: Hotkeys | Every command can take a shortcut | M5 |
| `obsidian-25-settings-daily-notes.png` | Settings: Daily notes | Format, Folder, Template from `daily-notes.json` | M5 |

## Things noticed

- Obsidian shows `Templates/Daily` as "File not found" in the Daily notes settings, although `Templates/Daily.md` exists. Opal should resolve a Template path with or without `.md`.
- The Quick Switcher did not match the Alias `Dirt` for `Soil` with default settings. The design brief asks Opal to match Aliases.
- The Unresolved Link `[[Ideas That Do Not Exist Yet]]` shows in a fainter colour and appears in the Quick Switcher and `[[` suggestions as a Note that can be created.

## Opal, Milestone 1

Taken on 27/10/2026 from a Debug build, sandboxed, on a copy of the `Garden` fixture Vault in a temporary folder, with preferences in a throwaway suite (`-OpalDefaultsSuite`).

| File | Screen | Story |
| --- | --- | --- |
| `opal-m1-01-welcome.png` | First launch, no Vault remembered | M1-01, M1-02 |
| `opal-m1-02-note-editor.png` | A Note open in the Editor after an edit | M1-04, M1-05, M1-06 |
| `opal-m1-03-conflict.png` | The Note changed on disk while it had edits | M1-11 |
| `opal-m1-04-new-note-in-inbox.png` | ⌘N placed the Note in `Inbox`, from `.obsidian/app.json` | M1-07 |

## Opal, Milestone 2

Taken on 27/10/2026 from a Debug build, sandboxed, on a copy of the `Garden` fixture Vault in the app container's temporary folder, with preferences in a throwaway suite (`-OpalDefaultsSuite`). Most shots are set up with launch arguments, not clicks: `-OpalOpenNote <path>`, `-OpalAppearance light|dark`, `-OpalQuickOpen <query>`, and the Debug-only `-OpalTypeText <text>`. The inspector tab comes from `inspectorPane` in the throwaway suite.

| File | Screen | Story |
| --- | --- | --- |
| `opal-m2-01-links-styled.png`, `-dark` | Links in the accent colour, the Unresolved Link fainter | M2-03, M2-04 |
| `opal-m2-02-inspector-backlinks.png`, `-dark` | Inspector: Backlinks of `Soil`, grouped by Note, with the line in context | M2-05 |
| `opal-m2-02b-no-backlinks.png` | Inspector: no Backlinks | M2-05 |
| `opal-m2-03-inspector-outgoing.png`, `-dark` | Inspector: outgoing Links of `Welcome` | M2-06 |
| `opal-m2-04-inspector-outline.png`, `-dark` | Inspector: outline of `Opal Roadmap` | M2-06 |
| `opal-m2-05-quick-switcher.png`, `-dark` | Quick Switcher, query `so` | M2-07 |
| `opal-m2-05b-quick-switcher-alias.png` | Quick Switcher, query `dirt` finds `Soil` by its Alias | M2-07 |
| `opal-m2-05c-quick-switcher-create.png` | Quick Switcher, no match: Return creates the Note | M2-07 |
| `opal-m2-06-link-suggestions.png` | `[[so` suggestions under the cursor | M2-09 |
| `opal-m2-07-back-forward.png` | Back and forward in the toolbar | M2-10 |
| `opal-m2-08-outside-change.png` | `Welcome` changed and `Peas` added by another app, shown without ⌘R | M2-08 |

## Opal, Milestone 3

Taken on 27/10/2026 the same way as Milestone 2, with the Index in a throwaway folder (`-OpalIndexFolder`). New set-up arguments: `-OpalSearch <query>` and `-OpalSidebarPane files|search|tags`. The indexing shot uses a generated 3,000-Note Vault.

| File | Screen | Story |
| --- | --- | --- |
| `opal-m3-01-indexing.png` | “Indexing 600 of 3,000 Notes…” at the foot of the sidebar | M3-01 |
| `opal-m3-02-search.png` | Search for `soil`, results grouped by Note with matches marked | M3-04 |
| `opal-m3-02-search-dark.png` | Search for `tag:#garden`, dark | M3-03, M3-04 |
| `opal-m3-03-tags.png` | Tags pane, nested, with Note counts | M3-03 |
| `opal-m3-04-unlinked-mentions.png` | Backlinks tab of `Gardening Basics` with an unlinked mention and **Link** | M3-05 |

## Opal, Milestone 4

Taken on 28/10/2026 from a Debug build with `-OpalSnapshot <png>`: the app draws its own window and quits, so no Screen Recording permission is needed. `cacheDisplay` does not draw materials faithfully. The sidebar selection shows as a black bar, the toolbar is blank, and dark sidebar text looks dim. Judge only the Editor. The Vault is a copy of `Garden` in the app container's temporary folder, with [`fixtures/Live Markdown.md`](fixtures/Live%20Markdown.md) copied in. That Note is not part of `Garden`, so test counts don't change.

| File | Screen | Story |
| --- | --- | --- |
| `opal-m4-01-live-markdown-light.png`, `-dark` | Every live Markdown style, with the cursor on the last line | M4-01 |
| `opal-m4-01-cursor-line.png` | `-OpalTypeText " and **more** [[Soil]]"`: marks on the cursor's line are full strength, the line above is faint | M4-01 |
| `opal-m4-05-checkboxes.png` | An open task with accent brackets; a done task struck through and faint | M4-05 |
| `opal-m4-02-reading-view.png` | Reading view (`-OpalReadingView`) of the live Markdown fixture: Headings, emphasis, Links shown by name, a quote, a callout with its icon, checkboxes | M4-02 |
| `opal-m4-02-reading-table-code-dark.png` | Reading view, dark: a table, Python with syntax colour, `Tomatoes > Watering` | M4-02 |

In these shots, Links look paler than in the app because `cacheDisplay` does not draw SwiftUI's link tint faithfully.
| `opal-m4-03-properties.png` | The Properties form above `Welcome` (Aliases, Tags, a date), Add Property, Edit as YAML, and the new Tags tab in the inspector | M4-03 |
| `opal-m4-04-embeds.png` | Reading view of [`fixtures/Embeds.md`](fixtures/Embeds.md): a whole Note (with its own image Embed inside), a Heading's section, a Block | M4-04 |
| `opal-m4-04-embeds-media-dark.png` | An image at `|200`, a PDF (blank in the snapshot), an Unresolved Embed with Create Note | M4-04 |

## Opal, Milestone 5

Taken the same way as Milestone 4 (`-OpalSnapshot`). `-OpalDailyNote` opens today's Daily Note at launch.

| File | Screen | Story |
| --- | --- | --- |
| `opal-m5-01-daily-note.png` | Today's Daily Note created from `Templates/Daily` in `Daily Notes/` | M5-01 |
