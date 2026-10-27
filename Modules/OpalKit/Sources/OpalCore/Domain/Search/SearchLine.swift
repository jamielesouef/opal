//
//  SearchLine.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct SearchLine: Hashable, Sendable {
    // MARK: - Stored

    public let line: Int
    public let text: String
    public let highlights: [TextSpan]

    // MARK: - Init

    public init(line: Int, text: String, highlights: [TextSpan]) {
        self.line = line
        self.text = text
        self.highlights = highlights
    }
}
