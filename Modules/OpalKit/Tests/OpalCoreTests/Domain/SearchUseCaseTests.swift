//
//  SearchUseCaseTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("Search query and snippets", .tags(.domain))
struct SearchUseCaseTests {
    // MARK: - Query

    @Test("reads words, phrases, exclusions and operators")
    func parse() {
        let query = SearchQueryUseCase.parse(#"soil "organic matter" -clay path:Reading file:"Soil Book" tag:#garden/harvest Unknown:op"#)

        #expect(query.words == ["soil", "Unknown:op"])
        #expect(query.phrases == ["organic matter"])
        #expect(query.excluded == ["clay"])
        #expect(query.paths == ["Reading"])
        #expect(query.files == ["Soil Book"])
        #expect(query.tags == ["garden/harvest"])
    }

    @Test("an empty or blank query is empty", arguments: ["", "   ", "-x"])
    func empty(text: String) {
        #expect(SearchQueryUseCase.parse(text).isEmpty)
    }

    @Test("an unclosed quote still searches the phrase typed so far")
    func unclosed() {
        #expect(SearchQueryUseCase.parse(#""organic mat"#).phrases == ["organic mat"])
    }

    // MARK: - Snippets

    @Test("returns up to three matching lines with the matches marked, ignoring case and accents")
    func snippets() {
        let text = "# Soil\n\nSoil is a mix.\nNo match here.\nGood SOIL.\nCafé soil.\nMore soil."
        let result = SearchSnippetUseCase.result(for: NotePath("Soil.md"), text: text, query: SearchQueryUseCase.parse("soil"))

        #expect(result.lines.map(\.line) == [0, 2, 4])
        #expect(result.matchCount == 5)
        #expect(result.lines[1].highlights == [TextSpan(location: 0, length: 4)])
    }

    @Test("a very long line is cut around the first match")
    func longLine() throws {
        let text = String(repeating: "a ", count: 300) + "needle" + String(repeating: " b", count: 300)
        let line = try #require(SearchSnippetUseCase.result(for: NotePath("A.md"), text: text, query: SearchQueryUseCase.parse("needle")).lines.first)

        #expect((line.text as NSString).length <= SearchSnippetUseCase.maxLineLength + 2)
        let span = try #require(line.highlights.first)
        #expect((line.text as NSString).substring(with: NSRange(location: span.location, length: span.length)) == "needle")
    }

    @Test("filters by path, file name and excluded words")
    func filters() {
        let query = SearchQueryUseCase.parse("path:reading file:book -clay")

        #expect(SearchSnippetUseCase.passesFilters(NotePath("Reading/The Soil Book.md"), text: "loam", query: query))
        #expect(SearchSnippetUseCase.passesFilters(NotePath("Reading/The Soil Book.md"), text: "Clay", query: query) == false)
        #expect(SearchSnippetUseCase.passesFilters(NotePath("Soil.md"), text: "loam", query: query) == false)
    }
}
