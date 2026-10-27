# Opal glossary

Use these terms in code, docs, issues and tests. Do not use the _Avoid_ words.

| Term | Meaning | Avoid |
| --- | --- | --- |
| **Vault** | A folder on disk that the user opens in Opal. Every Note and Attachment in it, at any depth, belongs to it. An Obsidian vault is a Vault. | workspace, library, database |
| **Note** | One Markdown file (`.md`) in the Vault. Its name is the file name without `.md`. | page, document, entry, file (when you mean a Note) |
| **Attachment** | Any file in the Vault that is not a Note: an image, a PDF, audio, video. | asset, media, resource |
| **Folder** | A folder inside the Vault. | directory (in UI copy), collection |
| **Link** | A reference from one Note to a Note or an Attachment: a wikilink `[[Name]]`, `[[Name\|alias]]`, `[[Name#Heading]]`, `[[Name#^block]]`, or a Markdown link `[text](path.md)`. | reference, wikiref |
| **Embed** | A Link that shows the target inside the Note: `![[Name]]`. | transclusion, include |
| **Backlink** | A Link seen from its target: the Notes that link to this Note. | inbound link, mention (when it is a Link) |
| **Unlinked mention** | Text in a Note that matches another Note's name or alias but is not a Link. | |
| **Unresolved Link** | A Link whose target does not exist yet. Following it creates the Note. | broken link, dead link |
| **Heading** | A Markdown heading line. A Link can point at one. | section (in code) |
| **Block** | A paragraph or list item with a `^id`. A Link can point at one. | |
| **Tag** | `#name` in the body, or an entry in the `tags` Property. Nested with `/`, as in `#project/opal`. | label, category |
| **Property** | One key and value in a Note's YAML frontmatter. `aliases` and `tags` are Properties with special meaning. | metadata, field, attribute |
| **Alias** | Another name for a Note, from its `aliases` Property. Links and the Quick Switcher match it. | nickname |
| **Daily Note** | The Note for one date, named and placed by the Daily Note settings (Obsidian's `daily-notes.json` when present). | journal entry |
| **Template** | A Note whose content seeds a new Note. | snippet, boilerplate |
| **Index** | Opal's derived store of Notes, Links, Tags, Properties and search text. Built from the Vault. Can be deleted and rebuilt with no loss. | cache (when you mean the Index), database |
| **Editor** | The view that edits one Note's Markdown text. | composer |
| **Reading view** | A Note rendered, not editable. | preview mode |
| **Quick Switcher** | The keyboard panel that opens a Note by name or Alias. | finder, launcher |
| **Command Palette** | The keyboard panel that runs any command by name. | action menu |
| **Graph** | A view of Notes as points and Links as lines. Not in v1. | map, network |
