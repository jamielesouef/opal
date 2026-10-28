//
//  DailyNoteServiceTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("DailyNoteService", .tags(.service))
@MainActor
struct DailyNoteServiceTests {
    // MARK: - Helpers

    private static func service(_ harness: ServiceHarness, on date: Date) -> DailyNoteService {
        DailyNoteService(
            vault: harness.vault,
            links: harness.links,
            navigation: harness.navigation,
            clock: FixedClock(now: date, timeZone: TimeZone(identifier: "Australia/Sydney") ?? .gmt)
        )
    }

    // MARK: - Tests

    @Test("creates a missing Daily Note from the Vault's Template and opens it")
    func creates() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = ServiceHarness(store: FileSystemVaultStore(rootURL: vault.rootURL))
        await harness.openVaultWithLinks()

        let opened = await Self.service(harness, on: Date(timeIntervalSince1970: 1_793_200_000)).openToday()

        #expect(opened == NotePath("Daily Notes/2026-10-29.md"))
        #expect(harness.notes.path == opened)
        #expect(try vault.text("Daily Notes/2026-10-29.md").hasPrefix("# 2026-10-29\n\n## Tasks"))
    }

    @Test("opens an existing Daily Note without changing it")
    func opensExisting() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let before = try vault.text("Daily Notes/2026-10-26.md")
        let harness = ServiceHarness(store: FileSystemVaultStore(rootURL: vault.rootURL))
        await harness.openVaultWithLinks()

        let service = Self.service(harness, on: Date(timeIntervalSince1970: 1_793_000_000))
        await service.openToday()
        await service.openToday()
        await harness.notes.flush()

        #expect(harness.notes.path == NotePath("Daily Notes/2026-10-26.md"))
        #expect(try vault.text("Daily Notes/2026-10-26.md") == before)
    }
}
