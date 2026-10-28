//
//  DailyNoteSettingsView.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import OpalCore
import SwiftUI

struct DailyNoteSettingsView: View {
    // MARK: - Environment

    @Environment(\.settingsService) private var settings

    // MARK: - View

    var body: some View {
        let vault = settings.vaultSettings
        let format = vault.dailyFormat ?? settings.settings.dailyFormat
        Form {
            Section {
                SetByVaultNote(isSet: vault.dailyFolder != nil) {
                    TextField(String(localized: "Folder"), text: settings.binding(\.dailyFolder, vaultValue: vault.dailyFolder), prompt: Text(String(localized: "Vault root")))
                }
                SetByVaultNote(isSet: vault.dailyFormat != nil) {
                    TextField(String(localized: "Date format"), text: settings.binding(\.dailyFormat, vaultValue: vault.dailyFormat), prompt: Text(DailyNoteSettings.defaults.format))
                }
                LabeledContent(String(localized: "Today")) {
                    Text(settings.dailyNotePreview(format: format))
                        .textSelection(.enabled)
                }
                SetByVaultNote(isSet: vault.dailyTemplate != nil) {
                    TextField(String(localized: "Template"), text: settings.binding(\.dailyTemplate, vaultValue: vault.dailyTemplate), prompt: Text(String(localized: "No Template")))
                }
            } footer: {
                if settings.isVaultOpen == false {
                    Text(String(localized: "Open a Vault to see its Obsidian settings."))
                }
            }
        }
        .formStyle(.grouped)
    }
}
