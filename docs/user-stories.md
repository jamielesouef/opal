# Opal user stories

Stories for Opal v1, grouped into milestones. Vocabulary follows [GLOSSARY.md](../GLOSSARY.md). The reference screens of Obsidian are indexed in [screens/README.md](screens/README.md); the design is set by [design-brief.md](design-brief.md).

The user is someone who writes a lot and links their Notes. Some already keep an Obsidian Vault.

Each story has acceptance criteria. A story is done when its criteria pass in tests (Domain, parsers, Data and Services) or in a run against a fixture Vault copied to a temporary folder (Presentation).

## Milestones

| Milestone | Goal | Stories |
| --- | --- | --- |
| **M1 — Open a Vault and write a Note** (built 27/10/2026) | Open an existing Obsidian Vault or a new one, browse it, and write in a Note safely | M1-01 … M1-11 |
| **M2 — Links** (built 27/10/2026) | Follow Links, see Backlinks, find Notes by name | M2-01 … M2-10 |
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

Each acceptance line starts with how it is checked: `[unit]` a Swift Testing test, `[snap]` a screenshot of the running app on a copy of the `Garden` fixture Vault, `[manual]` a person must try it.

The Link map in M2 is held in memory, built from the files after the Vault opens. It is not the Index (M3-01): nothing is stored, so there is nothing to delete or rebuild.

### M2-01 Read the Links in a Note
As a user, I want Opal to understand the Links I write in Obsidian syntax, so that every later story can follow, list and suggest them.
Screens: `obsidian-06-note-source-mode.png`
Acceptance:
- [unit] The parser finds `[[Note]]`, `[[Note|alias]]`, `[[Note#Heading]]`, `[[Note#^block]]`, `[[Folder/Note]]` and `![[Embed]]`, with their ranges in the text.
- [unit] It finds Markdown Links `[text](path.md)` and `[text](My%20Note.md)`. A Markdown Link to `http:` or `mailto:` is not a Link.
- [unit] It ignores Links inside fenced code blocks, inline code and frontmatter.
- [unit] It finds Headings (`#` to `######`, outside code) and Block ids (`^id` at the end of a line).
- [unit] It reads `aliases` from frontmatter as a list or a single string. Other Properties wait for M4.
Status: done

### M2-02 Resolve a Link to its target
As a user, I want `[[Soil]]` to find `Soil.md` wherever it lives, the way Obsidian does, so that my existing Links work.
Depends: M2-01
Acceptance:
- [unit] Order: exact path from the Vault root, then path relative to the linking Note, then the Note name anywhere in the Vault. When names clash, the shortest path wins, then name order.
- [unit] Case is ignored. `.md` may be left out.
- [unit] An Alias resolves when no Note has that name (`[[Dirt]]` → `Soil.md`).
- [unit] `[[seedlings.png]]` resolves to an Attachment.
- [unit] A Link that matches nothing is an Unresolved Link.
Status: done

### M2-03 Follow a Link (⌘-click)
As a user, I want to ⌘-click a Link to open its target, so that I can move through my Notes.
Screens: `opal-m2-01-links-styled.png`
Depends: M2-02
Acceptance:
- [snap] Links show in the accent colour. The text itself never changes.
- [manual] ⌘-click on a Link opens its target. On a Heading or Block Link, the Editor scrolls to that line and puts the cursor there.
- [manual] A Link to an Attachment opens it in its default app.
- [manual] A plain click places the cursor as usual. The pointer is a hand only while ⌘ is held over a Link.
Status: done

### M2-04 Unresolved Links
As a user, I want to see which Links have no Note yet, and create it by following the Link.
Screens: `opal-m2-01-links-styled.png`
Depends: M2-03
Acceptance:
- [snap] An Unresolved Link shows fainter than a resolved Link (`[[Ideas That Do Not Exist Yet]]` in `Welcome`).
- [unit] Following it plans a new Note: a bare name goes where M1-07 places new Notes; a name with a Folder (`[[Ideas/New]]`) goes in that Folder.
- [manual] The new Note opens and appears in the sidebar. Its Link now shows as resolved.
Status: done

### M2-05 Backlinks
As a user, I want to see the Notes that link to the open Note, each with the line in context, so that I can see how it connects.
Screens: `obsidian-08-backlinks-and-unlinked-mentions.png`, `opal-m2-02-inspector-backlinks.png`
Depends: M2-02
Acceptance:
- [unit] `Soil` has Backlinks from `Gardening Basics`, `Tomatoes` (two Links) and `The Soil Book`. A Link through an Alias counts.
- [snap] The inspector (⌥⌘0, toolbar button) shows Backlinks grouped by Note, with each line in context and the count.
- [manual] Clicking a Backlink opens that Note at the line.
- [unit] After the open Note is saved, the Link map updates; Backlinks of other Notes change to match.
- [snap] With no Backlinks, the section says “No Backlinks”.
Status: done

### M2-06 Outgoing Links and outline
As a user, I want to see what the open Note links to and its Headings, so that I can jump around a long Note.
Screens: `obsidian-09-outgoing-links-pane.png`, `obsidian-12-outline-pane.png`, `opal-m2-03-inspector-outgoing.png`, `opal-m2-04-inspector-outline.png`
Depends: M2-05
Acceptance:
- [snap] The inspector has three sections in a segmented control: Backlinks, Outgoing, Outline.
- [snap] Outgoing lists each Link target once, Unresolved ones fainter.
- [snap] Outline lists Headings indented by level.
- [manual] Clicking an outline row scrolls the Editor to that Heading. Clicking an Outgoing row follows the Link.
Status: done

### M2-07 Quick Switcher (⌘O)
As a user, I want to open any Note by typing part of its name or Alias, so that I never hunt in the tree.
Screens: `obsidian-07-quick-switcher.png`, `opal-m2-05-quick-switcher.png`
Depends: M2-02
Acceptance:
- [unit] Fuzzy match: the letters of the query, in order, in the name, path or Alias. A match at the start of a word ranks higher; a name match beats a path match.
- [unit] `dirt` finds `Soil` through its Alias (Obsidian misses this by default).
- [unit] With an empty query, recent Notes come first, then the rest by name. Recent Notes are kept in Opal's preferences, never in the Vault.
- [snap] A panel over the window: a search field and a list with name, Folder, and the Alias when it matched.
- [manual] ↑ ↓ move, Return opens, Esc closes. With no match, Return creates a Note with the typed name (placed as in M1-07).
- Later: ⌘Return opens in a new tab, when tabs exist (M5-06).
Status: done

### M2-08 Changes from outside
As a user who also uses Obsidian, git or a sync tool, I want Opal to show their changes without ⌘R.
Depends: M2-05
Acceptance:
- [unit] Files added, removed or changed outside Opal appear in the tree within a second (FSEvents, [ADR 0003](adr/0003-fsevents-dispatch-queue-exception.md)).
- [unit] An open Note with no unsaved edits reloads with the text on disk.
- [unit] An open Note with unsaved edits is not touched; saving then follows M1-11.
- [unit] Opal's own saves cause no reload and no conflict.
- [unit] Changes in hidden Folders (`.obsidian/`, `.git/`) are ignored.
- [unit] The Link map updates for each changed Note.
Status: done

### M2-09 Link suggestions (`[[`)
As a user, I want a list of Notes while I type a Link, so that I link without spelling the name exactly.
Screens: `obsidian-14-link-suggestions.png`, `opal-m2-06-link-suggestions.png`
Depends: M2-07
Acceptance:
- [unit] Typing `[[` and a query lists Notes and Aliases by the M2-07 match, plus Unresolved targets already used in the Vault.
- [snap] The list shows under the cursor, like the system completion list.
- [manual] ↑ ↓ choose, Return or Tab inserts, Esc closes. The insert is one undo step.
- [unit] The inserted Link is the shortest path that resolves to the chosen Note; an Alias inserts `[[Note|Alias]]`; `useMarkdownLinks: true` inserts `[Name](path.md)` with spaces as `%20`.
- Later: `#` Headings and `^` Blocks of the chosen Note inside `[[`.
Status: done

### M2-10 Back and forward
As a user who follows Links, I want to go back to the Note I came from.
Depends: M2-03
Acceptance:
- [unit] Opening a Note (by Link, tree, Quick Switcher or Backlink) pushes the last Note on a back list and clears forward.
- [snap] Toolbar back and forward buttons, enabled only when there is somewhere to go.
- [manual] ⌘[ and ⌘] go back and forward.
Status: done

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
