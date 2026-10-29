//
//  UserDefaultsRecentNotesStore.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

public final class UserDefaultsRecentNotesStore: RecentNotesStoring, @unchecked Sendable {
    // MARK: - Constants

    private enum Constants {
        static let keyPrefix = "recentNotes."
    }

    // MARK: - Private

    private let defaults: UserDefaults

    // MARK: - Init

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    // MARK: - RecentNotesStoring

    public func recentNotes(forVaultAt rootURL: URL) -> [NotePath] {
        (defaults.stringArray(forKey: key(for: rootURL)) ?? []).map(NotePath.init)
    }

    public func setRecentNotes(_ paths: [NotePath], forVaultAt rootURL: URL) {
        defaults.set(paths.map(\.rawValue), forKey: key(for: rootURL))
    }

    // MARK: - Private

    private func key(for rootURL: URL) -> String {
        Constants.keyPrefix + rootURL.standardizedFileURL.path
    }
}
