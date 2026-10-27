//
//  AppDependencies.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import OpalCore

@MainActor
enum AppDependencies {
    // MARK: - Graph

    static let shared = makeGraph()

    static func makeGraph() -> AppGraph {
        let arguments = LaunchArguments(ProcessInfo.processInfo.arguments)
        let defaults = arguments.defaultsSuite.flatMap(UserDefaults.init(suiteName:)) ?? .standard

        let vaultService = VaultService(
            access: SecurityScopedVaultAccess(),
            locations: UserDefaultsVaultLocationStore(defaults: defaults),
            launchVaultURL: arguments.vaultURL
        ) { FileSystemVaultStore(rootURL: $0) }

        return AppGraph(vaultService: vaultService, noteService: NoteService(vault: vaultService))
    }
}
