//
//  BacklinkGroup.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct BacklinkGroup: Hashable, Sendable, Identifiable {
    // MARK: - Stored

    public let source: NotePath
    public let backlinks: [Backlink]

    // MARK: - Init

    public init(source: NotePath, backlinks: [Backlink]) {
        self.source = source
        self.backlinks = backlinks
    }

    // MARK: - Identifiable

    public var id: NotePath {
        source
    }
}
