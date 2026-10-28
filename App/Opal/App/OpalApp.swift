//
//  OpalApp.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

@main
struct OpalApp: App {
    // MARK: - Environment

    @NSApplicationDelegateAdaptor(OpalAppDelegate.self) private var appDelegate

    // MARK: - Scene

    var body: some Scene {
        Window(String(localized: "Opal"), id: "main") {
            RootScreen()
                .frame(minWidth: EditorMetrics.windowMinWidth, minHeight: EditorMetrics.windowMinHeight)
                .defaultAppStorage(AppDependencies.shared.defaults)
                .environment(\.launchRequest, AppDependencies.shared.launchRequest)
        }
        .defaultSize(width: EditorMetrics.windowDefaultWidth, height: EditorMetrics.windowDefaultHeight)
        .commands {
            OpalCommands(
                vault: AppDependencies.shared.services.vault,
                notes: AppDependencies.shared.services.notes,
                navigation: AppDependencies.shared.services.navigation,
                switcher: AppDependencies.shared.services.switcher,
                search: AppDependencies.shared.services.search,
                dailyNotes: AppDependencies.shared.services.dailyNotes,
                templates: AppDependencies.shared.services.templates,
                defaults: AppDependencies.shared.defaults
            )
        }

        Settings {
            SettingsScreen()
                .defaultAppStorage(AppDependencies.shared.defaults)
        }
    }
}
