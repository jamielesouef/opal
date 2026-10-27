//
//  ParsedNote.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct ParsedNote: Hashable, Sendable {
    // MARK: - Constants

    public static let empty = ParsedNote(links: [], headings: [], blocks: [], aliases: [])

    // MARK: - Stored

    public let links: [Link]
    public let headings: [Heading]
    public let blocks: [Block]
    public let aliases: [String]

    // MARK: - Init

    public init(links: [Link], headings: [Heading], blocks: [Block], aliases: [String]) {
        self.links = links
        self.headings = headings
        self.blocks = blocks
        self.aliases = aliases
    }
}
