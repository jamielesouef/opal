//
//  IndexSyncPlan.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct IndexSyncPlan: Hashable, Sendable {
    // MARK: - Stored

    public let toRead: [NotePath]
    public let toRemove: [NotePath]

    // MARK: - Init

    public init(toRead: [NotePath], toRemove: [NotePath]) {
        self.toRead = toRead
        self.toRemove = toRemove
    }

    // MARK: - Derived

    public var isEmpty: Bool {
        toRead.isEmpty && toRemove.isEmpty
    }
}
