//
//  UserDefaultsWindowListStore.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation

public final class UserDefaultsWindowListStore: WindowListStoring, @unchecked Sendable {
    // MARK: - Constants

    private enum Constants {
        static let key = "openWindows"
    }

    // MARK: - Private

    private let defaults: UserDefaults

    // MARK: - Init

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    // MARK: - WindowListStoring

    public func windowIDs() -> [UUID] {
        (defaults.stringArray(forKey: Constants.key) ?? []).compactMap(UUID.init(uuidString:))
    }

    public func setWindowIDs(_ ids: [UUID]) {
        defaults.set(ids.map(\.uuidString), forKey: Constants.key)
    }
}
