//
//  ParsedNote.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct ParsedNote: Hashable, Sendable, Codable {
    // MARK: - Constants

    public static let empty = ParsedNote(links: [], headings: [], blocks: [], aliases: [], tags: [], skippedSpans: [])

    // MARK: - Stored

    public let links: [Link]
    public let headings: [Heading]
    public let blocks: [Block]
    public let aliases: [String]
    public let tags: [String]
    public let skippedSpans: [TextSpan]

    // MARK: - Init

    public init(links: [Link], headings: [Heading], blocks: [Block], aliases: [String], tags: [String] = [], skippedSpans: [TextSpan] = []) {
        self.links = links
        self.headings = headings
        self.blocks = blocks
        self.aliases = aliases
        self.tags = tags
        self.skippedSpans = skippedSpans
    }
}
