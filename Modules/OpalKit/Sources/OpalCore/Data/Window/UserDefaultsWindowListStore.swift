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
        static let statePrefix = "windowState."
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

    public func windowState(for id: UUID) -> WindowState? {
        defaults.data(forKey: key(for: id)).flatMap { try? JSONDecoder().decode(WindowState.self, from: $0) }
    }

    public func setWindowState(_ state: WindowState?, for id: UUID) {
        defaults.set(state.flatMap { try? JSONEncoder().encode($0) }, forKey: key(for: id))
    }

    // MARK: - Private

    private func key(for id: UUID) -> String {
        Constants.statePrefix + id.uuidString
    }
}
