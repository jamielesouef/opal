//
//  SettingsTab.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

enum SettingsTab: String, CaseIterable, Identifiable {
    case editor
    case filesAndLinks = "files"
    case dailyNotes = "daily"
    case appearance

    // MARK: - Identifiable

    var id: String {
        rawValue
    }

    // MARK: - Display

    var title: String {
        switch self {
        case .editor:
            String(localized: "Editor")
        case .filesAndLinks:
            String(localized: "Files and Links")
        case .dailyNotes:
            String(localized: "Daily Notes")
        case .appearance:
            String(localized: "Appearance")
        }
    }

    var systemImage: String {
        switch self {
        case .editor:
            "textformat"
        case .filesAndLinks:
            "link"
        case .dailyNotes:
            "calendar"
        case .appearance:
            "circle.lefthalf.filled"
        }
    }
}
