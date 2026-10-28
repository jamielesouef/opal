//
//  CodeToken.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

public struct CodeToken: Hashable, Sendable {
    // MARK: - Stored

    public let span: TextSpan
    public let kind: CodeTokenKind

    // MARK: - Init

    public init(span: TextSpan, kind: CodeTokenKind) {
        self.span = span
        self.kind = kind
    }
}
