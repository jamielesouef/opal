//
//  AppDependencies.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import AppKit
import OpalCore

@MainActor
enum AppDependencies {
    // MARK: - Graph

    static let shared = makeGraph()

    private static func defaultIndexBaseURL() -> URL {
        URL.applicationSupportDirectory.appending(path: "Opal/Indexes", directoryHint: .isDirectory)
    }

    static func makeGraph() -> AppGraph {
        let arguments = LaunchArguments(ProcessInfo.processInfo.arguments)
        let defaults = arguments.defaultsSuite.flatMap(UserDefaults.init(suiteName:)) ?? .standard

        let vaultService = VaultService(
            access: SecurityScopedVaultAccess(),
            locations: UserDefaultsVaultLocationStore(defaults: defaults),
            launchVaultURL: arguments.vaultURL,
            makeWatcher: { FSEventsVaultWatcher(rootURL: $0) },
            makeStore: { FileSystemVaultStore(rootURL: $0) }
        )

        return AppGraph(
            vaultService: vaultService,
            indexBaseURL: arguments.indexFolderURL ?? defaultIndexBaseURL(),
            defaults: defaults,
            launchRequest: arguments.request,
            launchAppearance: arguments.appearanceName
        )
    }
}
