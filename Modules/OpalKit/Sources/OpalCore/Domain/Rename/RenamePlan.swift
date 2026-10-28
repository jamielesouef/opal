//
//  RenamePlan.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

public struct RenamePlan: Hashable, Sendable {
    // MARK: - Stored

    public let moves: [NotePath: NotePath]
    public let linkingNotes: [NotePath]

    // MARK: - Init

    public init(moves: [NotePath: NotePath], linkingNotes: [NotePath]) {
        self.moves = moves
        self.linkingNotes = linkingNotes
    }
}
