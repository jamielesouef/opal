//
//  RenameUseCaseTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("Rename and Link rewriting")
struct RenameUseCaseTests {
    // MARK: - Names

    @Test("checks the new name", arguments: [
        ("", RenameProblem.empty),
        ("a/b", .invalidCharacter("/")),
        ("a:b", .invalidCharacter(":")),
        (".hidden", .startsWithDot),
        ("Tomatoes", .taken(NotePath("Tomatoes.md"))),
        ("TOMATOES.md", .taken(NotePath("Tomatoes.md"))),
        ("Soil", .unchanged)
    ])
    func problems(name: String, problem: RenameProblem) {
        let existing: Set = [NotePath("Soil.md"), NotePath("Tomatoes.md")]
        #expect(RenameUseCase.newPath(renaming: NotePath("Soil.md"), to: name, kind: .note, existing: existing) == .failure(problem))
    }

    @Test("adds the right extension and allows a change of case")
    func names() {
        let existing: Set = [NotePath("Soil.md"), NotePath("Attachments/seedlings.png")]
        #expect(RenameUseCase.newPath(renaming: NotePath("Soil.md"), to: "Earth", kind: .note, existing: existing) == .success(NotePath("Earth.md")))
        #expect(RenameUseCase.newPath(renaming: NotePath("Soil.md"), to: "soil", kind: .note, existing: existing) == .success(NotePath("soil.md")))
        #expect(RenameUseCase.newPath(renaming: NotePath("Attachments/seedlings.png"), to: "sprouts", kind: .attachment, existing: existing) == .success(NotePath("Attachments/sprouts.png")))
    }

    // MARK: - Links

    @Test(
        "rewrites each kind of Link and keeps its style, subpath and alias",
        arguments: [
            ("[[Soil]]", "[[Earth]]"),
            ("[[Soil|rich earth]]", "[[Earth|rich earth]]"),
            ("![[Soil#Types]]", "![[Earth#Types]]"),
            ("[[Soil#^compost-rule]]", "[[Earth#^compost-rule]]"),
            ("[[Soil.md]]", "[[Earth.md]]"),
            ("[soil](Soil.md)", "[soil](Earth.md)"),
            ("[[Tomatoes]] and [[Soil]]", "[[Tomatoes]] and [[Earth]]")
        ]
    )
    func rewrite(before: String, after: String) {
        #expect(rewritten(before, moves: [NotePath("Soil.md"): NotePath("Earth.md")]) == after)
    }

    @Test("uses a path when the new name is not unique, and keeps relative Markdown Links relative")
    func paths() {
        let moves = [NotePath("Areas/Soil.md"): NotePath("Areas/Beds/Soil.md")]
        #expect(rewritten("[[Areas/Soil]]", moves: moves, source: NotePath("Note.md"), unique: false) == "[[Areas/Beds/Soil]]")
        #expect(rewritten("[soil](../Areas/Soil.md)", moves: moves, source: NotePath("Projects/Note.md"), unique: false) == "[soil](../Areas/Beds/Soil.md)")
        #expect(rewritten("[[Soil]]", moves: [NotePath("Soil.md"): NotePath("Areas/Soil.md")], unique: false) == "[[Areas/Soil]]")
    }

    @Test("leaves text without Links to the moved Note unchanged")
    func untouched() {
        #expect(rewritten("[[Tomatoes]]", moves: [NotePath("Soil.md"): NotePath("Earth.md")]) == nil)
    }

    // MARK: - Helpers

    private func rewritten(_ text: String, moves: [NotePath: NotePath], source: NotePath = NotePath("Note.md"), unique: Bool = true) -> String? {
        let paths = [NotePath("Soil.md"), NotePath("Tomatoes.md"), NotePath("Areas/Soil.md"), NotePath("Note.md"), NotePath("Projects/Note.md")]
        let parsed = paths.reduce(into: [NotePath: ParsedNote]()) { $0[$1] = .empty }
        let resolver = LinkMap(paths: paths, parsed: parsed).resolver
        return LinkRewriteUseCase.rewrite(text, links: MarkdownNoteParser.parse(text).links, source: source, moves: moves, resolver: resolver) { _ in unique }
    }
}
