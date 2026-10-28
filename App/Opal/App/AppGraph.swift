//
//  AppGraph.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import AppKit
import OpalCore

@MainActor
struct AppGraph {
    // MARK: - Services

    let services: ServiceGraph

    // MARK: - Launch

    let launchRequest: LaunchRequest
    let launchAppearance: NSAppearance.Name?
    let launchSnapshotURL: URL?
    let defaults: UserDefaults

    // MARK: - Init

    init(
        vaultService: VaultService,
        indexBaseURL: URL,
        defaults: UserDefaults,
        launchRequest: LaunchRequest = LaunchRequest(),
        launchAppearance: NSAppearance.Name? = nil,
        launchSnapshotURL: URL? = nil
    ) {
        services = ServiceGraph(
            vault: vaultService,
            makeIndex: { root throws(IndexError) in
                try GRDBIndexStore(folderURL: IndexLocation.folder(forVaultAt: root, in: indexBaseURL))
            },
            recents: UserDefaultsRecentNotesStore(defaults: defaults),
            settingsStore: UserDefaultsSettingsStore(defaults: defaults),
            clock: SystemClock()
        )
        self.launchRequest = launchRequest
        self.launchAppearance = launchAppearance
        self.launchSnapshotURL = launchSnapshotURL
        self.defaults = defaults
    }
}
