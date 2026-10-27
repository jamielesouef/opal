//
//  GRDBIndexStore.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import GRDB

public final class GRDBIndexStore: IndexStoring {
    // MARK: - Constants

    public static let schemaVersion = 2

    private enum Constants {
        static let fileName = "index.sqlite"
    }

    // MARK: - Stored

    public let fileURL: URL

    private let queue: DatabaseQueue

    // MARK: - Init

    public init(folderURL: URL) throws(IndexError) {
        fileURL = folderURL.appending(component: Constants.fileName)
        do {
            try FileManager().createDirectory(at: folderURL, withIntermediateDirectories: true)
            queue = try Self.openCurrentSchema(at: fileURL)
        } catch {
            AppLog.error("Opening the Index failed, rebuilding it: \(error)")
            do {
                try Self.deleteDatabase(at: fileURL)
                queue = try Self.openCurrentSchema(at: fileURL)
            } catch {
                AppLog.error("Rebuilding the Index failed: \(error)")
                throw .cannotOpen
            }
        }
    }

    // MARK: - IndexStoring

    public func stamps() async throws(IndexError) -> [NotePath: FileStamp] {
        do {
            return try await queue.read { db in
                var stamps: [NotePath: FileStamp] = [:]
                for row in try Row.fetchAll(db, sql: "SELECT path, modified, size FROM notes") {
                    stamps[NotePath(row["path"] as String)] = FileStamp(
                        modified: Date(timeIntervalSinceReferenceDate: row["modified"]),
                        size: row["size"]
                    )
                }
                return stamps
            }
        } catch {
            throw .readFailed
        }
    }

    public func parsedNotes() async throws(IndexError) -> [NotePath: ParsedNote] {
        do {
            return try await queue.read { db in
                let decoder = JSONDecoder()
                var notes: [NotePath: ParsedNote] = [:]
                for row in try Row.fetchAll(db, sql: "SELECT path, parsed FROM notes") {
                    notes[NotePath(row["path"] as String)] = try decoder.decode(ParsedNote.self, from: row["parsed"] as Data)
                }
                return notes
            }
        } catch {
            throw .readFailed
        }
    }

    public func upsert(_ notes: [IndexedNote]) async throws(IndexError) {
        guard notes.isEmpty == false else {
            return
        }

        do {
            try await queue.write { db in
                let encoder = JSONEncoder()
                for note in notes {
                    let path = note.path.rawValue
                    try db.execute(
                        sql: """
                        INSERT INTO notes (path, modified, size, parsed) VALUES (?, ?, ?, ?)
                        ON CONFLICT(path) DO UPDATE SET modified = excluded.modified, size = excluded.size, parsed = excluded.parsed
                        """,
                        arguments: [path, note.stamp.modified.timeIntervalSinceReferenceDate, note.stamp.size, encoder.encode(note.parsed)]
                    )
                    try db.execute(sql: "DELETE FROM notes_fts WHERE path = ?", arguments: [path])
                    try db.execute(
                        sql: "INSERT INTO notes_fts (path, name, body) VALUES (?, ?, ?)",
                        arguments: [path, note.path.name, note.text]
                    )
                }
            }
        } catch {
            AppLog.error("Writing to the Index failed: \(error)")
            throw .writeFailed
        }
    }

    public func remove(_ paths: [NotePath]) async throws(IndexError) {
        guard paths.isEmpty == false else {
            return
        }

        do {
            try await queue.write { db in
                for path in paths.map(\.rawValue) {
                    try db.execute(sql: "DELETE FROM notes WHERE path = ?", arguments: [path])
                    try db.execute(sql: "DELETE FROM notes_fts WHERE path = ?", arguments: [path])
                }
            }
        } catch {
            throw .writeFailed
        }
    }

    // MARK: - Schema

    private static func openCurrentSchema(at fileURL: URL) throws -> DatabaseQueue {
        let queue = try DatabaseQueue(path: fileURL.path)
        let version = try queue.read { db in try Int.fetchOne(db, sql: "PRAGMA user_version") ?? 0 }
        guard version != schemaVersion else {
            return queue
        }

        guard version == 0 else {
            try queue.close()
            try deleteDatabase(at: fileURL)
            return try openCurrentSchema(at: fileURL)
        }

        try queue.write { db in
            try db.execute(sql: """
            CREATE TABLE notes (
                path TEXT PRIMARY KEY NOT NULL,
                modified DOUBLE NOT NULL,
                size INTEGER NOT NULL,
                parsed BLOB NOT NULL
            );
            CREATE VIRTUAL TABLE notes_fts USING fts5(path UNINDEXED, name, body, tokenize = 'unicode61 remove_diacritics 2');
            PRAGMA user_version = \(schemaVersion);
            """)
        }
        return queue
    }

    private static func deleteDatabase(at fileURL: URL) throws {
        let fileManager = FileManager()
        for suffix in ["", "-wal", "-shm", "-journal"] {
            let url = URL(filePath: fileURL.path + suffix)
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
        }
    }
}
