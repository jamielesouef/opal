//
//  Heading.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct Heading: Hashable, Sendable {
    // MARK: - Stored

    public let level: Int
    public let text: String
    public let line: Int

    // MARK: - Init

    public init(level: Int, text: String, line: Int) {
        self.level = level
        self.text = text
        self.line = line
    }
}
