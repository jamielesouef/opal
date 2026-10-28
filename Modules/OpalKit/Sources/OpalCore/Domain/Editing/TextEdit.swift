//
//  TextEdit.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

public struct TextEdit: Hashable, Sendable {
    // MARK: - Stored

    public let span: TextSpan
    public let replacement: String

    // MARK: - Init

    public init(span: TextSpan, replacement: String) {
        self.span = span
        self.replacement = replacement
    }
}
