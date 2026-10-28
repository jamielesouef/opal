//
//  PropertyType+Display.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import OpalCore

extension PropertyType {
    // MARK: - Display

    var systemImage: String {
        switch self {
        case .text:
            "text.alignleft"
        case .list:
            "list.bullet"
        case .number:
            "number"
        case .checkbox:
            "checkmark.square"
        case .date:
            "calendar"
        case .dateTime:
            "clock"
        case .tags:
            "tag"
        case .aliases:
            "arrow.turn.up.right"
        }
    }

    var title: String {
        switch self {
        case .text:
            String(localized: "Text")
        case .list:
            String(localized: "List")
        case .number:
            String(localized: "Number")
        case .checkbox:
            String(localized: "Checkbox")
        case .date:
            String(localized: "Date")
        case .dateTime:
            String(localized: "Date and time")
        case .tags:
            String(localized: "Tags")
        case .aliases:
            String(localized: "Aliases")
        }
    }
}
