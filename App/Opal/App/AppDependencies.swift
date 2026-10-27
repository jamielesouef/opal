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

        let appearance: NSAppearance.Name? = switch arguments.appearance {
        case "light":
            .aqua
        case "dark":
            .darkAqua
        default:
            nil
        }

        return AppGraph(
            vaultService: vaultService,
            defaults: defaults,
            launchNote: arguments.openNote,
            launchAppearance: appearance,
            launchQuickOpen: arguments.quickOpen,
            launchTypeText: arguments.typeText
        )
    }
}
