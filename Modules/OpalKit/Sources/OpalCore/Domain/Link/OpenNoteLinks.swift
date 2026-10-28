//
//  OpenNoteLinks.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct OpenNoteLinks: Sendable, Equatable {
    // MARK: - Stored

    public let path: NotePath
    public let textLength: Int
    public let parsed: ParsedNote
    public let styles: [TextStyleRun]

    // MARK: - Init

    public init(path: NotePath, textLength: Int, parsed: ParsedNote, styles: [TextStyleRun]) {
        self.path = path
        self.textLength = textLength
        self.parsed = parsed
        self.styles = styles
    }
}
