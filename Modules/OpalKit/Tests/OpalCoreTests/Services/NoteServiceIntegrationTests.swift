//
//  NoteServiceIntegrationTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("NoteService with a fixture Vault", .tags(.service, .data))
struct NoteServiceIntegrationTests {
    @Test("an edited Note is saved to disk exactly, and other Notes keep their bytes and dates")
    func savesOnlyTheEditedNote() async throws {
        let fixture = try FixtureVault()
        defer { fixture.remove() }
        let harness = await ServiceHarness(store: FileSystemVaultStore(rootURL: fixture.rootURL))
        let tomatoesURL = fixture.url("Tomatoes.md")
        let tomatoesBefore = try Data(contentsOf: tomatoesURL)
        let tomatoesDate = try FileManager().attributesOfItem(atPath: tomatoesURL.path)[.modificationDate] as? Date
        await harness.openVault()

        await harness.notes.open(NotePath("Tomatoes.md"))
        await harness.notes.open(NotePath("Soil.md"))
        let original = try fixture.text("Soil.md")
        await harness.notes.edit(original + "\nMore compost.\n")
        await harness.notes.close()

        #expect(try fixture.text("Soil.md") == original + "\nMore compost.\n")
        #expect(try Data(contentsOf: tomatoesURL) == tomatoesBefore)
        #expect(try FileManager().attributesOfItem(atPath: tomatoesURL.path)[.modificationDate] as? Date == tomatoesDate)
    }

    @Test("a change made by another app is not overwritten")
    func keepsExternalChange() async throws {
        let fixture = try FixtureVault()
        defer { fixture.remove() }
        let harness = await ServiceHarness(store: FileSystemVaultStore(rootURL: fixture.rootURL))
        await harness.openVault()
        await harness.notes.open(NotePath("Welcome.md"))

        await harness.notes.edit("mine")
        try fixture.write("changed in Obsidian", to: "Welcome.md")
        await harness.notes.flush()

        #expect(try fixture.text("Welcome.md") == "changed in Obsidian")
        #expect(await harness.notes.loadState == .conflict(Note(path: NotePath("Welcome.md"), text: "mine"), diskText: "changed in Obsidian"))
    }

    @Test("a new Note in the Garden Vault lands in Inbox, as its app.json says")
    func newNoteInInbox() async throws {
        let fixture = try FixtureVault()
        defer { fixture.remove() }
        let harness = await ServiceHarness(store: FileSystemVaultStore(rootURL: fixture.rootURL))
        await harness.openVault()

        let path = try await harness.vault.createNote(openNote: nil)

        #expect(path == NotePath("Inbox/Untitled.md"))
        #expect(FileManager().fileExists(atPath: fixture.url("Inbox/Untitled.md").path))
    }
}
