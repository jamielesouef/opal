# Opal

Opal is a native macOS note-taking app. It is an alternative to Obsidian. It opens a Vault (a folder of Markdown files), lets the user write and link Notes, and finds anything in the Vault fast. It works on existing Obsidian Vaults as they are: the files on disk stay the user's, and Obsidian can still open them.

## Sources of truth

Read the one that matches the task before writing code. When they disagree with code on the branch, the code on `HEAD` wins for what exists; these docs win for what should exist.

| Need | Read |
|---|---|
| Vocabulary (Vault, Note, Link, Backlink, Tag, Property, Index…) | `GLOSSARY.md` — use its terms, never its _Avoid_ words |
| Why a hard-to-reverse choice was made | `docs/adr/` (add an ADR when you make one) |
| Layer rules | `docs/architecture.md` |
| Opal's planned modules and deliberate constraints | `ARCHITECTURE.md` |
| File shapes and test shapes | `docs/templates/README.md` and the templates beside it |
| What a screen looks like | `docs/design-brief.md` |

## Toolchain

- Use `xcrun swift` and `xcodebuild`. The `swift` on `PATH` can be an older toolchain and give different results.
- Generate the Xcode project from `project.yml` with `xcodegen generate`. Edit `project.yml`, never the `.xcodeproj` by hand.
- Shared code lives in the local package `Modules/OpalKit`. Not `Packages/`: a common `.gitignore` ignores that name.
- `.swiftformat` and `.swiftlint.yml` are authoritative once they exist. Never weaken them to make a check pass.

## Rules that bite

- Swift 6, complete strict concurrency, typed throws, exhaustive switches, one type per file with `// MARK: -` sections, no prefix `!`, no `print` (use `AppLog`), no comments inside bodies.
- Every `.swift` file starts with the Xcode header, author `Jamie Le Souef`, project `Opal`, date `DD/MM/YYYY`.
- MV: state lives in `@MainActor @Observable` services. No view models, `ObservableObject`, `@Published`, Combine or `DispatchQueue`.
- The Vault on disk is the source of truth. Opal's Index is derived from the files and can always be deleted and rebuilt. Never store a fact only in the Index.
- Opal writes a Note only when the user edits it, or when the user confirms an action that changes it (for example, a rename that updates Links). Opal never reformats a file it did not change.
- Opal never writes inside `.obsidian/`. It may read it.
- Keep Obsidian syntax: `[[Links]]`, `[[Note|alias]]`, `[[Note#Heading]]`, `![[Embeds]]`, `#tags`, YAML frontmatter Properties and `aliases`.
- Swift Testing only. Parsers and use cases: text in, values out. Vault code: a fixture Vault copied into a temporary folder.

## Never touch real user data

Tests and acceptance runs never open or write to a real Vault. Copy a fixture Vault into a temporary folder and point Opal at that. Point the Index and settings folders at a temporary folder too: tests never write to `~/Library/Application Support/Opal/` or the app's real `UserDefaults` domain. Fixtures copied from a real Vault must have personal content removed.
