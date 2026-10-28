//
//  TextStyleRun.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct TextStyleRun: Hashable, Sendable {
    // MARK: - Stored

    public let span: TextSpan
    public let kind: TextStyleKind

    // MARK: - Init

    public init(span: TextSpan, kind: TextStyleKind) {
        self.span = span
        self.kind = kind
    }
}
