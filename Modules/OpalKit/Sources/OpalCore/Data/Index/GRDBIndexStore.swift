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

    public static let schemaVersion = 6

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
                    let id = try Int64.fetchOne(
                        db,
                        sql: """
                        INSERT INTO notes (path, modified, size, parsed, tags) VALUES (?, ?, ?, ?, ?)
                        ON CONFLICT(path) DO UPDATE SET
                            modified = excluded.modified, size = excluded.size, parsed = excluded.parsed, tags = excluded.tags
                        RETURNING id
                        """,
                        arguments: [
                            note.path.rawValue,
                            note.stamp.modified.timeIntervalSinceReferenceDate,
                            note.stamp.size,
                            encoder.encode(note.parsed),
                            FTSQueryBuilder.tagColumn(for: note.parsed.tags)
                        ]
                    )
                    try db.execute(sql: "DELETE FROM notes_fts WHERE rowid = ?", arguments: [id])
                    try db.execute(
                        sql: "INSERT INTO notes_fts (rowid, name, body) VALUES (?, ?, ?)",
                        arguments: [id, note.path.name, note.text]
                    )
                    try db.execute(sql: "DELETE FROM note_properties WHERE note_id = ?", arguments: [id])
                    for property in PropertyIndexUseCase.properties(in: note.text) {
                        for item in property.items.isEmpty ? [""] : property.items {
                            try db.execute(
                                sql: "INSERT INTO note_properties (note_id, name, key, type, item, folded) VALUES (?, ?, ?, ?, ?, ?)",
                                arguments: [id, property.name, FTSQueryBuilder.folded(property.name), property.type.rawValue, item, FTSQueryBuilder.folded(item)]
                            )
                        }
                    }
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
                    guard let id = try Int64.fetchOne(db, sql: "SELECT id FROM notes WHERE path = ?", arguments: [path]) else {
                        continue
                    }
                    try db.execute(sql: "DELETE FROM notes_fts WHERE rowid = ?", arguments: [id])
                    try db.execute(sql: "DELETE FROM note_properties WHERE note_id = ?", arguments: [id])
                    try db.execute(sql: "DELETE FROM notes WHERE id = ?", arguments: [id])
                }
            }
        } catch {
            throw .writeFailed
        }
    }

    public func search(_ query: SearchQuery, limit: Int) async throws(IndexError) -> [SearchHit] {
        let (sql, arguments) = Self.searchSQL(for: query, limit: limit)
        do {
            return try await queue.read { db in
                try Row.fetchAll(db, sql: sql, arguments: arguments).map { row in
                    SearchHit(path: NotePath(row["path"] as String), text: row["body"])
                }
            }
        } catch {
            AppLog.error("Searching the Index failed: \(error)")
            throw .readFailed
        }
    }

    public func propertyTypes(declared: [String: PropertyType]) async throws(IndexError) -> [String: PropertyType] {
        do {
            let counts = try await queue.read { db in
                var counts: [String: [PropertyType: Int]] = [:]
                let rows = try Row.fetchAll(db, sql: """
                SELECT name, type, COUNT(DISTINCT note_id) AS notes FROM note_properties GROUP BY name, type
                """)
                for row in rows {
                    if let type = PropertyType(rawValue: row["type"] as String) {
                        counts[row["name"] as String, default: [:]][type] = row["notes"] as Int
                    }
                }
                return counts
            }
            return PropertyIndexUseCase.resolvedTypes(counts: counts, declared: declared)
        } catch {
            throw .readFailed
        }
    }

    // MARK: - Search

    private static func searchSQL(for query: SearchQuery, limit: Int) -> (String, StatementArguments) {
        var conditions: [String] = []
        var arguments: [any DatabaseValueConvertible] = []
        if let match = FTSQueryBuilder.match(for: query) {
            conditions.append("notes_fts MATCH ?")
            arguments.append(match)
        }
        for path in query.paths {
            conditions.append("notes.path LIKE ? ESCAPE '\\'")
            arguments.append(FTSQueryBuilder.likePattern(containing: path))
        }
        for file in query.files {
            conditions.append("notes.path LIKE ? ESCAPE '\\'")
            arguments.append(FTSQueryBuilder.likePattern(containing: file))
        }
        for tag in query.tags {
            let patterns = FTSQueryBuilder.tagPatterns(for: tag)
            conditions.append("(notes.tags LIKE ? ESCAPE '\\' OR notes.tags LIKE ? ESCAPE '\\')")
            arguments.append(patterns.exact)
            arguments.append(patterns.child)
        }
        for filter in query.properties {
            var condition = "SELECT 1 FROM note_properties WHERE note_properties.note_id = notes.id AND note_properties.key = ?"
            arguments.append(FTSQueryBuilder.folded(filter.name))
            if let value = filter.value {
                condition += " AND note_properties.folded LIKE ? ESCAPE '\\'"
                arguments.append(FTSQueryBuilder.likePattern(containing: FTSQueryBuilder.folded(value)))
            }
            conditions.append((filter.isExcluded ? "NOT EXISTS (" : "EXISTS (") + condition + ")")
        }
        let order = query.hasTextTerms ? "bm25(notes_fts, 5.0, 1.0)" : "notes.path"
        let filter = conditions.isEmpty ? "1" : conditions.joined(separator: " AND ")
        let sql = """
        SELECT notes.path AS path, notes_fts.body AS body
        FROM notes_fts JOIN notes ON notes.id = notes_fts.rowid
        WHERE \(filter)
        ORDER BY \(order)
        LIMIT \(limit)
        """
        return (sql, StatementArguments(arguments))
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
                id INTEGER PRIMARY KEY,
                path TEXT NOT NULL UNIQUE,
                modified DOUBLE NOT NULL,
                size INTEGER NOT NULL,
                parsed BLOB NOT NULL,
                tags TEXT NOT NULL DEFAULT ' '
            );
            CREATE TABLE note_properties (
                note_id INTEGER NOT NULL,
                name TEXT NOT NULL,
                key TEXT NOT NULL,
                type TEXT NOT NULL,
                item TEXT NOT NULL,
                folded TEXT NOT NULL
            );
            CREATE INDEX note_properties_note ON note_properties (note_id);
            CREATE INDEX note_properties_key ON note_properties (key);
            CREATE VIRTUAL TABLE notes_fts USING fts5(name, body, tokenize = 'unicode61 remove_diacritics 2');
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
