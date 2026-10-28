//
//  Frontmatter.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

public struct Frontmatter: Hashable, Sendable {
    // MARK: - Stored

    public let properties: [Property]
    public let endLine: Int
    public let isReadable: Bool

    // MARK: - Init

    public init(properties: [Property], endLine: Int, isReadable: Bool) {
        self.properties = properties
        self.endLine = endLine
        self.isReadable = isReadable
    }
}
