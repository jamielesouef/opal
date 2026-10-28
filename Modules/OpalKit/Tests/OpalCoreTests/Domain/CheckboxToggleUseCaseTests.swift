//
//  CheckboxToggleUseCaseTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("CheckboxToggleUseCase")
struct CheckboxToggleUseCaseTests {
    // MARK: - Toggle

    @Test(
        "changes only the character between the brackets",
        arguments: [
            ("- [ ] Sow **peas** [[Soil]]", "- [x] Sow **peas** [[Soil]]"),
            ("- [x] Water", "- [ ] Water"),
            ("- [X] Weed", "- [ ] Weed"),
            ("  1. [ ] Nested\r\n", "  1. [x] Nested\r\n"),
            ("> - [ ] In a quote", "> - [x] In a quote")
        ]
    )
    func toggles(text: String, expected: String) throws {
        let styles = MarkdownStyleParser.runs(in: text, parsed: MarkdownNoteParser.parse(text))
        let box = try #require(styles.first { $0.kind.isCheckbox })
        let toggle = try #require(CheckboxToggleUseCase.toggle(at: box.span.location + 1, in: styles))
        let result = (text as NSString).replacingCharacters(in: NSRange(location: toggle.span.location, length: toggle.span.length), with: toggle.replacement)
        #expect(result == expected)
    }

    @Test("does nothing away from a checkbox", arguments: ["- [ ] Sow", "Text [ ] not a task", "`- [ ] code`"])
    func ignores(text: String) {
        let styles = MarkdownStyleParser.runs(in: text, parsed: MarkdownNoteParser.parse(text))
        let offsets = text.hasPrefix("- [") ? [0, 6] : Array(0 ..< text.utf16.count)
        #expect(offsets.allSatisfy { CheckboxToggleUseCase.toggle(at: $0, in: styles) == nil })
    }

    @Test("strikes the rest of a done task")
    func doneTask() {
        let text = "- [x] Water the tomatoes"
        let runs = MarkdownStyleParser.runs(in: text, parsed: MarkdownNoteParser.parse(text))
        let done = runs.first { $0.kind == .doneTask }
        #expect(done.map { (text as NSString).substring(with: NSRange(location: $0.span.location, length: $0.span.length)) } == " Water the tomatoes")
    }
}
