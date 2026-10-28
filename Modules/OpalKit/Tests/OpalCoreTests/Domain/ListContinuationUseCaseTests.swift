//
//  ListContinuationUseCaseTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("ListContinuationUseCase")
struct ListContinuationUseCaseTests {
    // MARK: - Helpers

    private func pressReturn(_ text: String) -> String? {
        let cursor = (text as NSString).range(of: "|").location
        let plain = (text as NSString).replacingCharacters(in: NSRange(location: cursor, length: 1), with: "")
        guard let edit = ListContinuationUseCase.newline(in: plain, cursor: cursor) else {
            return nil
        }
        let range = NSRange(location: edit.span.location, length: edit.span.length)
        return (plain as NSString).replacingCharacters(in: range, with: edit.replacement + "|")
    }

    // MARK: - Tests

    @Test(
        "Return in a list item starts the next item",
        arguments: [
            ("- one|", "- one\n- |"),
            ("* one|\n* two", "* one\n* |\n* two"),
            ("  - nested|", "  - nested\n  - |"),
            ("1. first|", "1. first\n2. |"),
            ("9) ninth|", "9) ninth\n10) |"),
            ("- [x] done|", "- [x] done\n- [ ] |"),
            ("> - quoted|", "> - quoted\n> - |"),
            ("- spl|it", "- spl\n- |it")
        ]
    )
    func continues(before: String, after: String) {
        #expect(pressReturn(before) == after)
    }

    @Test(
        "Return on an empty item ends the list",
        arguments: [
            ("- one\n- |", "- one\n|"),
            ("1. one\n2. |\nafter", "1. one\n|\nafter"),
            ("- [ ] |", "|")
        ]
    )
    func ends(before: String, after: String) {
        #expect(pressReturn(before) == after)
    }

    @Test("Return outside a list item, or inside its marker, is a plain newline", arguments: ["plain|", "|- one", "-|one", "#| heading"])
    func plain(text: String) {
        #expect(pressReturn(text) == nil)
    }
}
