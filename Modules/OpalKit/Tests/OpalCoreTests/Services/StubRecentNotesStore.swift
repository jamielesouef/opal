//
//  StubRecentNotesStore.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
@testable import OpalCore

actor StubRecentNotesStore: RecentNotesStoring {
    // MARK: - Stored

    private(set) var stored: [URL: [NotePath]] = [:]
    private(set) var tabs: [URL: [NotePath]] = [:]

    // MARK: - RecentNotesStoring

    func recentNotes(forVaultAt rootURL: URL) -> [NotePath] {
        stored[rootURL] ?? []
    }

    func setRecentNotes(_ paths: [NotePath], forVaultAt rootURL: URL) {
        stored[rootURL] = paths
    }

    func openTabs(forVaultAt rootURL: URL) -> [NotePath] {
        tabs[rootURL] ?? []
    }

    func setOpenTabs(_ paths: [NotePath], forVaultAt rootURL: URL) {
        tabs[rootURL] = paths
    }
}
