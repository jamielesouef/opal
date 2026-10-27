//
//  SidebarPane+Display.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore

extension SidebarPane {
    // MARK: - Display

    var title: String {
        switch self {
        case .files:
            String(localized: "Files")
        case .search:
            String(localized: "Search")
        case .tags:
            String(localized: "Tags")
        }
    }

    var systemImage: String {
        switch self {
        case .files:
            "folder"
        case .search:
            "magnifyingglass"
        case .tags:
            "number"
        }
    }
}
