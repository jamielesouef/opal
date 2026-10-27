//
//  IndexServiceTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("IndexService with a fixture Vault", .tags(.service))
@MainActor
struct IndexServiceTests {
    // MARK: - Helpers

    private static func harness(_ vault: FixtureVault) async -> ServiceHarness {
        let harness = ServiceHarness(store: FileSystemVaultStore(rootURL: vault.rootURL))
        await harness.openVault()
        return harness
    }

    private static func notesOnDisk(_ harness: ServiceHarness) async throws -> Int {
        try await harness.store.noteStamps().count
    }

    // MARK: - Tests

    @Test("the first sync indexes every Note, outside the Vault")
    func firstSync() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = await Self.harness(vault)
        defer { try? FileManager().removeItem(at: harness.indexFolder) }

        await harness.index.sync()

        #expect(harness.index.loadState == .ready)
        let stamps = try #require(try await harness.index.store?.stamps())
        #expect(try await stamps.count == Self.notesOnDisk(harness))
        #expect(FileManager().fileExists(atPath: vault.url(".obsidian").path))
        #expect(try FileManager().contentsOfDirectory(atPath: vault.rootURL.path).contains { $0.hasSuffix(".sqlite") } == false)
    }

    @Test("a second open reads nothing when nothing changed, and picks up a changed Note")
    func incremental() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = await Self.harness(vault)
        defer { try? FileManager().removeItem(at: harness.indexFolder) }
        await harness.index.sync()
        let revision = harness.index.revision

        await harness.index.sync()
        #expect(harness.index.revision == revision + 1)

        let index = try #require(harness.index.store)
        let plan = try await IndexSyncPlanUseCase.plan(disk: harness.store.noteStamps(), indexed: index.stamps())
        #expect(plan.isEmpty)

        try vault.write("# Soil\n\nNow about [[Peas]].\n", to: "Soil.md")
        await harness.index.update([NotePath("Soil.md")])
        #expect(try await index.parsedNotes()[NotePath("Soil.md")]?.links.map(\.target) == ["Peas"])
    }

    @Test("deleting the Index loses nothing: the next sync rebuilds the same content")
    func rebuild() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = await Self.harness(vault)
        defer { try? FileManager().removeItem(at: harness.indexFolder) }
        await harness.index.sync()
        let before = try #require(try await harness.index.store?.parsedNotes())

        try FileManager().removeItem(at: harness.indexFolder)
        let fresh = await Self.harness(vault)
        let freshIndex = IndexService(vault: fresh.vault) { root throws(IndexError) in
            try GRDBIndexStore(folderURL: IndexLocation.folder(forVaultAt: root, in: harness.indexFolder))
        }
        await freshIndex.sync()

        #expect(try await freshIndex.store?.parsedNotes() == before)
        try? FileManager().removeItem(at: fresh.indexFolder)
    }

    @Test("a saved edit and a removed file update the Index")
    func savesAndRemovals() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = await Self.harness(vault)
        defer { try? FileManager().removeItem(at: harness.indexFolder) }
        await harness.index.sync()

        await harness.notes.open(NotePath("Areas/Health.md"))
        harness.notes.edit("# Health\n\n## Sleep\n")
        await harness.notes.flush()
        try FileManager().removeItem(at: vault.url("Tomatoes.md"))
        await harness.vault.handleExternalChanges([NotePath("Tomatoes.md")])

        let parsed = try #require(try await harness.index.store?.parsedNotes())
        #expect(parsed[NotePath("Areas/Health.md")]?.headings.map(\.text) == ["Health", "Sleep"])
        #expect(parsed[NotePath("Tomatoes.md")] == nil)
    }
}
