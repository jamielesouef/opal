//
//  ExternalChangeTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("Changes from outside with a fixture Vault", .tags(.service))
@MainActor
struct ExternalChangeTests {
    // MARK: - Helpers

    private static func harness(_ vault: FixtureVault, watching: Bool = false) async -> ServiceHarness {
        let makeWatcher: (@Sendable (URL) -> any VaultWatching)? = watching ? Self.makeWatcher : nil
        let harness = ServiceHarness(store: FileSystemVaultStore(rootURL: vault.rootURL), makeWatcher: makeWatcher)
        await harness.openVaultWithLinks()
        return harness
    }

    private nonisolated static func makeWatcher(_ rootURL: URL) -> any VaultWatching {
        FSEventsVaultWatcher(rootURL: rootURL)
    }

    private static func waitUntil(_ condition: @MainActor () -> Bool) async -> Bool {
        for _ in 0 ..< 60 {
            if condition() {
                return true
            }
            try? await Task.sleep(for: .milliseconds(50))
        }
        return condition()
    }

    // MARK: - Tree

    @Test("a file added by another app appears in the tree, through FSEvents")
    func watcherAddsFile() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = await Self.harness(vault, watching: true)
        try await Task.sleep(for: .milliseconds(300))

        try vault.write("# Peas\n\nSee [[Soil]].\n", to: "Peas.md")

        #expect(await Self.waitUntil { harness.vault.kind(of: NotePath("Peas.md")) == .note })
        #expect(await Self.waitUntil {
            harness.links.map.backlinks(to: NotePath("Soil.md")).contains { $0.source == NotePath("Peas.md") }
        })
    }

    @Test("a file removed by another app leaves the tree")
    func removal() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = await Self.harness(vault)

        try FileManager().removeItem(at: vault.url("Areas/Health.md"))
        await harness.vault.handleExternalChanges([NotePath("Areas/Health.md")])

        #expect(harness.vault.kind(of: NotePath("Areas/Health.md")) == nil)
        #expect(harness.links.map.backlinks(to: NotePath("Tomatoes.md")).contains { $0.source == NotePath("Areas/Health.md") } == false)
    }

    // MARK: - Open Note

    @Test("an open Note with no unsaved edits reloads with the text on disk")
    func cleanReloads() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = await Self.harness(vault)
        await harness.notes.open(NotePath("Areas/Health.md"))

        try vault.write("# Health\n\nChanged in Obsidian.\n", to: "Areas/Health.md")
        await harness.vault.handleExternalChanges([NotePath("Areas/Health.md")])

        #expect(harness.notes.loadState.note?.text == "# Health\n\nChanged in Obsidian.\n")
        #expect(harness.notes.saveStatus == .saved)
    }

    @Test("an open Note with unsaved edits is not touched, and saving then reports a conflict")
    func dirtyKept() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = await Self.harness(vault)
        await harness.notes.open(NotePath("Areas/Health.md"))
        harness.notes.edit("# Health\n\nMy edit.\n")

        try vault.write("# Health\n\nTheir edit.\n", to: "Areas/Health.md")
        await harness.vault.handleExternalChanges([NotePath("Areas/Health.md")])
        #expect(harness.notes.loadState.note?.text == "# Health\n\nMy edit.\n")

        await harness.notes.flush()
        guard case .conflict = harness.notes.loadState else {
            Issue.record("Expected a conflict, got \(harness.notes.loadState)")
            return
        }
        #expect(try vault.text("Areas/Health.md") == "# Health\n\nTheir edit.\n")
    }

    @Test("Opal's own save causes no reload and no conflict")
    func ownSave() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = await Self.harness(vault)
        await harness.notes.open(NotePath("Areas/Health.md"))
        harness.notes.edit("# Health\n\nSaved by Opal.\n")
        await harness.notes.flush()

        await harness.vault.handleExternalChanges([NotePath("Areas/Health.md")])

        #expect(harness.notes.loadState == .editing(Note(path: NotePath("Areas/Health.md"), text: "# Health\n\nSaved by Opal.\n")))
        #expect(harness.notes.saveStatus == .saved)
    }

    @Test("changes in hidden Folders are ignored")
    func hiddenIgnored() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = await Self.harness(vault)
        let counter = CallCounter()
        harness.vault.onExternalChange = { _ in counter.count += 1 }

        await harness.vault.handleExternalChanges([NotePath(".obsidian/app.json"), NotePath(".git/index")])

        #expect(counter.count == 0)
    }
}

@MainActor
private final class CallCounter {
    var count = 0
}
