//
//  UserDefaultsVaultLocationStore.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

public final class UserDefaultsVaultLocationStore: VaultLocationStoring, @unchecked Sendable {
    // MARK: - Constants

    private enum Constants {
        static let lastVaultBookmarkKey = "lastVaultBookmark"
    }

    // MARK: - Private

    private let defaults: UserDefaults

    // MARK: - Init

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    // MARK: - VaultLocationStoring

    public func lastVaultBookmark() -> Data? {
        defaults.data(forKey: Constants.lastVaultBookmarkKey)
    }

    public func setLastVaultBookmark(_ bookmark: Data?) {
        defaults.set(bookmark, forKey: Constants.lastVaultBookmarkKey)
    }
}
