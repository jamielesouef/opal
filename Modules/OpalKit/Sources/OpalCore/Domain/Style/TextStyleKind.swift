//
//  TextStyleKind.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

public enum TextStyleKind: Hashable, Sendable {
    case link(isResolved: Bool)
    case mark
    case heading(level: Int)
    case bold
    case italic
    case strikethrough
    case highlight
    case inlineCode
    case codeBlock
    case quote
    case callout
    case calloutTitle
    case listMarker
    case checkbox(isDone: Bool)
    case doneTask
    case horizontalRule
    case tag
    case frontmatter

    // MARK: - Derived

    public var isLink: Bool {
        guard case .link = self else {
            return false
        }
        return true
    }

    public var isCheckbox: Bool {
        guard case .checkbox = self else {
            return false
        }
        return true
    }
}
