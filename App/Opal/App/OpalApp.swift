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
        WindowGroup(for: UUID.self) { $id in
            WindowScreen(id: id ?? AppDependencies.shared.windows.firstWindowID)
                .frame(minWidth: EditorMetrics.windowMinWidth, minHeight: EditorMetrics.windowMinHeight)
                .defaultAppStorage(AppDependencies.shared.defaults)
        } defaultValue: {
            AppDependencies.shared.windows.defaultWindowID()
        }
        .defaultSize(width: EditorMetrics.windowDefaultWidth, height: EditorMetrics.windowDefaultHeight)
        .restorationBehavior(.disabled)
        .commands {
            OpalCommands(
                windows: AppDependencies.shared.windows,
                recents: AppDependencies.shared.recents,
                placeholder: AppDependencies.shared.placeholder,
                defaults: AppDependencies.shared.defaults
            )
        }

        Settings {
            SettingsScreen()
                .defaultAppStorage(AppDependencies.shared.defaults)
        }
    }
}
