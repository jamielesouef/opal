//
//  SwitcherCandidate.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct SwitcherCandidate: Hashable, Sendable {
    // MARK: - Stored

    public let path: NotePath
    public let aliases: [String]

    // MARK: - Init

    public init(path: NotePath, aliases: [String] = []) {
        self.path = path
        self.aliases = aliases
    }
}
