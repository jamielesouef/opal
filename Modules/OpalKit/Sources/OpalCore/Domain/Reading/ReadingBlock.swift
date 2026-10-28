//
//  ReadingBlock.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

public struct ReadingBlock: Hashable, Sendable, Identifiable {
    // MARK: - Stored

    public let line: Int
    public let kind: ReadingBlockKind

    // MARK: - Init

    public init(line: Int, kind: ReadingBlockKind) {
        self.line = line
        self.kind = kind
    }

    // MARK: - Identifiable

    public var id: Int {
        line
    }

    // MARK: - Derived

    public var isHeading: Bool {
        guard case .heading = kind else {
            return false
        }
        return true
    }

    public var inlines: [ReadingInline] {
        switch kind {
        case let .heading(_, text), let .paragraph(text), let .listItem(_, _, _, text):
            text
        case let .quote(lines):
            lines.flatMap(\.self)
        case let .callout(_, title, lines):
            title + lines.flatMap(\.self)
        case let .table(header, rows):
            header.flatMap(\.self) + rows.flatMap { $0.flatMap(\.self) }
        case .code, .rule:
            []
        }
    }
}
