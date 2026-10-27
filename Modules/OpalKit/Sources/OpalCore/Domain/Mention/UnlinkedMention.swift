//
//  UnlinkedMention.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct UnlinkedMention: Hashable, Sendable {
    // MARK: - Stored

    public let source: NotePath
    public let span: TextSpan
    public let matchedText: String
    public let line: Int
    public let lineText: String

    // MARK: - Init

    public init(source: NotePath, span: TextSpan, matchedText: String, line: Int, lineText: String) {
        self.source = source
        self.span = span
        self.matchedText = matchedText
        self.line = line
        self.lineText = lineText
    }
}
