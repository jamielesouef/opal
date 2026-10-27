//
//  LinkHighlight.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct LinkHighlight: Hashable, Sendable {
    // MARK: - Stored

    public let span: TextSpan
    public let isResolved: Bool

    // MARK: - Init

    public init(span: TextSpan, isResolved: Bool) {
        self.span = span
        self.isResolved = isResolved
    }
}
