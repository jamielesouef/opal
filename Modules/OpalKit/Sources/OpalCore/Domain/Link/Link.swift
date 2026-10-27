//
//  Link.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct Link: Hashable, Sendable {
    // MARK: - Stored

    public let target: String
    public let subpath: LinkSubpath?
    public let displayText: String?
    public let isEmbed: Bool
    public let style: LinkStyle
    public let span: TextSpan
    public let line: Int
    public let lineText: String

    // MARK: - Init

    public init(
        target: String,
        subpath: LinkSubpath? = nil,
        displayText: String? = nil,
        isEmbed: Bool = false,
        style: LinkStyle = .wiki,
        span: TextSpan,
        line: Int,
        lineText: String
    ) {
        self.target = target
        self.subpath = subpath
        self.displayText = displayText
        self.isEmbed = isEmbed
        self.style = style
        self.span = span
        self.line = line
        self.lineText = lineText
    }

    // MARK: - Derived

    public var pointsAtSelf: Bool {
        target.isEmpty
    }
}
