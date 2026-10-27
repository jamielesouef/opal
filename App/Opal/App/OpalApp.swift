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
        }
        .defaultSize(width: EditorMetrics.windowDefaultWidth, height: EditorMetrics.windowDefaultHeight)
        .commands {
            OpalCommands(vault: AppDependencies.shared.vaultService, notes: AppDependencies.shared.noteService)
        }
    }
}
