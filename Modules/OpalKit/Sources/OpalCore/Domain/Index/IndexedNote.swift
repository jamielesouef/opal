//
//  IndexedNote.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct IndexedNote: Hashable, Sendable {
    // MARK: - Stored

    public let path: NotePath
    public let stamp: FileStamp
    public let parsed: ParsedNote
    public let text: String

    // MARK: - Init

    public init(path: NotePath, stamp: FileStamp, parsed: ParsedNote, text: String) {
        self.path = path
        self.stamp = stamp
        self.parsed = parsed
        self.text = text
    }
}
