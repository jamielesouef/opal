//
//  MarkdownReadingParserTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("MarkdownReadingParser", .tags(.parser))
struct MarkdownReadingParserTests {
    // MARK: - Blocks

    @Test("reads each kind of block from the same parse as the Editor")
    func blockKinds() {
        let text = """
        ---
        tags: [a]
        ---
        # Title
        A paragraph
        on two lines.

        > A quote

        > [!warning] Careful
        > Hot pots.

        - one
          - [x] nested done
        1. first

        | Plant | Water |
        | --- | :-: |
        | Peas | **daily** |

        ```swift
        let a = 1
        ```

        ---
        """
        let kinds = blocks(text).map(\.kind)
        #expect(kinds.count == 10)
        #expect(kinds[0] == .heading(level: 1, text: [ReadingInline(text: "Title")]))
        #expect(kinds[1] == .paragraph([ReadingInline(text: "A paragraph"), ReadingInline(text: "\n"), ReadingInline(text: "on two lines.")]))
        #expect(kinds[3] == .callout(type: "warning", title: [ReadingInline(text: "Careful", styles: [.bold])], lines: [[ReadingInline(text: "Hot pots.")]]))
        #expect(kinds[4] == .listItem(marker: "•", depth: 0, checkbox: nil, text: [ReadingInline(text: "one")]))
        #expect(kinds[5] == .listItem(marker: "•", depth: 1, checkbox: true, text: [ReadingInline(text: "nested done", styles: [.strikethrough])]))
        #expect(kinds[6] == .listItem(marker: "1.", depth: 0, checkbox: nil, text: [ReadingInline(text: "first")]))
        #expect(kinds[7] == .table(
            header: [[ReadingInline(text: "Plant")], [ReadingInline(text: "Water")]],
            rows: [[[ReadingInline(text: "Peas")], [ReadingInline(text: "daily", styles: [.bold])]]]
        ))
        #expect(kinds[8] == .code(language: "swift", text: "let a = 1"))
        #expect(kinds[9] == .rule)
    }

    @Test("a block's line is where it starts, for scrolling to it")
    func lines() {
        #expect(blocks("# A\n\ntext\n\n## B").map(\.line) == [0, 2, 4])
    }

    // MARK: - Inline

    @Test("drops marks and keeps emphasis, code and Tags")
    func inline() {
        let inlines = paragraph("A **rich** *soil* `pH 7` with #compost")
        #expect(inlines == [
            ReadingInline(text: "A "),
            ReadingInline(text: "rich", styles: [.bold]),
            ReadingInline(text: " "),
            ReadingInline(text: "soil", styles: [.italic]),
            ReadingInline(text: " "),
            ReadingInline(text: "pH 7", styles: [.code]),
            ReadingInline(text: " with "),
            ReadingInline(text: "#compost", styles: [.tag])
        ])
    }

    @Test(
        "shows a Link by its alias, its name, or Note > Heading",
        arguments: [
            ("[[Soil]]", "Soil"),
            ("[[Soil|rich earth]]", "rich earth"),
            ("[[Tomatoes#Watering]]", "Tomatoes > Watering"),
            ("[[#Harvest]]", "Harvest"),
            ("[earth](Soil.md)", "earth")
        ]
    )
    func links(text: String, shown: String) throws {
        let link = try #require(paragraph("See \(text).").first { $0.link != nil })
        #expect(link.text == shown)
    }

    @Test("marks an Unresolved Link")
    func unresolved() throws {
        let text = "[[Nowhere]]"
        let parsed = MarkdownNoteParser.parse(text)
        let styles = [TextStyleRun(span: TextSpan(location: 0, length: 11), kind: .link(isResolved: false))]
            + MarkdownStyleParser.runs(in: text, parsed: parsed)
        guard case let .paragraph(inlines) = MarkdownReadingParser.blocks(in: text, parsed: parsed, styles: styles).first?.kind else {
            Issue.record("No paragraph")
            return
        }
        #expect(inlines.first?.isResolved == false)
    }

    // MARK: - Helpers

    private func blocks(_ text: String) -> [ReadingBlock] {
        let parsed = MarkdownNoteParser.parse(text)
        return MarkdownReadingParser.blocks(in: text, parsed: parsed, styles: MarkdownStyleParser.runs(in: text, parsed: parsed))
    }

    private func paragraph(_ text: String) -> [ReadingInline] {
        guard case let .paragraph(inlines) = blocks(text).first?.kind else {
            return []
        }
        return inlines
    }
}
