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
    // MARK: - App-wide

    let windows: WindowRegistry
    let settings: SettingsService
    let placeholder: ServiceGraph

    // MARK: - Launch

    let launchRequest: LaunchRequest
    let launchVaultURL: URL?
    let restoresState: Bool
    let launchAppearance: NSAppearance.Name?
    let launchSnapshotURL: URL?
    let defaults: UserDefaults

    // MARK: - Init

    init(
        makeVault: @escaping @MainActor (_ windowID: UUID, _ isFirst: Bool) -> VaultService,
        indexBaseURL: URL,
        defaults: UserDefaults,
        launchRequest: LaunchRequest = LaunchRequest(),
        launchVaultURL: URL? = nil,
        restoresState: Bool = true,
        launchAppearance: NSAppearance.Name? = nil,
        launchSnapshotURL: URL? = nil
    ) {
        let settings = SettingsService(store: UserDefaultsSettingsStore(defaults: defaults), clock: SystemClock())
        let recents = UserDefaultsRecentNotesStore(defaults: defaults)
        let windowStore = UserDefaultsWindowListStore(defaults: defaults)
        let makeGraph: @MainActor (VaultService, UUID) -> ServiceGraph = { vault, windowID in
            ServiceGraph(
                vault: vault,
                makeIndex: { root throws(IndexError) in
                    try GRDBIndexStore(folderURL: IndexLocation.folder(forVaultAt: root, in: indexBaseURL))
                },
                recents: recents,
                windowID: windowID,
                windows: windowStore,
                settings: settings,
                clock: SystemClock()
            )
        }
        self.settings = settings
        windows = WindowRegistry(store: windowStore) { id, isFirst in
            makeGraph(makeVault(id, isFirst), id)
        }
        let placeholderID = UUID()
        placeholder = makeGraph(makeVault(placeholderID, false), placeholderID)
        settings.detach(placeholder.vault)
        self.launchRequest = launchRequest
        self.launchVaultURL = launchVaultURL
        self.restoresState = restoresState
        self.launchAppearance = launchAppearance
        self.launchSnapshotURL = launchSnapshotURL
        self.defaults = defaults
    }
}
