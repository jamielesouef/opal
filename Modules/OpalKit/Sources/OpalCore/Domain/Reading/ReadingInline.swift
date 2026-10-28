//
//  ReadingInline.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

public struct ReadingInline: Hashable, Sendable {
    // MARK: - Stored

    public let text: String
    public let styles: Set<ReadingInlineStyle>
    public let link: Link?
    public let isResolved: Bool

    // MARK: - Init

    public init(text: String, styles: Set<ReadingInlineStyle> = [], link: Link? = nil, isResolved: Bool = true) {
        self.text = text
        self.styles = styles
        self.link = link
        self.isResolved = isResolved
    }
}
