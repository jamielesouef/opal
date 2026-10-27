//
//  UnlinkedMentionUseCaseTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Testing
@testable import OpalCore

@Suite("UnlinkedMentionUseCase", .tags(.domain))
struct UnlinkedMentionUseCaseTests {
    // MARK: - Helpers

    private static func mentions(_ names: [String], in text: String) -> [UnlinkedMention] {
        UnlinkedMentionUseCase.mentions(of: names, in: text, parsed: MarkdownNoteParser.parse(text), source: NotePath("A.md"))
    }

    // MARK: - Tests

    @Test("finds whole-word mentions of the name or an Alias, ignoring case")
    func finds() {
        let found = Self.mentions(["Soil", "Dirt"], in: "Good soil here.\nTopsoil is not it. DIRT is.\n")

        #expect(found.map(\.matchedText) == ["soil", "DIRT"])
        #expect(found.map(\.line) == [0, 1])
        #expect(found.first?.lineText == "Good soil here.")
    }

    @Test("skips existing Links, code and frontmatter")
    func skips() {
        let text = "---\ntitle: Soil\n---\n[[Soil]] and [the soil](Soil.md) and `soil`\n```\nsoil\n```\nreal soil"

        #expect(Self.mentions(["Soil"], in: text).map(\.line) == [7])
    }

    @Test("a longer name wins over a shorter one at the same place")
    func longestFirst() {
        #expect(Self.mentions(["Soil", "Soil Book"], in: "The Soil Book.").map(\.matchedText) == ["Soil Book"])
    }

    @Test("linking replaces only that mention, keeping its words as display text when they differ")
    func linking() throws {
        let text = "Good soil.\nMore soil."
        let mention = try #require(Self.mentions(["Soil"], in: text).first)

        #expect(UnlinkedMentionUseCase.linking(mention, in: text, target: "Soil", targetName: "Soil") == "Good [[Soil|soil]].\nMore soil.")
        #expect(UnlinkedMentionUseCase.linking(mention, in: "Changed.", target: "Soil", targetName: "Soil") == nil)
    }

    @Test("an exact match becomes a plain Link")
    func exact() throws {
        let mention = try #require(Self.mentions(["Soil"], in: "See Soil.").first)
        #expect(UnlinkedMentionUseCase.replacement(for: mention, target: "Soil", targetName: "Soil") == "[[Soil]]")
    }
}
