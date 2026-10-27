//
//  OpalCommands.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import SwiftUI

struct OpalCommands: Commands {
    // MARK: - Dependencies

    let vault: VaultService
    let notes: NoteService
    let navigation: NavigationService
    let switcher: QuickSwitcherService

    // MARK: - Commands

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button(String(localized: "New Note")) {
                Task { await VaultActions.createNote(vault: vault, notes: notes) }
            }
            .keyboardShortcut("n")
            .disabled(vault.isOpen == false)

            Button(String(localized: "New Folder")) {
                Task { await VaultActions.createFolder(vault: vault, notes: notes) }
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
            .disabled(vault.isOpen == false)

            Divider()

            Button(String(localized: "Open Vault…")) {
                Task { await VaultActions.openVault(vault: vault, notes: notes) }
            }
            .keyboardShortcut("o", modifiers: [.command, .shift])

            Button(String(localized: "Create Vault…")) {
                Task { await VaultActions.createVault(vault: vault, notes: notes) }
            }
        }

        CommandMenu(String(localized: "Go")) {
            Button(String(localized: "Quick Open…")) {
                Task { await VaultActions.showQuickSwitcher(switcher: switcher, navigation: navigation) }
            }
            .keyboardShortcut("o")
            .disabled(vault.isOpen == false)

            Divider()

            Button(String(localized: "Back")) {
                Task { await navigation.goBack() }
            }
            .keyboardShortcut("[")
            .disabled(vault.isOpen == false)

            Button(String(localized: "Forward")) {
                Task { await navigation.goForward() }
            }
            .keyboardShortcut("]")
            .disabled(vault.isOpen == false)
        }

        CommandGroup(after: .sidebar) {
            Button(String(localized: "Toggle Inspector")) {
                navigation.isInspectorShown.toggle()
            }
            .keyboardShortcut("0", modifiers: [.command, .option])
        }

        CommandGroup(replacing: .saveItem) {
            Button(String(localized: "Save")) {
                Task { await notes.flush() }
            }
            .keyboardShortcut("s")
            .disabled(notes.path == nil)

            Button(String(localized: "Reload Vault")) {
                Task { await VaultActions.reloadVault(vault: vault, notes: notes) }
            }
            .keyboardShortcut("r")
            .disabled(vault.isOpen == false)
        }
    }
}
