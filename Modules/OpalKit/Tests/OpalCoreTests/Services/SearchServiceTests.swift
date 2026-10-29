//
//  SearchServiceTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("SearchService with a fixture Vault", .tags(.service))
@MainActor
struct SearchServiceTests {
    // MARK: - Helpers

    private static func results(_ query: String, in vault: FixtureVault) async -> [SearchResult] {
        let harness = ServiceHarness(store: FileSystemVaultStore(rootURL: vault.rootURL))
        defer { try? FileManager().removeItem(at: harness.indexFolder) }
        await harness.openVault()
        await harness.index.sync()
        harness.search.query = query
        await harness.search.search()
        guard case let .results(results) = harness.search.loadState else {
            return []
        }
        return results
    }

    private static func names(_ query: String, in vault: FixtureVault) async -> [String] {
        await results(query, in: vault).map(\.path.name)
    }

    // MARK: - Tests

    @Test("finds a word in every Note that has it, with the line in context")
    func word() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }

        let results = await Self.results("compost", in: vault)

        #expect(results.map(\.path.name) == ["Soil", "Tomatoes"])
        #expect(results.first?.lines.first?.text == "Compost improves every kind. ^compost-rule")
        #expect(results.first?.lines.first?.line == 16)
    }

    @Test("all words must match, and the last word matches as a prefix while typing")
    func andPrefix() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }

        #expect(await Self.names("water morn", in: vault) == ["Gardening Basics"])
    }

    @Test("a quoted phrase matches words in order")
    func phrase() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }

        #expect(await Self.names(#""organic matter""#, in: vault) == ["Soil"])
        #expect(await Self.names(#""matter organic""#, in: vault).isEmpty)
    }

    @Test("[property:value] finds the Notes whose Property has the value, with the line shown")
    func property() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }

        let results = await Self.results("[difficulty:easy]", in: vault)

        #expect(results.map(\.path.name) == ["Gardening Basics"])
        #expect(results.first?.lines.first?.text == "difficulty: easy")
        #expect(await Self.names("[difficulty:hard]", in: vault).isEmpty)
        #expect(Set(await Self.names("[planted]", in: vault)) == ["Tomatoes"])
        #expect(await Self.names("-[difficulty] [planted] tag:garden", in: vault) == ["Tomatoes"])
    }

    @Test("tag: finds the Tag and its children, from the body and the tags Property")
    func tag() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }

        #expect(Set(await Self.names("tag:#garden", in: vault)) == ["Soil", "Tomatoes", "Gardening Basics"])
        #expect(await Self.names("tag:#garden/harvest", in: vault) == ["Tomatoes"])
    }

    @Test("path:, file: and -word narrow the results")
    func filters() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }

        #expect(await Self.names("soil path:Reading", in: vault) == ["The Soil Book"])
        #expect(await Self.names("file:roadmap", in: vault) == ["Opal Roadmap"])
        #expect(await Self.names("soil -tomatoes", in: vault).contains("Tomatoes") == false)
    }

    @Test("accents and case are ignored")
    func folding() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }

        #expect(await Self.names("COMPÔST", in: vault) == ["Soil", "Tomatoes"])
    }

    @Test("typing schedules one search after a short pause")
    func debounce() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = ServiceHarness(store: FileSystemVaultStore(rootURL: vault.rootURL))
        defer { try? FileManager().removeItem(at: harness.indexFolder) }
        await harness.openVault()
        await harness.index.sync()

        harness.search.query = "c"
        harness.search.query = "co"
        harness.search.query = "compost"
        await harness.search.waitForSearch()

        guard case let .results(results) = harness.search.loadState else {
            Issue.record("Expected results, got \(harness.search.loadState)")
            return
        }
        #expect(results.map(\.path.name) == ["Soil", "Tomatoes"])
    }
}
