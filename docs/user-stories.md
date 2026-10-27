# Opal user stories

Stories for Opal v1, grouped into milestones. Vocabulary follows [GLOSSARY.md](../GLOSSARY.md). The reference screens of Obsidian are indexed in [screens/README.md](screens/README.md); the design is set by [design-brief.md](design-brief.md).

The user is someone who writes a lot and links their Notes. Some already keep an Obsidian Vault.

Each story has acceptance criteria. A story is done when its criteria pass in tests (Domain, parsers, Data and Services) or in a run against a fixture Vault copied to a temporary folder (Presentation).

## Milestones

| Milestone | Goal | Stories |
| --- | --- | --- |
| **M1 — Open a Vault and write a Note** (built 27/10/2026) | Open an existing Obsidian Vault or a new one, browse it, and write in a Note safely | M1-01 … M1-11 |
| M2 — Links | Follow Links, see Backlinks, find Notes by name | M2-01 … M2-07 |
| M3 — Find | The Index, full-text Search, Tags, unlinked mentions | M3-01 … M3-05 |
| M4 — Rich Editor | Live Markdown, Reading view, Properties, Embeds | M4-01 … M4-06 |
| M5 — Daily work | Daily Notes, Templates, rename with Link updates, Command Palette, Settings, tabs | M5-01 … M5-09 |

Out of scope for v1: Graph, Canvas, plugins, sync, publishing, iOS and iPadOS, collaboration.

---

## M1 — Open a Vault and write a Note

### M1-01 Open an existing Vault
As a user with an Obsidian Vault, I want to open its folder in Opal, so that I can write in the Notes I already have.

- On first launch, with no Vault remembered, Opal shows a welcome screen with **Open Vault…** and **Create Vault…**. No account, no sign-in.
- **Open Vault…** shows the macOS folder picker. Choosing a folder opens it as the Vault.
- Any folder works, with or without `.obsidian/`. Opal never creates `.obsidian/`, and never writes inside it.
- While the Vault is read, the window shows progress, not an empty tree.
- If the folder cannot be read, Opal says so and offers **Open Vault…** again.

### M1-02 Create a new Vault
As a new user, I want to create an empty Vault, so that I can start writing without setting anything up.

- **Create Vault…** shows a save panel for a new folder name and place.
- Opal creates the folder and opens it. It writes nothing else into it.
- If the folder already exists, the panel's own replace prompt applies; Opal opens the existing folder and never deletes its contents.

### M1-03 Reopen the last Vault
As a returning user, I want Opal to open the Vault I used last, so that I can carry on where I stopped.

- On launch Opal reopens the last Vault without asking.
- If that folder has moved or been deleted, Opal shows the welcome screen with a message naming the folder, not an error alert.
- **File ▸ Open Vault…** (⇧⌘O) switches to another Vault at any time. Unsaved edits are saved first.
- Opal remembers the Vault outside the Vault (the app's preferences), never in a file inside it.

### M1-04 Browse the Folder tree
As a user, I want to see the Vault's Folders, Notes and Attachments in the sidebar, so that I can find a Note by where I put it.

- The sidebar shows the Vault's name and a tree of its Folders, Notes and Attachments at any depth.
- Folders come first, then files. Each group is in name order, the way Finder sorts (`Note 2` before `Note 10`, case ignored).
- A Note shows its name without `.md`. An Attachment shows its full file name.
- Hidden items are not shown: any name starting with `.` (such as `.obsidian`, `.trash`, `.git`).
- Folders can be expanded and collapsed. The sidebar can be hidden.

### M1-05 Open a Note
As a user, I want to select a Note and read and edit its text, so that I can write.

- Selecting a Note in the sidebar opens it in the Editor. The window title shows the Note's name; the subtitle shows its Folder.
- The Editor shows the file's Markdown exactly, frontmatter included.
- Selecting an Attachment does not open it in the Editor; it shows its name and an **Open in Default App** button.
- If the file cannot be read (permissions, not UTF-8), the Editor says so and offers to try again. Opal never writes to that file.
- With no Note selected, the Editor shows a calm empty state with **New Note** (⌘N).

### M1-06 Edit and save a Note
As a user, I want my edits saved without thinking about it, so that I never lose work and never press Save.

- Edits are saved automatically shortly after typing stops, when another Note is opened, when the Vault is switched, and when Opal quits. ⌘S saves at once.
- The saved file holds exactly the text in the Editor. Opal does not change line endings, trailing whitespace, frontmatter or anything else.
- Opening a Note and not editing it never writes the file, and never changes its modification date.
- Typing is not changed behind the user's back: no smart quotes, smart dashes or automatic spelling correction in M1.
- Writes are atomic: a crash mid-save leaves the old file or the new file, never half of one.
- Undo and redo work for the open Note.

### M1-07 Create a Note
As a user, I want to create a Note in one keystroke, so that I can write something down now.

- **File ▸ New Note** (⌘N) creates `Untitled.md`, or `Untitled 1.md`, `Untitled 2.md` … if that name is taken, and opens it in the Editor.
- Where it goes follows Obsidian's `.obsidian/app.json` when present: `newFileLocation` `root` → the Vault root; `folder` → `newFileFolderPath` (created if missing); `current` → the Folder of the open Note. With no settings, the Vault root.
- The new Note is empty. It appears in the sidebar and is selected.

### M1-08 Create a Folder
As a user, I want to create a Folder, so that I can organise my Notes.

- **File ▸ New Folder** (⇧⌘N) creates `Untitled` (or `Untitled 1` …) in the Folder of the selected item, or the Vault root.
- The Folder appears in the sidebar.

### M1-09 Reveal in Finder
As a user, I want to see a Note's file in Finder, so that I can use other apps on it.

- The sidebar context menu has **Reveal in Finder** for every item, and **Open in Default App** for Attachments.

### M1-10 Empty Vault
As a user who just created a Vault, I want to know what to do next.

- A Vault with no Notes shows an empty sidebar message and the Editor's **New Note** empty state.

### M1-11 Never overwrite a change made elsewhere
As a user who also uses Obsidian, git or a sync tool, I want Opal never to overwrite a change it did not see, so that my Vault stays the source of truth.

- Before saving, Opal compares the file on disk with the text it last loaded or saved.
- If they match, it saves.
- If the file changed on disk and the Note has unsaved edits, Opal does not save. The Editor shows that the Note changed on disk, with **Keep My Version** (writes the edits) and **Use Version on Disk** (drops the edits and loads the file).
- If the file was deleted while open, saving creates it again with the Editor's text.
- **File ▸ Reload Vault** (⌘R) reads the tree again. (Watching the Vault for changes as they happen is M2-07.)

---

## M2 — Links

### M2-01 Follow a Link
- ⌘-click a `[[Link]]`, `[[Note|alias]]`, `[[Note#Heading]]` or `[[Note#^block]]` to open its target, scrolled to the Heading or Block.
- Link resolution follows Obsidian: exact path, then name anywhere in the Vault (shortest path wins), case-insensitive, then Alias.
- A Markdown Link `[text](path.md)` to a Note is followed too.

### M2-02 Unresolved Links
- An Unresolved Link looks different. Following it creates the Note (placed as in M1-07) and opens it.

### M2-03 Backlinks
- The inspector lists the Notes that link to the open Note, each with the line in context (screen `obsidian-08`).

### M2-04 Outgoing Links and outline
- The inspector lists the open Note's Links (`obsidian-09`) and its Headings (`obsidian-12`). Choosing a Heading scrolls to it.

### M2-05 Quick Switcher (⌘O)
- Fuzzy match on name, path and Alias (Obsidian misses Aliases by default; Opal does not). Recent Notes first with an empty query.
- Return opens; ⌘Return opens in a new tab; with no match, Return creates the Note.

### M2-06 Link suggestions
- Typing `[[` lists Notes, Aliases and Unresolved targets; `#` lists Headings and `^` lists Blocks of the chosen Note; `|` adds display text (`obsidian-14`).
- The inserted Link uses the shortest unambiguous path, or Markdown Link syntax when `useMarkdownLinks` is true.

### M2-07 Changes from outside
- Opal watches the Vault. Files added, removed or changed by other apps appear in the tree.
- An open Note with no unsaved edits reloads. With unsaved edits, M1-11 applies.

## M3 — Find

### M3-01 The Index
- Opal keeps a derived Index outside the Vault. Deleting it loses nothing; it is rebuilt on the next open, with progress.
- A 10,000-Note Vault reopens and is searchable in under a second once indexed.

### M3-02 Search (⇧⌘F)
- Full-text search, results grouped by Note with the match in context, updated as you type (`obsidian-13`).
- Operators: quoted phrases, `path:`, `file:`, `tag:`, `[property:value]`.

### M3-03 Tags
- The inspector lists all Tags, nested by `/`, with counts (`obsidian-10`). Choosing a Tag searches for it.
- Tags come from `#tag` in the body and the `tags` Property.

### M3-04 Unlinked mentions
- Below Backlinks, Notes that mention the open Note's name or Alias without a Link, with **Link** to turn a mention into a Link (with confirmation).

### M3-05 Large Vaults
- Folder tree, Note switching and Search stay responsive in a 10,000-Note Vault with Notes of 1 MB.

## M4 — Rich Editor

### M4-01 Live Markdown
- Headings, emphasis, Links, Tags, lists, checkboxes, quotes, code and callouts are styled as you type. Marks fade when the cursor is elsewhere. Can be turned off.

### M4-02 Reading view (⌘E)
- The Note rendered and not editable, including tables, callouts, code with syntax colour and maths (`obsidian-04`).

### M4-03 Properties
- Frontmatter shows as a small form above the text (`obsidian-03`) and can be edited as YAML. Editing one Property changes only that Property's lines.

### M4-04 Embeds
- `![[Note]]`, `![[Note#Heading]]`, images and PDFs show inline.

### M4-05 Checkboxes
- Clicking a checkbox toggles `[ ]` and `[x]` and changes nothing else in the line.

### M4-06 Paste and drop images
- A pasted or dropped image is saved as an Attachment (place from `attachmentFolderPath`) and an Embed is inserted.

## M5 — Daily work

### M5-01 Daily Note
- One command and a toolbar button open today's Daily Note, created from its Template when missing. Folder, name format and Template come from `.obsidian/daily-notes.json` when present (`obsidian-25`), else Opal's settings.

### M5-02 Templates
- Insert a Template from the Templates Folder (`.obsidian/templates.json`), with `{{date}}`, `{{time}}` and `{{title}}` filled in.

### M5-03 Rename with Link updates
- Renaming or moving a Note shows how many Notes have Links to it, and updates those Links only after the user confirms, one atomic write per Note. A setting chooses ask, always or never.

### M5-04 Delete
- Deleting a Note or Folder moves it to the macOS Trash after confirmation. Opal never deletes permanently.

### M5-05 Command Palette (⇧⌘P)
- Every command, searchable by name, shows its shortcut (`obsidian-05`).

### M5-06 Tabs and split view
- Notes open in tabs. Two Notes can be side by side. Back and forward move through history.

### M5-07 Settings
- Editor (font, size, line width, line spacing, spell check, live Markdown), Files and Links, Daily Notes, Appearance. Stored outside the Vault.

### M5-08 More than one window
- Each window shows one Vault. Two Vaults can be open at once.

### M5-09 Move and duplicate
- Move a Note to another Folder by drag or menu, with Link updates as in M5-03. Duplicate a Note.
