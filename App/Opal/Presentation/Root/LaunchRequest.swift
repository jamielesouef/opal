//
//  LaunchRequest.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import OpalCore

struct LaunchRequest {
    // MARK: - Stored

    var note: NotePath?
    var quickOpen: String?
    var search: String?
    var sidebarPane: SidebarPane?
    var typeText: String?
    var isReadingView = false
    var opensDailyNote = false
}
