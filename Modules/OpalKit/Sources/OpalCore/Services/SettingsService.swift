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
        didSet {
            guard settings != oldValue else {
                return
            }

            for vault in vaults {
                vault.opalSettings = settings
            }
            store.setSettings(settings)
        }
    }

    public private(set) var activeVault: VaultService?

    public var vaultSettings: VaultSettings {
        activeVault?.vaultSettings ?? VaultSettings()
    }

    public var isVaultOpen: Bool {
        activeVault?.isOpen == true
    }

    // MARK: - Private

    private let store: any SettingsStoring
    private let clock: any Clocking
    private var vaults: [VaultService] = []

    // MARK: - Init

    public init(store: any SettingsStoring, clock: any Clocking) {
        self.store = store
        self.clock = clock
        settings = store.settings()
    }

    // MARK: - Vaults

    public func attach(_ vault: VaultService) {
        vault.opalSettings = settings
        if vaults.contains(where: { $0 === vault }) == false {
            vaults.append(vault)
        }
        activeVault = vault
    }

    public func activate(_ vault: VaultService) {
        if vaults.contains(where: { $0 === vault }) {
            activeVault = vault
        }
    }

    public func detach(_ vault: VaultService) {
        vaults.removeAll { $0 === vault }
        if activeVault === vault {
            activeVault = vaults.last
        }
    }

    // MARK: - Reads

    public func dailyNotePreview(format: String) -> String {
        MomentFormatUseCase.string(from: clock.now, format: format.isEmpty ? DailyNoteSettings.defaults.format : format, timeZone: clock.timeZone)
    }
}
