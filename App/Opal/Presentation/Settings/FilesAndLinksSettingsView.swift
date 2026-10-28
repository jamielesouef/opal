//
//  FilesAndLinksSettingsView.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import OpalCore
import SwiftUI

struct FilesAndLinksSettingsView: View {
    // MARK: - Environment

    @Environment(\.settingsService) private var settings

    // MARK: - View

    var body: some View {
        let vault = settings.vaultSettings
        Form {
            Section {
                SetByVaultNote(isSet: vault.newFileLocation != nil) {
                    Picker(String(localized: "Where new Notes go"), selection: settings.binding(\.newFileLocation, vaultValue: vault.newFileLocation)) {
                        ForEach(NewFileLocation.allCases, id: \.self) { location in
                            Text(title(of: location)).tag(location)
                        }
                    }
                }
                if (vault.newFileLocation ?? settings.settings.newFileLocation) == .folder {
                    SetByVaultNote(isSet: vault.newFileFolderPath != nil) {
                        TextField(String(localized: "Folder for new Notes"), text: settings.binding(\.newFileFolderPath, vaultValue: vault.newFileFolderPath))
                    }
                }
                SetByVaultNote(isSet: vault.attachmentFolderPath != nil) {
                    TextField(String(localized: "Attachment Folder"), text: settings.binding(\.attachmentFolderPath, vaultValue: vault.attachmentFolderPath))
                        .help(String(localized: "“/” is the Vault root, and “./” is the Folder of the Note"))
                }
            }
            Section {
                SetByVaultNote(isSet: vault.useMarkdownLinks != nil) {
                    Toggle(String(localized: "Use Markdown Links"), isOn: settings.binding(\.useMarkdownLinks, vaultValue: vault.useMarkdownLinks))
                        .help(String(localized: "Write [name](Note.md) instead of [[Note]]"))
                }
                SetByVaultNote(isSet: vault.alwaysUpdateLinks != nil) {
                    Picker(
                        String(localized: "Update Links when a Note or Folder is renamed or moved"),
                        selection: settings.binding(\.linkUpdate, vaultValue: vault.alwaysUpdateLinks.map { $0 ? .always : .ask })
                    ) {
                        ForEach(LinkUpdate.allCases, id: \.self) { choice in
                            Text(title(of: choice)).tag(choice)
                        }
                    }
                }
            } footer: {
                if settings.isVaultOpen == false {
                    Text(String(localized: "Open a Vault to see its Obsidian settings."))
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Titles

    private func title(of location: NewFileLocation) -> String {
        switch location {
        case .root:
            String(localized: "Vault root")
        case .current:
            String(localized: "Same Folder as the open Note")
        case .folder:
            String(localized: "In this Folder")
        }
    }

    private func title(of choice: LinkUpdate) -> String {
        switch choice {
        case .ask:
            String(localized: "Ask")
        case .always:
            String(localized: "Always")
        case .never:
            String(localized: "Never")
        }
    }
}
