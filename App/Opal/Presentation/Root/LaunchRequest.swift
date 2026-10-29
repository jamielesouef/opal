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
    var showsTemplates = false
    var renaming: NotePath?
    var moving: NotePath?
    var deleting: NotePath?
    var showsCommandPalette = false
    var extraTabs: [NotePath] = []
    var splitNote: NotePath?
    var splitShare: Double?
    var hidesInspector = false
    var settingsTab: String?
    var opensNewWindow = false
}
