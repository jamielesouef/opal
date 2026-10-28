# Opal user stories

Stories for Opal v1, grouped into milestones. Vocabulary follows [GLOSSARY.md](../GLOSSARY.md). The reference screens of Obsidian are indexed in [screens/README.md](screens/README.md); the design is set by [design-brief.md](design-brief.md).

The user is someone who writes a lot and links their Notes. Some already keep an Obsidian Vault.

Each story has acceptance criteria. A story is done when its criteria pass in tests (Domain, parsers, Data and Services) or in a run against a fixture Vault copied to a temporary folder (Presentation).

## Milestones

| Milestone | Goal | Stories |
| --- | --- | --- |
| **M1 — Open a Vault and write a Note** (built 27/10/2026) | Open an existing Obsidian Vault or a new one, browse it, and write in a Note safely | M1-01 … M1-11 |
| **M2 — Links** (built 27/10/2026) | Follow Links, see Backlinks, find Notes by name | M2-01 … M2-10 |
| **M3 — Find** (built 27/10/2026) | The Index, full-text Search, Tags, unlinked mentions | M3-01 … M3-06 |
| **M4 — Rich Editor** (built 28/10/2026) | Live Markdown, Reading view, Properties, Embeds | M4-01 … M4-06 |
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

The Index is a SQLite database read and written through GRDB ([ADR 0004](adr/0004-index-in-sqlite-with-grdb.md)). It lives in Opal's Application Support folder, one per Vault, never in the Vault. It holds only what Opal can read again from the files.

### M3-01 Keep an Index of the Vault
As a user with a big Vault, I want Opal to remember what it read, so that reopening the Vault is fast.
Depends: M2-08
Acceptance:
- [unit] The Index stores, per Note: path, modification date, size, parsed Links, Headings, Blocks, Aliases, Tags, and the text for search.
- [unit] Opening a Vault compares each Note's date and size with the Index and reads only the Notes that changed, were added or were removed.
- [unit] Deleting the Index folder loses nothing: the next open rebuilds it with the same content.
- [unit] An Index with an older schema version is deleted and rebuilt.
- [unit] Changes from outside (M2-08) and Opal's own saves update the Index.
- [unit] Tests and acceptance runs point the Index at a temporary folder (`-OpalIndexFolder`).
- [snap] While the Index is built, the sidebar foot shows “Indexing 120 of 2,000 Notes…”.
Status: done

### M3-02 The Link map reads the Index
As a user, I want Backlinks ready as soon as the Vault opens, without Opal reading every Note again.
Depends: M3-01
Acceptance:
- [unit] `LinkService` builds the Link map from the parsed Notes in the Index; it reads no Note file when nothing changed.
- [unit] All M2 Link tests still pass.
Status: done

### M3-03 Tags
As a user, I want Opal to know my Tags, so that I can find Notes by topic.
Depends: M3-01
Acceptance:
- [unit] Tags come from `#tag` in the body (not in code, not in a Heading's `#`, not `#123`, not a URL fragment) and from the `tags` Property as a list, an inline list or one value.
- [unit] Tags nest by `/`: `#garden/harvest` counts for `garden` and `garden/harvest`. Case is ignored when counting; the first spelling seen is shown.
- [snap] The sidebar has a Tags section: a tree of Tags with Note counts (`obsidian-10`).
- [manual] Choosing a Tag searches for `tag:#name`.
- Later (with M4-03 Properties): the open Note's own Tags in the inspector, which the design brief lists.
Status: done

### M3-04 Search (⇧⌘F)
As a user, I want to find any word in my Vault, so that I can find a Note I half remember.
Screens: `obsidian-13-search.png`
Depends: M3-01, M3-03
Acceptance:
- [unit] The query parser reads words, quoted phrases, `path:`, `file:`, `tag:` and `-word` (exclude). Unknown operators are searched as words.
- [unit] All words must match (AND). Results are grouped by Note, best first, with up to 3 lines in context per Note and the matched words marked.
- [unit] Search works on a 10,000-Note Index in under 100 ms.
- [snap] ⇧⌘F shows Search in the sidebar, above the Folder tree; results update as you type.
- [manual] Clicking a result opens the Note at that line.
- Later (with M4-03 Properties): `[property:value]` search, which the design brief lists.
Status: done

### M3-05 Unlinked mentions
As a user, I want to see Notes that mention this Note without linking it, so that I can link them.
Screens: `obsidian-08-backlinks-and-unlinked-mentions.png`
Depends: M3-04
Acceptance:
- [unit] For the open Note, the Index finds other Notes whose text contains its name or an Alias as whole words, outside code and outside existing Links.
- [snap] The Backlinks tab shows “Unlinked mentions” below the Backlinks, with the line in context.
- [unit] **Link** asks first, then rewrites only that mention to `[[Name]]` (or `[[Name|Alias]]`), writes that Note atomically, and changes nothing else in it.
Status: done

### M3-06 Large Vaults
As a user with 10,000 Notes, I want Opal to stay fast.
Depends: M3-02, M3-04
Acceptance:
- [unit] A generated 10,000-Note Vault: first index under 20 s, reopen with no changes under 1 s, Search under 100 ms (Release build, this Mac).
- [manual] Typing in a 1 MB Note does not stutter (open-Note parsing is off the main actor since the 27/10/2026 review).
Status: done (measured 27/10/2026, Release: first index 5.6 s, reopen 0.54 s, Search 20 ms; the [manual] typing check is yours)

## M4 — Rich Editor

Styling is a view of the text, never a change to it. The Editor stays a plain-text `NSTextView` on TextKit 2 ([ADR 0002](adr/0002-textkit-2-editor.md)): fonts and colours are text storage attributes, which change neither `string` nor the undo stack. Opal writes a Note only when the user edits it (M4-03, M4-05 and M4-06 are edits). The styled ranges are computed with the open Note's Links, off the main actor for large Notes (the 27/10/2026 review), and the Editor maps each style kind to attributes in one place (the 28/10/2026 review). The Editor styles only the text near what is on screen (10,000 characters either side) and styles more as you scroll, so a 1 MB Note costs about 7 ms per restyle instead of 1.3 s.

### M4-01 Live Markdown
As a writer, I want the Markdown styled as I type, so that the Note reads well while I write it.
Screens: `obsidian-03-note-live-preview.png`
Depends: M2-06, M3-03
UX: Marks fade but never hide, so the text never reflows when the cursor moves. Only their colour changes, faint elsewhere and full strength on the cursor's line. The toggle is in the View menu, above Toggle Inspector, with no shortcut. It is kept in Opal's preferences, never in the Vault.
Acceptance:
- [unit] The parser returns style runs for Headings (levels 1–6), bold, italic, bold italic, strikethrough, highlight (`==text==`), inline code, code blocks, quotes, list markers, checkboxes, callouts (`> [!note] Title`), horizontal rules, Links, Embeds and Tags. Each run has a span and a kind, and the marks (`#`, `**`, `` ` ``, `[[`, `]]`) are their own runs.
- [unit] Nothing is styled inside code or frontmatter except as code or frontmatter. Runs never overlap the text's end after an edit.
- [unit] `TextStyleRun` replaces `LinkHighlight`; resolved and Unresolved Links keep their M2-04 colours.
- [snap] A fixture Note with every kind above, light and dark: Headings are larger and bold, code is monospaced on a tinted background, quotes and callouts have a bar, Tags are tinted.
- [snap] Marks are faint on lines without the cursor and full strength on the cursor's line. The text never moves sideways when the cursor changes line.
- [unit] Styling a 1 MB Note does no parsing on the main actor (the M3-06 rule).
- [manual] View › Live Markdown (no shortcut) turns styling off and on. With it off, the Editor is plain text except for Link colours, which ⌘-click needs (M2-04). The choice is kept outside the Vault.
- [manual] Scroll through a 1 MB Note: the text further down is styled as it comes into view.
Status: done (28/10/2026; `MarkdownStyleParserTests`, snapshots `opal-m4-01-*`; the two [manual] lines are yours)

### M4-02 Reading view (⌘E)
As a reader, I want the Note rendered and not editable, so that I can read it without the marks.
Screens: `obsidian-04-note-reading-view.png`
Depends: M4-01
Decided in [ADR 0005](adr/0005-reading-view-in-swiftui.md): native SwiftUI and `AttributedString`, built from the M4-01 parse; no maths.
Acceptance:
- [unit] The rendered blocks come from the same parse as M4-01: Headings, paragraphs, lists, checkboxes, quotes, callouts, tables, code blocks, horizontal rules, Links and Embeds.
- [manual] ⌘E and the toolbar's Editor / Reading control switch views; the scroll position stays on the same Heading. (The snapshot cannot show the toolbar.)
- [snap] Tables have columns and a header row; code blocks have syntax colour for at least Swift, Python, JavaScript, JSON, YAML and shell; callouts show their type's icon and title.
- [snap] `$…$` and `$$…$$` show as maths, or, if ADR 0005 drops maths, as code, with a note in the story.
- [manual] Clicking a Link follows it (M2-03); Heading Links read `Note > Heading`.
- [unit] Reading view never writes the Note.
Status: done (28/10/2026; `MarkdownReadingParserTests`, `CodeTokenizerTests`, `ReadingViewTests`, snapshots `opal-m4-02-*`). Per ADR 0005, maths is not rendered: `$$…$$` blocks show as code and inline `$…$` as written. For you to check [manual]: clicking a Link, and the scroll position when you switch with ⌘E.

### M4-03 Properties
As a user, I want my Note's Properties as a small form, so that I can read and change them without editing YAML.
Screens: `obsidian-03-note-live-preview.png`, `obsidian-11-all-properties-pane.png`
Depends: M4-01
Acceptance:
- [unit] A frontmatter parser reads text, number, checkbox, date, date-and-time and list Properties, and keeps the exact source lines of each one. Unreadable YAML is shown as YAML, never rewritten.
- [unit] Changing one Property rewrites only that Property's lines; every other byte of the Note, including key order, quotes, comments and line endings, is unchanged. Adding a Property appends it; removing one removes only its lines.
- [unit] Types are inferred per Property name across the Vault, from the Index, as Obsidian does (`.obsidian/types.json` is read when present, never written).
- [snap] The form sits above the text, below the Note's name: a row per Property with an icon for its type, an Add Property button, and a way to edit the frontmatter as YAML.
- [manual] The inspector shows the open Note's Tags (from M3-03's Later line).
- [unit] Search reads `[property:value]` (from M3-04's Later line).
- Later: types inferred across the whole Vault from the Index, and `[property:value]` search. Both need Property values in the Index, which means a schema change, so they are a story of their own.
- Later: hide the frontmatter in the Editor while the form shows it. For now the Editor still shows it as faint YAML, and that is where **Edit as YAML** puts the cursor.
Status: done (28/10/2026; `FrontmatterParserTests`, `PropertyServiceTests`, `opal-m4-03-properties.png`). Types come from the value, the name (`tags`, `aliases`) and `.obsidian/types.json`. The inspector has a Tags tab for the open Note. Editing in the form is [manual] and yours to check.

### M4-04 Embeds
As a user, I want Embeds shown inline, so that I can see the embedded Note, image or PDF where it is used.
Screens: `obsidian-03-note-live-preview.png`
Depends: M4-01, M4-02
Acceptance:
- [unit] `![[Note]]`, `![[Note#Heading]]`, `![[Note#^block]]`, `![[image.png]]`, `![[image.png|300]]`, `![[file.pdf]]` and `![alt](image.png)` resolve with the M2-02 rules; the Heading form takes the text up to the next Heading of the same or a higher level.
- [snap] In Reading view ([ADR 0006](adr/0006-embeds-only-in-reading-view.md): never in the Editor, which shows the Embed as styled text), Embeds show below their line: a Note or a Heading’s text in a bordered box with its name, an image at its size or the width given, a PDF as a scrollable page view.
- [snap] An Unresolved Embed shows “‘name’ is not in this Vault” with a create action.
- [unit] An Embed of a Note that embeds itself, directly or through others, stops after one level and says so.
- [manual] Changing the embedded Note elsewhere updates the Embed.
Status: done (28/10/2026; `EmbedTests`, snapshots `opal-m4-04-*`). In the snapshot a PDF shows as a blank page because `cacheDisplay` does not draw PDFKit; check it [manual]. If a Note is already shown higher up, Opal says so instead of embedding it again. Embeds also stop at four levels deep.

### M4-05 Checkboxes
As a user, I want to tick a task with one click, so that I do not have to type the `x`.
Screens: `obsidian-03-note-live-preview.png`
Depends: M4-01
Acceptance:
- [unit] Toggling a checkbox changes only the one character between `[` and `]` (space to `x`, `x` or `X` to space) and nothing else in the line or the Note.
- [snap] With live Markdown on, `- [ ]` and `- [x]` show as checkboxes; done tasks are struck through and faint. Reading view shows the same.
- [manual] Clicking the checkbox toggles it; the toggle is one undo step and is saved like any edit.
- Later: draw a checkbox in place of the `[ ]` brackets in the Editor. In Reading view, clicking a checkbox toggles it as well (`NoteService.toggleCheckbox(onLine:)`).
Status: done (28/10/2026; `CheckboxToggleUseCaseTests`, `opal-m4-05-checkboxes.png`; clicking is [manual] and yours to check)

### M4-06 Paste and drop images
As a user, I want to paste or drop an image into a Note, so that I can add it without the Finder.
Depends: M4-04
Acceptance:
- [unit] The Attachment's place follows `attachmentFolderPath` from `.obsidian/app.json` (Vault root, a named Folder, the Note's Folder, or a subfolder of it) and Opal's own setting when there is no `app.json`.
- [unit] The name is `Pasted image YYYYMMDDHHmmss.png` for a paste and the file's own name for a drop; a name that is taken gets ` 1`, ` 2`… The file is written atomically and never replaces an existing file.
- [unit] The Embed `![[name.png]]` is inserted at the cursor (or the drop point) as one undo step, using the shortest Link form the Vault's `newLinkFormat` asks for.
- [manual] Paste from Screenshot and drag from Finder both work; the image shows in Reading view (M4-04).
Status: done (28/10/2026; `AttachmentUseCaseTests`, `AttachmentServiceTests`). Only image files are attached; other dropped or pasted files keep the Editor's usual behaviour. Paste and drag are [manual] and yours to check: I could not drive the pasteboard or a drag in the running app.

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
