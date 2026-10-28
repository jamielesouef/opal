//
//  MarkdownBlock.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import AppKit

enum MarkdownBlock: String {
    case quote
    case callout
    case code

    // MARK: - Attribute

    static let key = NSAttributedString.Key("OpalMarkdownBlock")
}
