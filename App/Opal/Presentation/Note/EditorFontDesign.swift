//
//  EditorFontDesign.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import AppKit

enum EditorFontDesign: String, CaseIterable, Identifiable {
    case system
    case serif
    case rounded
    case monospaced

    // MARK: - Identifiable

    var id: String {
        rawValue
    }

    // MARK: - Display

    var title: String {
        switch self {
        case .system:
            String(localized: "System")
        case .serif:
            String(localized: "Serif")
        case .rounded:
            String(localized: "Rounded")
        case .monospaced:
            String(localized: "Monospaced")
        }
    }

    var design: NSFontDescriptor.SystemDesign {
        switch self {
        case .system:
            .default
        case .serif:
            .serif
        case .rounded:
            .rounded
        case .monospaced:
            .monospaced
        }
    }
}
