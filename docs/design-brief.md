# Opal design brief

Brief for designing the Opal interface. Vocabulary follows [GLOSSARY.md](../GLOSSARY.md).

## What Opal is

A native macOS app (macOS 26 and later) for writing and linking Notes in a Vault. It is an alternative to Obsidian, and it opens existing Obsidian Vaults as they are.

The user writes a lot and links their Notes. Some already use Obsidian. They want an app that feels like a real Mac app: fast to open, light on memory, and at home with the system. They open Opal to:

1. Write something down now.
2. Find a Note they wrote before.
3. See what links to the Note they are reading.

## Direction

- **A native Mac app.** macOS 26 Liquid Glass: a standard sidebar, a toolbar, system fonts, system colours and the user's accent colour. Follow Apple's Human Interface Guidelines. No custom window chrome.
- **The text comes first.** The Editor is the largest part of the window. Everything else can hide.
- **Calm.** Few borders, few badges, no decoration that is not information.
- **Fast.** Opening a Vault of 10,000 Notes, switching Notes and searching all feel instant.
- **Keyboard first.** Every command is reachable without the mouse, through the Command Palette or a shortcut.
- **Light and dark** follow the macOS setting.

## Window

- **Sidebar** (left, can hide): the Folder tree of the Vault, with Notes and Attachments. Above it: Search and Tags as sections or tabs.
- **Editor** (centre): one Note. Tabs for open Notes. Split view for two Notes side by side.
- **Inspector** (right, can hide): Backlinks, unlinked mentions, outline (Headings), Properties, Tags of this Note.
- **Toolbar**: back and forward, the Note's name and Folder, Editor or Reading view, inspector toggle.
- More than one window is allowed. Each window shows one Vault.

## Editor

- Live Markdown: the syntax is styled as you type, and the marks fade when the cursor is not on them. Reading view shows the Note rendered.
- `[[` opens a suggestion list of Notes, Aliases and Headings. Choosing one inserts the Link.
- ⌘-click a Link to open it. An Unresolved Link looks different, and following it creates the Note.
- Embeds show the target inline: another Note, a Heading, an image or a PDF.
- Properties show as a small form above the text, and can also be edited as YAML.
- Paste or drop an image to save it as an Attachment (place set by Obsidian's attachment setting when present).
- Checkboxes, tables, code blocks with syntax colour, callouts (`> [!note]`), and maths (`$…$`).

## Panels

### Quick Switcher (⌘O)
Find and open a Note by name or Alias. Fuzzy match, recent Notes first. ⌘Return opens in a new tab. No match: Return creates the Note.

### Command Palette (⌘⇧P)
Run any command by name. Shows each command's shortcut. Not ⌘P: macOS keeps that for Print.

### Search (⌘⇧F)
Full-text search across the Vault.
- Results grouped by Note, with the matched text in context.
- Filters: `path:`, `tag:`, `file:`, Property values, and quoted phrases. Same operators as Obsidian where they exist.
- Results update as you type.

### Daily Note
One command or toolbar button opens today's Daily Note, created from its Template when missing. Name, Folder and Template come from the Vault's Obsidian Daily Note settings, or Opal's own.

## Settings

Stored outside the Vault. Nothing the user might want to change is hard-coded.
- **General**: Vaults to open at launch, default Vault.
- **Editor**: font, size, line width, line spacing, spell check, live Markdown on or off.
- **Files and Links**: where new Notes and Attachments go, wikilinks or Markdown links, update Links on rename (ask, always, never).
- **Daily Notes**: Folder, name format, Template.
- **Appearance**: follow system, light, dark.

## States every screen needs

Empty Vault, opening or indexing (with progress), a Note changed on disk while open, a file that cannot be read, and very large (10,000 Notes, Notes of 1 MB).

## First launch

Open a Vault: pick an existing folder (an Obsidian Vault works as is), or create a new one. No account, no sign-in.

## Out of scope for v1

Graph view, Canvas, plugins, sync, publishing, iOS and iPadOS, collaboration.
