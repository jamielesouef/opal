//
//  MarkdownCheckbox.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import AppKit
import OpalDesign

enum MarkdownCheckbox {
    // MARK: - Attribute

    static let key = NSAttributedString.Key("OpalMarkdownCheckbox")

    // MARK: - Colour

    static func textColor(isDone: Bool, isActive: Bool) -> NSColor {
        guard isActive else {
            return .clear
        }

        return isDone ? AppKitColor.secondaryText : AppKitColor.accent
    }
}
