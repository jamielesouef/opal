//
//  LinkSuggestionUseCaseTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Testing
@testable import OpalCore

@Suite("LinkSuggestionUseCase", .tags(.domain))
struct LinkSuggestionUseCaseTests {
    // MARK: - Fixtures

    private static let paths = [
        "Soil.md", "Areas/Notes.md", "Projects/Notes.md", "Projects/Opal/Opal Roadmap.md", "Attachments/seedlings.png"
    ].map(NotePath.init)

    private static let resolver = LinkResolver(paths: paths, aliases: [NotePath("Soil.md"): ["Dirt"]])

    private static func insertion(_ suggestion: LinkSuggestion, markdown: Bool = false) -> String {
        LinkSuggestionUseCase.insertion(for: suggestion, from: NotePath("Welcome.md"), resolver: resolver, useMarkdownLinks: markdown)
    }

    // MARK: - Query

    @Test("finds the open [[ before the cursor", arguments: [
        ("See [[So", 8, "So", 4),
        ("See [[", 6, "", 4),
        ("a\nb ![[Opal R", 13, "Opal R", 5)
    ])
    func openQuery(text: String, cursor: Int, query: String, bracket: Int) throws {
        let found = try #require(LinkSuggestionUseCase.openQuery(in: text, cursor: cursor))

        #expect(found.text == query)
        #expect(found.bracketLocation == bracket)
        #expect(found.queryLocation == bracket + 2)
    }

    @Test("no query once the Link is closed, has a | or #, or is on another line", arguments: [
        ("[[Soil]] and", 12),
        ("[[Soil|ri", 9),
        ("[[Soil#Wa", 9),
        ("[[So\nil", 7),
        ("plain text", 5)
    ])
    func noQuery(text: String, cursor: Int) {
        #expect(LinkSuggestionUseCase.openQuery(in: text, cursor: cursor) == nil)
    }

    // MARK: - Suggestions

    @Test("suggests Notes, Aliases and Unresolved targets")
    func suggestions() {
        let candidates = [SwitcherCandidate(path: NotePath("Soil.md"), aliases: ["Dirt"]), SwitcherCandidate(path: NotePath("Tomatoes.md"))]

        #expect(LinkSuggestionUseCase.suggestions(for: "dir", candidates: candidates, unresolved: ["Dirt Types"], recent: []) == [
            .note(NotePath("Soil.md"), alias: "Dirt"),
            .unresolved("Dirt Types")
        ])
    }

    // MARK: - Insertion

    @Test("inserts the name when it is unambiguous, else the path")
    func shortestPath() {
        #expect(Self.insertion(.note(NotePath("Projects/Opal/Opal Roadmap.md"), alias: nil)) == "[[Opal Roadmap]]")
        #expect(Self.insertion(.note(NotePath("Projects/Notes.md"), alias: nil)) == "[[Projects/Notes]]")
        #expect(Self.insertion(.note(NotePath("Attachments/seedlings.png"), alias: nil)) == "[[seedlings.png]]")
    }

    @Test("an Alias becomes the display text")
    func alias() {
        #expect(Self.insertion(.note(NotePath("Soil.md"), alias: "Dirt")) == "[[Soil|Dirt]]")
    }

    @Test("an Unresolved target is inserted as written")
    func unresolved() {
        #expect(Self.insertion(.unresolved("Ideas That Do Not Exist Yet")) == "[[Ideas That Do Not Exist Yet]]")
    }

    @Test("Markdown Links when the Vault asks for them, with spaces encoded")
    func markdown() {
        #expect(Self.insertion(.note(NotePath("Projects/Opal/Opal Roadmap.md"), alias: nil), markdown: true) == "[Opal Roadmap](Opal%20Roadmap.md)")
        #expect(Self.insertion(.note(NotePath("Soil.md"), alias: "Dirt"), markdown: true) == "[Dirt](Soil.md)")
    }

    @Test("the Link map lists Unresolved targets once")
    func unresolvedTargets() {
        let map = LinkMap(paths: [NotePath("A.md")], parsed: [
            NotePath("A.md"): MarkdownNoteParser.parse("[[Missing]] [[missing]] [[A]] [[Other]]")
        ])

        #expect(map.unresolvedTargets == ["Missing", "Other"])
    }
}
