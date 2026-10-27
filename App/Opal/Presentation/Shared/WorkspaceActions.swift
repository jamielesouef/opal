//
//  WorkspaceActions.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import AppKit

@MainActor
enum WorkspaceActions {
    // MARK: - Finder

    static func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    static func openInDefaultApp(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}
