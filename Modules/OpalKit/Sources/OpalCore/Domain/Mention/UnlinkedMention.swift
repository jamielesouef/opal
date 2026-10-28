//
//  UnlinkedMention.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct UnlinkedMention: Hashable, Sendable, Identifiable {
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

    // MARK: - Identifiable

    public var id: String {
        "\(source.rawValue)#\(span.location)"
    }

    // MARK: - Hashable

    public static func == (lhs: UnlinkedMention, rhs: UnlinkedMention) -> Bool {
        lhs.span == rhs.span && lhs.line == rhs.line && lhs.source == rhs.source
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(source)
        hasher.combine(span)
    }
}
