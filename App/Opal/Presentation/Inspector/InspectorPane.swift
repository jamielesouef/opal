//
//  InspectorPane.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

enum InspectorPane: String, CaseIterable, Identifiable {
    case backlinks
    case outgoing
    case outline

    // MARK: - Identifiable

    var id: Self {
        self
    }

    // MARK: - Display

    var title: String {
        switch self {
        case .backlinks:
            String(localized: "Backlinks")
        case .outgoing:
            String(localized: "Outgoing")
        case .outline:
            String(localized: "Outline")
        }
    }
}
