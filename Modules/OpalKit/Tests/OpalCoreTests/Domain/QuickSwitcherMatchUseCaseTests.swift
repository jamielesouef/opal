//
//  QuickSwitcherMatchUseCaseTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Testing
@testable import OpalCore

@Suite("QuickSwitcherMatchUseCase", .tags(.domain))
struct QuickSwitcherMatchUseCaseTests {
    // MARK: - Fixtures

    private static let candidates = [
        SwitcherCandidate(path: NotePath("Soil.md"), aliases: ["Dirt", "Earth"]),
        SwitcherCandidate(path: NotePath("Reading/The Soil Book.md")),
        SwitcherCandidate(path: NotePath("Projects/Opal/Opal Roadmap.md")),
        SwitcherCandidate(path: NotePath("Projects/Opal/Meeting 2026-10-20.md")),
        SwitcherCandidate(path: NotePath("Welcome.md"), aliases: ["Start Here"]),
        SwitcherCandidate(path: NotePath("Tomatoes.md"))
    ]

    private static func names(_ query: String, recent: [String] = []) -> [String] {
        QuickSwitcherMatchUseCase.matches(query: query, candidates: candidates, recent: recent.map(NotePath.init)).map(\.path.name)
    }

    // MARK: - Tests

    @Test("ranks a name that starts with the query first")
    func prefixFirst() {
        #expect(Self.names("so").prefix(2) == ["Soil", "The Soil Book"])
    }

    @Test("matches letters in order, across words")
    func fuzzy() {
        #expect(Self.names("oprd").first == "Opal Roadmap")
        #expect(Self.names("opal road").first == "Opal Roadmap")
    }

    @Test("matches the Folder path")
    func path() {
        #expect(Self.names("projects meet").first == "Meeting 2026-10-20")
    }

    @Test("finds a Note by its Alias and says which Alias matched")
    func alias() throws {
        let match = try #require(QuickSwitcherMatchUseCase.matches(query: "dirt", candidates: Self.candidates, recent: []).first)

        #expect(match.path == NotePath("Soil.md"))
        #expect(match.matchedAlias == "Dirt")
    }

    @Test("a name match beats an Alias match")
    func nameBeatsAlias() {
        let match = QuickSwitcherMatchUseCase.matches(query: "soil", candidates: Self.candidates, recent: []).first
        #expect(match?.matchedAlias == nil)
    }

    @Test("returns nothing when no letters match")
    func noMatch() {
        #expect(Self.names("xyz").isEmpty)
    }

    @Test("an empty query lists recent Notes first, then the rest by name")
    func emptyQuery() {
        #expect(Self.names("", recent: ["Tomatoes.md", "Gone.md", "Welcome.md"]) == [
            "Tomatoes", "Welcome", "Meeting 2026-10-20", "Opal Roadmap", "Soil", "The Soil Book"
        ])
    }

    @Test("recording a Note moves it to the front and keeps the list short")
    func recording() {
        var recent: [NotePath] = []
        for index in 0 ..< QuickSwitcherMatchUseCase.recentLimit + 5 {
            recent = QuickSwitcherMatchUseCase.recording(NotePath("\(index).md"), in: recent)
        }
        recent = QuickSwitcherMatchUseCase.recording(NotePath("10.md"), in: recent)

        #expect(recent.count == QuickSwitcherMatchUseCase.recentLimit)
        #expect(recent.first == NotePath("10.md"))
        #expect(recent.filter { $0 == NotePath("10.md") }.count == 1)
    }
}
