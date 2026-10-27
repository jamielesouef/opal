//
//  GRDBIndexStoreTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("GRDBIndexStore", .tags(.data))
struct GRDBIndexStoreTests {
    // MARK: - Helpers

    private static func folder() -> URL {
        FileManager().temporaryDirectory.appending(component: "OpalIndexStoreTests-\(UUID().uuidString)")
    }

    private static func note(_ raw: String, _ text: String, seconds: Double = 1) -> IndexedNote {
        IndexedNote(
            path: NotePath(raw),
            stamp: FileStamp(modified: Date(timeIntervalSinceReferenceDate: seconds), size: text.utf8.count),
            parsed: MarkdownNoteParser.parse(text),
            text: text
        )
    }

    // MARK: - Tests

    @Test("stores stamps and parsed Notes, and keeps them across reopening")
    func roundTrip() async throws {
        let folder = Self.folder()
        defer { try? FileManager().removeItem(at: folder) }
        let note = Self.note("Soil.md", "---\naliases: [Dirt]\n---\n# Soil\n\nSee [[Tomatoes#Watering]].\n")

        try await GRDBIndexStore(folderURL: folder).upsert([note])
        let reopened = try GRDBIndexStore(folderURL: folder)

        #expect(try await reopened.stamps() == [note.path: note.stamp])
        #expect(try await reopened.parsedNotes() == [note.path: note.parsed])
    }

    @Test("an upsert replaces the Note and a remove deletes it")
    func upsertAndRemove() async throws {
        let folder = Self.folder()
        defer { try? FileManager().removeItem(at: folder) }
        let store = try GRDBIndexStore(folderURL: folder)

        try await store.upsert([Self.note("A.md", "# One"), Self.note("B.md", "# B")])
        try await store.upsert([Self.note("A.md", "# Two", seconds: 2)])
        try await store.remove([NotePath("B.md")])

        let parsed = try await store.parsedNotes()
        #expect(parsed.keys.map(\.rawValue) == ["A.md"])
        #expect(parsed[NotePath("A.md")]?.headings.map(\.text) == ["Two"])
    }

    @Test("a damaged Index file is deleted and rebuilt empty")
    func damaged() async throws {
        let folder = Self.folder()
        defer { try? FileManager().removeItem(at: folder) }
        try FileManager().createDirectory(at: folder, withIntermediateDirectories: true)
        try Data("not a database".utf8).write(to: folder.appending(component: "index.sqlite"))

        let store = try GRDBIndexStore(folderURL: folder)

        #expect(try await store.stamps().isEmpty)
    }

    @Test("each Vault gets its own folder, outside the Vault")
    func location() {
        let base = URL(filePath: "/Indexes")
        let one = IndexLocation.folder(forVaultAt: URL(filePath: "/Vaults/One"), in: base)
        let two = IndexLocation.folder(forVaultAt: URL(filePath: "/Vaults/Two"), in: base)

        #expect(one != two)
        #expect(one.deletingLastPathComponent().path == "/Indexes")
        #expect(one == IndexLocation.folder(forVaultAt: URL(filePath: "/Vaults/One/"), in: base))
    }
}
