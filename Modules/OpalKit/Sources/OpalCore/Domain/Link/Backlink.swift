//
//  Backlink.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct Backlink: Hashable, Sendable {
    // MARK: - Stored

    public let source: NotePath
    public let link: Link

    // MARK: - Init

    public init(source: NotePath, link: Link) {
        self.source = source
        self.link = link
    }
}
