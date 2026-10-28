//
//  CommandMatchUseCaseTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Testing
@testable import OpalCore

@Suite("CommandMatchUseCase")
struct CommandMatchUseCaseTests {
    // MARK: - Constants

    private static let ids = ["newNote", "dailyNote", "search", "save"]
    private static let names = ["newNote": "New Note", "dailyNote": "Today's Daily Note", "search": "Search Vault…", "save": "Save"]

    // MARK: - Tests

    @Test("with no query, recent commands come first, then menu order")
    func empty() {
        #expect(CommandMatchUseCase.ordered(ids: Self.ids, names: Self.names, query: "", recent: ["save"]) == ["save", "newNote", "dailyNote", "search"])
    }

    @Test("matches fuzzily on the name")
    func fuzzy() {
        #expect(CommandMatchUseCase.ordered(ids: Self.ids, names: Self.names, query: "dn", recent: []).first == "dailyNote")
        #expect(CommandMatchUseCase.ordered(ids: Self.ids, names: Self.names, query: "sav", recent: []).first == "save")
        #expect(CommandMatchUseCase.ordered(ids: Self.ids, names: Self.names, query: "zzz", recent: []).isEmpty)
    }

    @Test("remembers the last commands, newest first")
    func recent() {
        #expect(CommandMatchUseCase.recording("search", in: ["save", "search", "newNote"]) == ["search", "save", "newNote"])
    }
}
