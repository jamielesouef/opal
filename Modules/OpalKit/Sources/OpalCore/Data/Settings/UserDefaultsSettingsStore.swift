//
//  UserDefaultsSettingsStore.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation

public final class UserDefaultsSettingsStore: SettingsStoring, @unchecked Sendable {
    // MARK: - Constants

    private enum Constants {
        static let key = "settings"
    }

    // MARK: - Private

    private let defaults: UserDefaults

    // MARK: - Init

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    // MARK: - SettingsStoring

    public func settings() -> OpalSettings {
        guard let data = defaults.data(forKey: Constants.key) else {
            return .defaults
        }

        do {
            return try JSONDecoder().decode(OpalSettings.self, from: data)
        } catch {
            AppLog.error("Reading Settings failed: \(error)")
            return .defaults
        }
    }

    public func setSettings(_ settings: OpalSettings) {
        do {
            try defaults.set(JSONEncoder().encode(settings), forKey: Constants.key)
        } catch {
            AppLog.error("Saving Settings failed: \(error)")
        }
    }
}
