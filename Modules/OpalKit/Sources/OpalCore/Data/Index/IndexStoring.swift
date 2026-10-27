//
//  IndexStoring.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public protocol IndexStoring: Sendable {
    func stamps() async throws(IndexError) -> [NotePath: FileStamp]
    func parsedNotes() async throws(IndexError) -> [NotePath: ParsedNote]
    func upsert(_ notes: [IndexedNote]) async throws(IndexError)
    func remove(_ paths: [NotePath]) async throws(IndexError)
    func search(_ query: SearchQuery, limit: Int) async throws(IndexError) -> [SearchHit]
}
