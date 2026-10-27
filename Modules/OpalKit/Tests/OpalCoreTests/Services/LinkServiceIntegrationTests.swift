//
//  LinkServiceIntegrationTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("LinkService with a fixture Vault", .tags(.service))
@MainActor
struct LinkServiceIntegrationTests {
    // MARK: - Helpers

    private static func harness(_ vault: FixtureVault) -> ServiceHarness {
        ServiceHarness(store: FileSystemVaultStore(rootURL: vault.rootURL))
    }

    // MARK: - Backlinks

    @Test("lists the Backlinks of Soil, through names, Aliases and Markdown Links")
    func soilBacklinks() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = Self.harness(vault)
        await harness.openVaultWithLinks()

        let backlinks = harness.links.map.backlinks(to: NotePath("Soil.md"))

        #expect(Set(backlinks.map(\.source.rawValue)) == [
            "Gardening Basics.md", "Tomatoes.md", "Reading/The Soil Book.md", "Areas/Health.md"
        ])
        #expect(backlinks.filter { $0.source == NotePath("Tomatoes.md") }.count == 2)
        #expect(backlinks.first { $0.source == NotePath("Tomatoes.md") }?.link.lineText == "Grow them in full sun, in [[Soil|rich earth]].")
        #expect(harness.links.loadState == .ready)
    }

    @Test("a saved edit updates the Backlinks of other Notes")
    func saveUpdatesMap() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = Self.harness(vault)
        await harness.openVaultWithLinks()

        await harness.notes.open(NotePath("Areas/Health.md"))
        harness.notes.edit("# Health\n\nSee [[Dirt]] and [[Welcome]].\n")
        await harness.notes.flush()
        await harness.links.waitForRebuild()

        #expect(harness.links.map.backlinks(to: NotePath("Welcome.md")).contains { $0.source == NotePath("Areas/Health.md") })
        #expect(harness.links.map.backlinks(to: NotePath("Soil.md")).contains { $0.link.target == "Dirt" })
        #expect(harness.links.map.backlinks(to: NotePath("Tomatoes.md")).contains { $0.source == NotePath("Areas/Health.md") } == false)
    }

    // MARK: - Following

    @Test("following a Heading Link opens the Note and asks to reveal the line")
    func followHeading() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = Self.harness(vault)
        await harness.openVaultWithLinks()
        await harness.navigation.open(NotePath("Gardening Basics.md"))

        let link = try #require(MarkdownNoteParser.parse("[[Tomatoes#Watering]]").links.first)
        await harness.navigation.follow(link, from: NotePath("Gardening Basics.md"))

        #expect(harness.notes.path == NotePath("Tomatoes.md"))
        #expect(harness.navigation.reveal?.line == 9)
        #expect(harness.navigation.history.back == [NotePath("Gardening Basics.md")])
    }

    @Test("following an Unresolved Link creates the Note in Inbox, opens it and resolves the Link")
    func followUnresolved() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = Self.harness(vault)
        await harness.openVaultWithLinks()
        await harness.navigation.open(NotePath("Welcome.md"))

        let link = try #require(MarkdownNoteParser.parse("[[Ideas That Do Not Exist Yet]]").links.first)
        let destination = await harness.navigation.follow(link, from: NotePath("Welcome.md"))

        let created = NotePath("Inbox/Ideas That Do Not Exist Yet.md")
        #expect(destination == .create(created))
        #expect(FileManager().fileExists(atPath: vault.url(created.rawValue).path))
        #expect(harness.notes.path == created)
        #expect(harness.vault.kind(of: created) == .note)
        #expect(harness.links.map.resolver.resolve(link.target, from: NotePath("Welcome.md")) == created)
    }

    @Test("back and forward move through the Notes opened")
    func backAndForward() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = Self.harness(vault)
        await harness.openVaultWithLinks()

        await harness.navigation.open(NotePath("Welcome.md"))
        await harness.navigation.open(NotePath("Soil.md"))
        await harness.navigation.goBack()
        #expect(harness.notes.path == NotePath("Welcome.md"))

        await harness.navigation.goForward()
        #expect(harness.notes.path == NotePath("Soil.md"))
    }
}
