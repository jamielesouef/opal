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
