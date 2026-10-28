//
//  OpenNoteLinksTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("LinkService open Note", .tags(.service))
@MainActor
struct OpenNoteLinksTests {
    // MARK: - Helpers

    private static func harness(_ vault: FixtureVault) async -> ServiceHarness {
        let harness = ServiceHarness(store: FileSystemVaultStore(rootURL: vault.rootURL))
        await harness.openVaultWithLinks()
        return harness
    }

    // MARK: - Tests

    @Test("a small Note is parsed at once, and follows each edit")
    func smallNote() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = await Self.harness(vault)

        harness.links.openNoteChanged(NotePath("Welcome.md"), text: "# Welcome\n\nSee [[Soil]] and [[Nowhere]].\n")
        #expect(harness.links.openNote?.parsed.headings.map(\.text) == ["Welcome"])
        #expect(harness.links.openNote?.styles.map(\.kind) == [.link(isResolved: true), .link(isResolved: false)])

        harness.links.openNoteChanged(NotePath("Welcome.md"), text: "# Hello\n")
        #expect(harness.links.openNote?.parsed.headings.map(\.text) == ["Hello"])
        #expect(harness.links.openNote?.styles.isEmpty == true)
    }

    @Test("a large Note is parsed off the main actor after a pause")
    func largeNote() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = await Self.harness(vault)
        let text = "# Big\n" + String(repeating: "Text about [[Soil]].\n", count: LinkService.mainActorParseLimit / 10)

        harness.links.openNoteChanged(NotePath("Big.md"), text: text)
        #expect(harness.links.openNote == nil)

        await harness.links.waitForOpenNote()
        #expect(harness.links.openNote?.path == NotePath("Big.md"))
        #expect(harness.links.openNote?.textLength == text.utf16.count)
        #expect(harness.links.openNote?.styles.allSatisfy { $0.kind == .link(isResolved: true) } == true)
    }

    @Test("closing the Note clears it")
    func close() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = await Self.harness(vault)
        harness.links.openNoteChanged(NotePath("Welcome.md"), text: "# Welcome\n")

        harness.links.openNoteChanged(nil, text: "")

        #expect(harness.links.openNote == nil)
    }

    @Test("a Link map rebuild recolours the open Note's Links")
    func rebuildRecolours() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = await Self.harness(vault)
        harness.links.openNoteChanged(NotePath("Welcome.md"), text: "See [[Peas]].\n")
        #expect(harness.links.openNote?.styles.first?.kind == .link(isResolved: false))

        try vault.write("# Peas\n", to: "Peas.md")
        await harness.vault.handleExternalChanges([NotePath("Peas.md")])
        await harness.links.sync()

        #expect(harness.links.openNote?.styles.first?.kind == .link(isResolved: true))
    }

    @Test("NoteService keeps the open Note's Links current through open, edit and close")
    func followsNoteService() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = await Self.harness(vault)

        await harness.notes.open(NotePath("Tomatoes.md"))
        #expect(harness.links.openNote?.path == NotePath("Tomatoes.md"))
        #expect(harness.links.openNote?.parsed.headings.map(\.text) == ["Tomatoes", "Watering", "Harvest"])

        harness.notes.edit("# Tomatoes\n\n## Pruning\n")
        #expect(harness.links.openNote?.parsed.headings.map(\.text) == ["Tomatoes", "Pruning"])

        await harness.notes.close()
        #expect(harness.links.openNote == nil)
    }
}
