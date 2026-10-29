//
//  FrontmatterFoldUseCaseTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("FrontmatterFoldUseCase", .tags(.domain))
struct FrontmatterFoldUseCaseTests {
    // MARK: - Span

    @Test(
        "folds the frontmatter lines up to the start of the body",
        arguments: [
            ("---\ntags: a\n---\n# Body\n", 4, 16),
            ("---\r\ntags: a\r\n---\r\n# Body", 5, 19),
            ("---\na: 1\n...\nBody", 4, 13),
            ("---  \na: 1\n--- \t\nBody", 6, 17),
            ("---\n---\nBody", 4, 8),
            ("---\ntags: a\n---\n", 4, 16),
            ("---\ntags: a\n---", 4, 15),
            ("---\ntitle: 🌱\n---\nBody", 4, 18)
        ]
    )
    func folds(text: String, headingLength: Int, end: Int) {
        #expect(FrontmatterFoldUseCase.fold(in: text) == FrontmatterFold(headingLength: headingLength, end: end))
    }

    @Test("the hidden lines are exactly the frontmatter after its first line")
    func hiddenLines() throws {
        let text = "---\ntitle: 🌱\n---\nBody"
        let fold = try #require(FrontmatterFoldUseCase.fold(in: text))
        let hidden = (text as NSString).substring(with: NSRange(location: fold.hidden.location, length: fold.hidden.length))
        #expect(hidden == "title: 🌱\n---\n")
    }

    @Test(
        "does not fold text that has no closed frontmatter",
        arguments: ["", "Body\n---\n", "---\ntags: a\n", "--- x\na: 1\n---\n", "---", " ---\na: 1\n---\n", "----\na: 1\n----\n"]
    )
    func doesNotFold(text: String) {
        #expect(FrontmatterFoldUseCase.fold(in: text) == nil)
    }

    @Test("agrees with the parser on where the frontmatter ends")
    func agreesWithParser() throws {
        let text = "---\ntags:\n  - a\ncreated: 2026-01-04\n---\n# Body\n"
        let fold = try #require(FrontmatterFoldUseCase.fold(in: text))
        let frontmatter = try #require(FrontmatterParser.parse(text))
        #expect(fold.end == TextLineUseCase.utf16Offset(ofLine: frontmatter.endLine, in: text))
    }

    // MARK: - Selection

    @Test("a caret in the fold moves to the start of the body")
    func caretMoves() {
        let fold = FrontmatterFold(headingLength: 4, end: 19)
        #expect(fold.rule(forSelection: TextSpan(location: 0, length: 0)) == .moveTo(19))
        #expect(fold.rule(forSelection: TextSpan(location: 7, length: 0)) == .moveTo(19))
        #expect(fold.rule(forSelection: TextSpan(location: 19, length: 0)) == .keep)
        #expect(fold.rule(forSelection: TextSpan(location: 40, length: 0)) == .keep)
    }

    @Test("a selection that covers only part of the fold unfolds it")
    func partialSelectionUnfolds() {
        let fold = FrontmatterFold(headingLength: 4, end: 19)
        #expect(fold.rule(forSelection: TextSpan(location: 10, length: 20)) == .unfold)
        #expect(fold.rule(forSelection: TextSpan(location: 2, length: 5)) == .unfold)
    }

    @Test("a selection of the whole Note or clear of the fold leaves it folded")
    func wholeSelectionKeeps() {
        let fold = FrontmatterFold(headingLength: 4, end: 19)
        #expect(fold.rule(forSelection: TextSpan(location: 0, length: 60)) == .keep)
        #expect(fold.rule(forSelection: TextSpan(location: 19, length: 10)) == .keep)
    }

    @Test("folding again moves a caret or selection that touches the frontmatter to the start of the body")
    func refoldMovesSelection() {
        let fold = FrontmatterFold(headingLength: 4, end: 19)
        #expect(fold.selectionAfterFolding(TextSpan(location: 0, length: 0)) == TextSpan(location: 19, length: 0))
        #expect(fold.selectionAfterFolding(TextSpan(location: 12, length: 0)) == TextSpan(location: 19, length: 0))
        #expect(fold.selectionAfterFolding(TextSpan(location: 10, length: 20)) == TextSpan(location: 19, length: 0))
    }

    @Test("folding again leaves a selection in the body where it is")
    func refoldKeepsBodySelection() {
        let fold = FrontmatterFold(headingLength: 4, end: 19)
        #expect(fold.selectionAfterFolding(TextSpan(location: 19, length: 0)) == TextSpan(location: 19, length: 0))
        #expect(fold.selectionAfterFolding(TextSpan(location: 25, length: 6)) == TextSpan(location: 25, length: 6))
    }

    @Test("an edit before the body is inside the fold")
    func editInside() {
        let fold = FrontmatterFold(headingLength: 4, end: 19)
        #expect(fold.isInside(editAt: 0))
        #expect(fold.isInside(editAt: 18))
        #expect(fold.isInside(editAt: 19) == false)
    }
}
