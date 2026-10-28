//
//  SettingsService.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation
import Observation

@MainActor
@Observable
public final class SettingsService {
    // MARK: - State

    public var settings: OpalSettings {
        get { vault.opalSettings }
        set {
            guard newValue != vault.opalSettings else {
                return
            }

            vault.opalSettings = newValue
            store.setSettings(newValue)
        }
    }

    public var vaultSettings: VaultSettings {
        vault.vaultSettings
    }

    public var isVaultOpen: Bool {
        vault.isOpen
    }

    // MARK: - Private

    private let vault: VaultService
    private let store: any SettingsStoring
    private let clock: any Clocking

    // MARK: - Init

    public init(vault: VaultService, store: any SettingsStoring, clock: any Clocking) {
        self.vault = vault
        self.store = store
        self.clock = clock
    }

    // MARK: - Intent

    public func load() {
        vault.opalSettings = store.settings()
    }

    // MARK: - Reads

    public func dailyNotePreview(format: String) -> String {
        MomentFormatUseCase.string(from: clock.now, format: format.isEmpty ? DailyNoteSettings.defaults.format : format, timeZone: clock.timeZone)
    }
}
