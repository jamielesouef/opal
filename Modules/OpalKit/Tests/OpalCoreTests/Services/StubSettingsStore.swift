//
//  StubSettingsStore.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation
@testable import OpalCore

final class StubSettingsStore: SettingsStoring, @unchecked Sendable {
    // MARK: - Stored

    private(set) var saved: OpalSettings?
    private let initial: OpalSettings

    // MARK: - Init

    init(_ initial: OpalSettings = .defaults) {
        self.initial = initial
    }

    // MARK: - SettingsStoring

    func settings() -> OpalSettings {
        saved ?? initial
    }

    func setSettings(_ settings: OpalSettings) {
        saved = settings
    }
}
