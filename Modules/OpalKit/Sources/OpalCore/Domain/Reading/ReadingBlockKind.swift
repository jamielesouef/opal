//
//  ReadingBlockKind.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

public enum ReadingBlockKind: Hashable, Sendable {
    case heading(level: Int, text: [ReadingInline])
    case paragraph([ReadingInline])
    case listItem(marker: String, depth: Int, checkbox: Bool?, text: [ReadingInline])
    case quote(lines: [[ReadingInline]])
    case callout(type: String, title: [ReadingInline], lines: [[ReadingInline]])
    case code(language: String?, text: String)
    case table(header: [[ReadingInline]], rows: [[[ReadingInline]]])
    case rule
    case embed(Link)
}
