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
