//
//  SwitcherMatch.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct SwitcherMatch: Hashable, Sendable, Identifiable {
    // MARK: - Stored

    public let path: NotePath
    public let matchedAlias: String?
    public let score: Int

    // MARK: - Init

    public init(path: NotePath, matchedAlias: String? = nil, score: Int = 0) {
        self.path = path
        self.matchedAlias = matchedAlias
        self.score = score
    }

    // MARK: - Identifiable

    public var id: NotePath {
        path
    }
}
