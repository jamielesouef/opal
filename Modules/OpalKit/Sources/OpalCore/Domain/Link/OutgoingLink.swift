//
//  OutgoingLink.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct OutgoingLink: Hashable, Sendable {
    // MARK: - Stored

    public let link: Link
    public let target: NotePath?

    // MARK: - Init

    public init(link: Link, target: NotePath?) {
        self.link = link
        self.target = target
    }

    // MARK: - Derived

    public var isResolved: Bool {
        target != nil
    }
}
