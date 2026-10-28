//
//  SettingsScreen.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import SwiftUI

struct SettingsScreen: View {
    // MARK: - Constants

    private enum Constants {
        static let width: CGFloat = 520
    }

    // MARK: - State

    @AppStorage(EditorPreferences.settingsTabKey) private var tab = SettingsTab.editor

    // MARK: - View

    var body: some View {
        TabView(selection: $tab) {
            ForEach(SettingsTab.allCases) { tab in
                content(tab)
                    .tabItem { Label(tab.title, systemImage: tab.systemImage) }
                    .tag(tab)
            }
        }
        .frame(width: Constants.width)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Tabs

    @ViewBuilder
    private func content(_ tab: SettingsTab) -> some View {
        switch tab {
        case .editor:
            EditorSettingsView()
        case .filesAndLinks:
            FilesAndLinksSettingsView()
        case .dailyNotes:
            DailyNoteSettingsView()
        case .appearance:
            AppearanceSettingsView()
        }
    }
}
