# 0005 — Reading view is native SwiftUI, built from Opal's own parse

Date: 28/10/2026. Status: accepted (chosen by the user).

## Context

M4-02 needs the open Note rendered and not editable, with tables, callouts and code with syntax colour. The design brief also lists maths (`$…$`). The options put to the user were:

1. SwiftUI views and `AttributedString`, built from the same parse as live Markdown (M4-01).
2. HTML in a `WKWebView`, from a Markdown-to-HTML renderer, with KaTeX bundled for maths.

## Decision

Reading view is SwiftUI. A pure parser in Data (`MarkdownReadingParser`) turns the Note's text, its `ParsedNote` and its style runs into reading blocks: Headings, paragraphs, list items, quotes, callouts, tables, code blocks and rules. Presentation draws each block with native views and builds inline text as an `AttributedString`. Code colour comes from Opal's own small tokenizer (`CodeTokenizer`): keywords, strings, numbers and comments for Swift, Python, JavaScript, JSON, YAML and shell.

## Consequences

- No new dependency and no web view. Text selection, fonts, Dynamic Type, dark mode and accessibility work the way they do in every native view.
- Reading view and the Editor read one parse, so Links, Tags and Headings cannot disagree between the two.
- Maths is not rendered. `$$…$$` blocks show as code and inline `$…$` shows as written. Adding maths later means a native maths renderer or a small web view for maths blocks only, which needs a new ADR.
- The code colours are simpler than a full grammar (no type inference, no nested string templates). That is enough for reading; the Editor stays plain monospace.
- HTML was not chosen. It would have given maths and code colour almost for free, but it adds a renderer dependency and a web view that does not behave like the rest of the app.
