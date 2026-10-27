//
//  MentionServiceTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("MentionService with a fixture Vault", .tags(.service))
@MainActor
struct MentionServiceTests {
    // MARK: - Helpers

    private static func harness(_ vault: FixtureVault) async -> ServiceHarness {
        let harness = ServiceHarness(store: FileSystemVaultStore(rootURL: vault.rootURL))
        await harness.openVault()
        await harness.index.sync()
        await harness.links.sync()
        return harness
    }

    // MARK: - Tests

    @Test("finds Notes that name Gardening Basics without linking it")
    func finds() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = await Self.harness(vault)
        defer { try? FileManager().removeItem(at: harness.indexFolder) }

        await harness.mentions.load(for: NotePath("Gardening Basics.md"))

        #expect(harness.mentions.mentions.map(\.source) == [NotePath("Soil.md")])
        #expect(harness.mentions.mentions.first?.lineText == "Tomatoes need rich soil, as Gardening Basics says.")
    }

    @Test("linking a mention rewrites only that mention and nothing else in the file")
    func links() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = await Self.harness(vault)
        defer { try? FileManager().removeItem(at: harness.indexFolder) }
        let before = try vault.text("Soil.md")
        await harness.mentions.load(for: NotePath("Gardening Basics.md"))
        let mention = try #require(harness.mentions.mentions.first)

        #expect(await harness.mentions.link(mention))

        let expected = before.replacingOccurrences(of: "as Gardening Basics says", with: "as [[Gardening Basics]] says")
        #expect(try vault.text("Soil.md") == expected)
        #expect(harness.mentions.mentions.isEmpty)
        #expect(harness.links.map.backlinks(to: NotePath("Gardening Basics.md")).contains { $0.source == NotePath("Soil.md") })
    }

    @Test("linking in the open Note goes through the Editor's text and saves it")
    func linksOpenNote() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = await Self.harness(vault)
        defer { try? FileManager().removeItem(at: harness.indexFolder) }
        await harness.notes.open(NotePath("Soil.md"))
        await harness.mentions.load(for: NotePath("Gardening Basics.md"))
        let mention = try #require(harness.mentions.mentions.first)

        #expect(await harness.mentions.link(mention))

        #expect(harness.notes.loadState.note?.text.contains("[[Gardening Basics]]") == true)
        #expect(try vault.text("Soil.md").contains("[[Gardening Basics]]"))
        #expect(harness.notes.saveStatus == .saved)
    }
}
