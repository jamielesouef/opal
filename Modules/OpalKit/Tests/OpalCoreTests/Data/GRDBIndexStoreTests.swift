//
//  GRDBIndexStoreTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import GRDB
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

    @Test("a query with no word characters returns no hits instead of failing", arguments: ["!!!", "🌱", "\"\"", "a*b"])
    func oddQueries(text: String) async throws {
        let folder = Self.folder()
        defer { try? FileManager().removeItem(at: folder) }
        let store = try GRDBIndexStore(folderURL: folder)
        try await store.upsert([Self.note("Soil.md", "# Soil\n\nGood soil.\n")])

        _ = try await store.search(SearchQueryUseCase.parse(text), limit: 10)
    }

    // MARK: - Properties

    private static func names(_ text: String, in store: GRDBIndexStore) async throws -> [String] {
        try await store.search(SearchQueryUseCase.parse(text), limit: 10).map(\.path.name)
    }

    @Test("finds Notes by Property: value, presence, absence and list items, ignoring case")
    func propertySearch() async throws {
        let folder = Self.folder()
        defer { try? FileManager().removeItem(at: folder) }
        let store = try GRDBIndexStore(folderURL: folder)
        try await store.upsert([
            Self.note("A.md", "---\nstatus: Draft\ntags: [garden, howto]\n---\nSoil here."),
            Self.note("B.md", "---\nstatus: done\n---\nSoil there."),
            Self.note("C.md", "Soil bare.")
        ])

        #expect(try await Self.names("[status:draft]", in: store) == ["A"])
        #expect(try await Self.names("[STATUS]", in: store) == ["A", "B"])
        #expect(try await Self.names("-[status:done]", in: store) == ["A", "C"])
        #expect(try await Self.names("-[status]", in: store) == ["C"])
        #expect(try await Self.names("[tags:howto]", in: store) == ["A"])
        #expect(try await Self.names("[tags:how] soil", in: store) == ["A"])
        #expect(try await Self.names("[status:dra] tag:garden", in: store) == ["A"])
        #expect(try await Self.names("[status:draft] [tags:nope]", in: store).isEmpty)
    }

    @Test("an edit replaces a Note's Properties and a remove drops them")
    func propertyReplace() async throws {
        let folder = Self.folder()
        defer { try? FileManager().removeItem(at: folder) }
        let store = try GRDBIndexStore(folderURL: folder)
        try await store.upsert([Self.note("A.md", "---\nstatus: draft\n---\n")])
        try await store.upsert([Self.note("A.md", "---\nstatus: done\n---\n", seconds: 2)])

        #expect(try await Self.names("[status:draft]", in: store).isEmpty)
        #expect(try await Self.names("[status:done]", in: store) == ["A"])

        try await store.remove([NotePath("A.md")])
        #expect(try await store.propertyTypes(declared: [:]).isEmpty)
    }

    @Test("a name used with two types shows the declared type, or else the most common")
    func propertyTypes() async throws {
        let folder = Self.folder()
        defer { try? FileManager().removeItem(at: folder) }
        let store = try GRDBIndexStore(folderURL: folder)
        try await store.upsert([
            Self.note("A.md", "---\nrating: 4\n---\n"),
            Self.note("B.md", "---\nrating: 5\n---\n"),
            Self.note("C.md", "---\nrating: great\nplanted: 2026-03-14\n---\n")
        ])

        let common = try await store.propertyTypes(declared: [:])
        let declared = try await store.propertyTypes(declared: ["rating": .text])

        #expect(common == ["rating": .number, "planted": .date])
        #expect(declared == ["rating": .text, "planted": .date])
    }

    @Test("an Index from an older schema is rebuilt empty and then fills with Properties")
    func olderSchema() async throws {
        let folder = Self.folder()
        defer { try? FileManager().removeItem(at: folder) }
        try FileManager().createDirectory(at: folder, withIntermediateDirectories: true)
        let old = try DatabaseQueue(path: folder.appending(component: "index.sqlite").path)
        try await old.write { db in
            try db.execute(sql: "CREATE TABLE notes (id INTEGER PRIMARY KEY); PRAGMA user_version = \(GRDBIndexStore.schemaVersion - 1);")
        }
        try old.close()

        let store = try GRDBIndexStore(folderURL: folder)
        try await store.upsert([Self.note("A.md", "---\nstatus: draft\n---\n")])

        #expect(try await Self.names("[status:draft]", in: store) == ["A"])
    }
}
