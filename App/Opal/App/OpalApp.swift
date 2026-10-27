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

    // MARK: - Launch

    private static var launchTypeText: String? {
        #if DEBUG
            AppDependencies.shared.launchTypeText
        #else
            nil
        #endif
    }

    // MARK: - Scene

    var body: some Scene {
        Window(String(localized: "Opal"), id: "main") {
            RootScreen(
                launchNote: AppDependencies.shared.launchNote,
                launchQuickOpen: AppDependencies.shared.launchQuickOpen,
                launchSearch: AppDependencies.shared.launchSearch,
                launchSidebarPane: AppDependencies.shared.launchSidebarPane
            )
                .frame(minWidth: EditorMetrics.windowMinWidth, minHeight: EditorMetrics.windowMinHeight)
                .defaultAppStorage(AppDependencies.shared.defaults)
                .environment(\.launchTypeText, Self.launchTypeText)
        }
        .defaultSize(width: EditorMetrics.windowDefaultWidth, height: EditorMetrics.windowDefaultHeight)
        .commands {
            OpalCommands(
                vault: AppDependencies.shared.vaultService,
                notes: AppDependencies.shared.noteService,
                navigation: AppDependencies.shared.navigationService,
                switcher: AppDependencies.shared.quickSwitcherService,
                search: AppDependencies.shared.searchService
            )
        }
    }
}
