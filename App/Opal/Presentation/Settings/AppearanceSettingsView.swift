//
//  AppearanceSettingsView.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import SwiftUI

struct AppearanceSettingsView: View {
    // MARK: - State

    @AppStorage(EditorPreferences.appearanceKey) private var appearance = AppearanceChoice.system

    // MARK: - View

    var body: some View {
        Form {
            Picker(String(localized: "Appearance"), selection: $appearance) {
                ForEach(AppearanceChoice.allCases) { choice in
                    Text(choice.title).tag(choice)
                }
            }
            .pickerStyle(.radioGroup)
        }
        .formStyle(.grouped)
    }
}
