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
        static let recentVaultsKey = "recentVaults"
    }

    // MARK: - Private

    private let defaults: UserDefaults
    private let key: String
    private let fallbackKey: String?

    // MARK: - Init

    public init(defaults: UserDefaults) {
        self.defaults = defaults
        key = Constants.lastVaultBookmarkKey
        fallbackKey = nil
    }

    public init(defaults: UserDefaults, windowID: UUID, fallsBackToLastVault: Bool) {
        self.defaults = defaults
        key = Constants.lastVaultBookmarkKey + "." + windowID.uuidString
        fallbackKey = fallsBackToLastVault ? Constants.lastVaultBookmarkKey : nil
    }

    // MARK: - VaultLocationStoring

    public func lastVaultBookmark() -> Data? {
        defaults.data(forKey: key) ?? fallbackKey.flatMap(defaults.data(forKey:))
    }

    public func setLastVaultBookmark(_ bookmark: Data?) {
        defaults.set(bookmark, forKey: key)
    }

    public func recentVaults() -> [RecentVaultRecord] {
        defaults.data(forKey: Constants.recentVaultsKey).flatMap { try? JSONDecoder().decode([RecentVaultRecord].self, from: $0) } ?? []
    }

    public func setRecentVaults(_ records: [RecentVaultRecord]) {
        defaults.set(try? JSONEncoder().encode(records), forKey: Constants.recentVaultsKey)
    }
}
