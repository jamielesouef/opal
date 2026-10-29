//
//  QuickSwitcherServiceTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("QuickSwitcherService with a fixture Vault", .tags(.service))
@MainActor
struct QuickSwitcherServiceTests {
    // MARK: - Helpers

    private static func harness(_ vault: FixtureVault) async -> ServiceHarness {
        let harness = ServiceHarness(store: FileSystemVaultStore(rootURL: vault.rootURL))
        await harness.openVaultWithLinks()
        return harness
    }

    // MARK: - Tests

    @Test("finds Soil by its Alias and opens it")
    func aliasOpens() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = await Self.harness(vault)

        await harness.switcher.prepare(query: "dirt")
        #expect(harness.switcher.selected?.matchedAlias == "Dirt")

        await harness.switcher.confirm()
        #expect(harness.notes.path == NotePath("Soil.md"))
    }

    @Test("arrow keys move the selection within the results")
    func selection() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = await Self.harness(vault)

        await harness.switcher.prepare(query: "so")
        harness.switcher.moveSelection(by: 1)
        #expect(harness.switcher.selected?.path == NotePath("Reading/The Soil Book.md"))

        harness.switcher.moveSelection(by: -5)
        #expect(harness.switcher.selectedIndex == 0)
    }

    @Test("with no match, confirming creates the Note where new Notes go")
    func creates() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = await Self.harness(vault)

        await harness.switcher.prepare(query: "Zucchini")
        #expect(harness.switcher.canCreate)

        let created = await harness.switcher.confirm()
        #expect(created == NotePath("Inbox/Zucchini.md"))
        #expect(FileManager().fileExists(atPath: vault.url("Inbox/Zucchini.md").path))
        #expect(harness.notes.path == created)
    }

    @Test("an empty query lists the Notes opened last first, and remembers them outside the Vault")
    func recent() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = await Self.harness(vault)

        await harness.navigation.open(NotePath("Tomatoes.md"))
        await harness.navigation.open(NotePath("Areas/Health.md"))
        await harness.switcher.prepare()

        #expect(harness.switcher.results.prefix(2).map(\.path) == [NotePath("Areas/Health.md"), NotePath("Tomatoes.md")])
        #expect(await harness.recents.recentNotes(forVaultAt: harness.store.rootURL).first == NotePath("Areas/Health.md"))
    }

    @Test("with newFileLocation current, a created Note goes in the open Note's Folder")
    func createsBesideOpenNote() async {
        let store = StubVaultFileStore(
            files: ["Soil.md": "# Soil\n", "Areas/Health.md": "# Health\n"],
            folders: ["Areas"],
            settingsJSON: #"{"newFileLocation":"current"}"#
        )
        let harness = ServiceHarness(store: store)
        await harness.openVaultWithLinks()
        await harness.navigation.open(NotePath("Areas/Health.md"))

        await harness.switcher.prepare(query: "Zucchini")
        let created = await harness.switcher.confirm()

        #expect(created == NotePath("Areas/Zucchini.md"))
        #expect(await store.text("Areas/Zucchini.md") == "")
    }

    @Test("tabs open, close and come back for the same Vault")
    func tabs() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = ServiceHarness(store: FileSystemVaultStore(rootURL: vault.rootURL))
        await harness.openVault()

        await harness.navigation.open(NotePath("Welcome.md"))
        await harness.navigation.openInNewTab(NotePath("Soil.md"))
        #expect(harness.notes.path == NotePath("Soil.md"))
        #expect(harness.navigation.tabs.paths == [NotePath("Welcome.md"), NotePath("Soil.md")])

        await harness.navigation.selectTab(harness.navigation.tabs.tabs[0].id)
        #expect(harness.notes.path == NotePath("Welcome.md"))

        let restored = NavigationService(vault: harness.vault, notes: harness.notes, links: harness.links, recents: harness.recents, windowID: harness.windowID, windows: harness.windows)
        await restored.restoreWindowState()
        #expect(restored.tabs.paths == [NotePath("Welcome.md"), NotePath("Soil.md")])

        await harness.navigation.closeSelectedTab()
        #expect(harness.notes.path == NotePath("Soil.md"))
    }
}
