//
//  SearchResult.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct SearchResult: Hashable, Sendable, Identifiable {
    // MARK: - Stored

    public let path: NotePath
    public let lines: [SearchLine]
    public let matchCount: Int

    // MARK: - Init

    public init(path: NotePath, lines: [SearchLine], matchCount: Int) {
        self.path = path
        self.lines = lines
        self.matchCount = matchCount
    }

    // MARK: - Identifiable

    public var id: NotePath {
        path
    }
}
