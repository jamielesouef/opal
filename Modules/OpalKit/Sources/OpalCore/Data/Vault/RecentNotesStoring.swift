//
//  RecentNotesStoring.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

public protocol RecentNotesStoring: Sendable {
    func recentNotes(forVaultAt rootURL: URL) async -> [NotePath]
    func setRecentNotes(_ paths: [NotePath], forVaultAt rootURL: URL) async
    func openTabs(forVaultAt rootURL: URL) async -> [NotePath]
    func setOpenTabs(_ paths: [NotePath], forVaultAt rootURL: URL) async
}
