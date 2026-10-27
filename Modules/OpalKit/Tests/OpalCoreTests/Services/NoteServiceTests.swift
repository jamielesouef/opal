//
//  NoteServiceTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("NoteService", .tags(.service))
struct NoteServiceTests {
    // MARK: - Fixtures

    private static let soil = NotePath("Soil.md")

    private static func openSoil(text: String = "# Soil\n") async -> (ServiceHarness, StubVaultFileStore) {
        let store = StubVaultFileStore(files: ["Soil.md": text, "Tomatoes.md": "# Tomatoes\n"])
        let harness = await ServiceHarness(store: store)
        await harness.openVault()
        await harness.notes.open(soil)
        return (harness, store)
    }

    // MARK: - Tests

    @Test("has no Note open at first")
    func initialState() async {
        let harness = await ServiceHarness(store: StubVaultFileStore())

        #expect(await harness.notes.loadState == .noNote)
    }

    @Test("opening a Note loads its text for editing")
    func opens() async {
        let (harness, _) = await Self.openSoil()

        #expect(await harness.notes.loadState == .editing(Note(path: Self.soil, text: "# Soil\n")))
        #expect(await harness.notes.saveStatus == .saved)
    }

    @Test("opening and leaving a Note without editing never writes it")
    func noWriteWithoutEdit() async {
        let (harness, store) = await Self.openSoil()

        await harness.notes.open(NotePath("Tomatoes.md"))
        await harness.notes.flush()

        #expect(await store.writeCount == 0)
    }

    @Test("an edit is unsaved until flushed, then written exactly")
    func editAndFlush() async {
        let (harness, store) = await Self.openSoil()

        await harness.notes.edit("# Soil\r\n\r\nLoam.  ")
        #expect(await harness.notes.saveStatus == .unsaved)
        await harness.notes.flush()

        #expect(await store.text("Soil.md") == "# Soil\r\n\r\nLoam.  ")
        #expect(await harness.notes.saveStatus == .saved)
        #expect(await store.writeCount == 1)
    }

    @Test("opening another Note saves the edits of the one being left")
    func savesOnSwitch() async {
        let (harness, store) = await Self.openSoil()

        await harness.notes.edit("edited")
        await harness.notes.open(NotePath("Tomatoes.md"))

        #expect(await store.text("Soil.md") == "edited")
        #expect(await harness.notes.loadState == .editing(Note(path: NotePath("Tomatoes.md"), text: "# Tomatoes\n")))
    }

    @Test("a file changed elsewhere while the Note has edits becomes a conflict, and nothing is written")
    func conflict() async {
        let (harness, store) = await Self.openSoil()

        await harness.notes.edit("mine")
        await store.changeOnDisk("Soil.md", to: "theirs")
        await harness.notes.flush()

        #expect(await harness.notes.loadState == .conflict(Note(path: Self.soil, text: "mine"), diskText: "theirs"))
        #expect(await store.text("Soil.md") == "theirs")
        #expect(await store.writeCount == 0)
    }

    @Test("keeping my version after a conflict writes the edits")
    func keepMine() async {
        let (harness, store) = await Self.openSoil()
        await harness.notes.edit("mine")
        await store.changeOnDisk("Soil.md", to: "theirs")
        await harness.notes.flush()

        await harness.notes.keepMyVersion()

        #expect(await store.text("Soil.md") == "mine")
        #expect(await harness.notes.loadState == .editing(Note(path: Self.soil, text: "mine")))
    }

    @Test("using the version on disk after a conflict drops the edits and writes nothing")
    func useDisk() async {
        let (harness, store) = await Self.openSoil()
        await harness.notes.edit("mine")
        await store.changeOnDisk("Soil.md", to: "theirs")
        await harness.notes.flush()

        await harness.notes.useVersionOnDisk()
        await harness.notes.flush()

        #expect(await harness.notes.loadState == .editing(Note(path: Self.soil, text: "theirs")))
        #expect(await store.writeCount == 0)
    }

    @Test("a Note deleted while open is written again on save")
    func recreates() async {
        let (harness, store) = await Self.openSoil()

        await harness.notes.edit("still here")
        await store.changeOnDisk("Soil.md", to: nil)
        await harness.notes.flush()

        #expect(await store.text("Soil.md") == "still here")
    }

    @Test("a failed write keeps the edits and reports the failure")
    func writeFailure() async {
        let (harness, store) = await Self.openSoil()
        await store.failWrites(with: .writeFailed(Self.soil))

        await harness.notes.edit("edited")
        await harness.notes.flush()

        #expect(await harness.notes.saveStatus == .failed(.writeFailed(Self.soil)))
        #expect(await harness.notes.loadState == .editing(Note(path: Self.soil, text: "edited")))
    }

    @Test("a Note that cannot be read is a failure that can be retried")
    func readFailure() async {
        let store = StubVaultFileStore(files: ["Soil.md": "# Soil\n"])
        await store.failReads(with: .notUTF8(Self.soil))
        let harness = await ServiceHarness(store: store)
        await harness.openVault()

        await harness.notes.open(Self.soil)
        #expect(await harness.notes.loadState == .failed(Self.soil, .notUTF8(Self.soil)))

        await store.failReads(with: nil)
        await harness.notes.retry()
        #expect(await harness.notes.loadState == .editing(Note(path: Self.soil, text: "# Soil\n")))
    }

    @Test("edits are ignored while a Note failed to load, so the file is never touched")
    func noEditOnFailure() async {
        let store = StubVaultFileStore(files: [:])
        let harness = await ServiceHarness(store: store)
        await harness.openVault()
        await harness.notes.open(Self.soil)

        await harness.notes.edit("x")
        await harness.notes.flush()

        #expect(await harness.notes.loadState == .failed(Self.soil, .notFound(Self.soil)))
        #expect(await store.writeCount == 0)
    }

    @Test("closing saves and leaves no Note open")
    func close() async {
        let (harness, store) = await Self.openSoil()

        await harness.notes.edit("bye")
        await harness.notes.close()

        #expect(await store.text("Soil.md") == "bye")
        #expect(await harness.notes.loadState == .noNote)
    }
}
