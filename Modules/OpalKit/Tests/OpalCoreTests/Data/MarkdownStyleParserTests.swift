//
//  MarkdownStyleParserTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("MarkdownStyleParser", .tags(.parser))
struct MarkdownStyleParserTests {
    // MARK: - Blocks

    @Test("styles a Heading by level and marks its hashes", arguments: [("# Soil", 1), ("### Soil", 3), ("###### Soil", 6)])
    func heading(text: String, level: Int) {
        let runs = styled(text)
        #expect(runs.contains { $0 == (text, .heading(level: level)) })
        #expect(runs.contains { $0 == (String(repeating: "#", count: level) + " ", .mark) })
    }

    @Test("styles quotes and marks the bar")
    func quote() {
        let runs = styled("> Keep the soil covered.")
        #expect(runs.contains { $0 == ("> Keep the soil covered.", .quote) })
        #expect(runs.contains { $0 == ("> ", .mark) })
    }

    @Test("styles a callout and the quote lines that follow it")
    func callout() {
        let runs = styled("> [!tip] Mulch\n> Two inches.\nAfter")
        #expect(runs.contains { $0 == ("> [!tip] Mulch", .callout) })
        #expect(runs.contains { $0 == ("[!tip]", .mark) })
        #expect(runs.contains { $0 == ("Mulch", .calloutTitle) })
        #expect(runs.contains { $0 == ("> Two inches.", .callout) })
        #expect(runs.contains { $0.0 == "After" } == false)
    }

    @Test("styles list markers and checkboxes")
    func lists() {
        let runs = styled("- one\n1. two\n- [ ] sow\n- [x] water\n* [X] weed")
        #expect(runs.filter { $0.1 == .listMarker }.map(\.0) == ["-", "1.", "-", "-", "*"])
        #expect(runs.filter { if case .checkbox = $0.1 { true } else { false } }.map(\.1) == [
            .checkbox(isDone: false), .checkbox(isDone: true), .checkbox(isDone: true)
        ])
    }

    @Test("styles a horizontal rule but not frontmatter delimiters")
    func rule() {
        let runs = styled("---\ntags: a\n---\nText\n\n***\n")
        #expect(runs.contains { $0 == ("---\ntags: a\n---", .frontmatter) })
        #expect(runs.filter { $0.1 == .horizontalRule }.map(\.0) == ["***"])
    }

    @Test("styles code blocks and nothing inside them")
    func codeBlock() {
        let runs = styled("```swift\n# not a heading **bold** #tag [[Soil]]\n```\nAfter")
        #expect(runs.filter { $0.1 == .codeBlock }.map(\.0) == ["```swift", "# not a heading **bold** #tag [[Soil]]", "```"])
        #expect(runs.allSatisfy { [.codeBlock, .mark].contains($0.1) })
    }

    // MARK: - Inline

    @Test(
        "styles emphasis and marks its delimiters",
        arguments: [
            ("**rich**", "rich", [TextStyleKind.bold], "**"),
            ("__rich__", "rich", [.bold], "__"),
            ("*rich*", "rich", [.italic], "*"),
            ("_rich_", "rich", [.italic], "_"),
            ("***rich***", "rich", [.bold, .italic], "***"),
            ("~~rich~~", "rich", [.strikethrough], "~~"),
            ("==rich==", "rich", [.highlight], "==")
        ]
    )
    func emphasis(text: String, inner: String, kinds: [TextStyleKind], marks: String) {
        let runs = styled("A \(text) loam")
        #expect(runs.filter { $0.0 == inner }.map(\.1) == kinds)
        #expect(runs.filter { $0.1 == .mark }.map(\.0) == [marks, marks])
    }

    @Test("does not style emphasis inside words, code or Link targets")
    func emphasisEdges() {
        let runs = styled("snake_case_name `**code**` [[my_garden_note]] 2 * 3 * 4")
        #expect(runs.contains { [.bold, .italic].contains($0.1) } == false)
        #expect(runs.contains { $0 == ("`**code**`", .inlineCode) })
    }

    @Test("styles inline code and marks its backticks")
    func inlineCode() {
        let runs = styled("Use ``a ` b`` here")
        #expect(runs.contains { $0 == ("``a ` b``", .inlineCode) })
        #expect(runs.filter { $0.1 == .mark }.map(\.0) == ["``", "``"])
    }

    @Test("marks the brackets of Links and Embeds, and the target of an aliased Link")
    func linkMarks() {
        #expect(marks("[[Soil]]") == ["[[", "]]"])
        #expect(marks("![[seedlings.png]]") == ["![[", "]]"])
        #expect(marks("[[Projects/Opal Roadmap|roadmap]]") == ["[[", "]]", "Projects/Opal Roadmap|"])
        #expect(marks("[rich earth](Soil.md)") == ["[", "](Soil.md)"])
        #expect(marks("![photo](seedlings.png)") == ["![", "](seedlings.png)"])
    }

    @Test("styles Tags outside code")
    func tags() {
        let runs = styled("#garden/harvest and `#code` and #123")
        #expect(runs.filter { $0.1 == .tag }.map(\.0) == ["#garden/harvest"])
    }

    @Test("marks a Block id")
    func blockID() {
        #expect(marks("Compost weekly. ^compost-rule") == ["^compost-rule"])
    }

    // MARK: - Bounds

    @Test("every run stays inside the text", arguments: [
        "# H\n**b** *i* ==h== ~~s~~ `c` [[L|a]] #t\n> [!note] T\n> q\n- [ ] x\n```\ncode\n```\n---\n",
        "**unclosed *also `open [[link",
        "\r\n# Windows\r\n> quote\r\n",
        "---\nunclosed: frontmatter\n"
    ])
    func bounds(text: String) {
        let length = text.utf16.count
        #expect(MarkdownStyleParser.runs(in: text, parsed: MarkdownNoteParser.parse(text)).allSatisfy {
            $0.span.location >= 0 && $0.span.length > 0 && $0.span.upperBound <= length
        })
    }

    // MARK: - Helpers

    private func styled(_ text: String) -> [(String, TextStyleKind)] {
        let nsText = text as NSString
        return MarkdownStyleParser.runs(in: text, parsed: MarkdownNoteParser.parse(text)).map {
            (nsText.substring(with: NSRange(location: $0.span.location, length: $0.span.length)), $0.kind)
        }
    }

    private func marks(_ text: String) -> [String] {
        styled(text).filter { $0.1 == .mark }.map(\.0)
    }
}
