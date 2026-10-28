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
    let search: SearchService
    let dailyNotes: DailyNoteService
    let templates: TemplateService

    // MARK: - Preferences

    @AppStorage private var isLiveMarkdown: Bool

    // MARK: - Init

    init(vault: VaultService, notes: NoteService, navigation: NavigationService, switcher: QuickSwitcherService, search: SearchService, dailyNotes: DailyNoteService, templates: TemplateService, defaults: UserDefaults) {
        self.vault = vault
        self.notes = notes
        self.navigation = navigation
        self.switcher = switcher
        self.search = search
        self.dailyNotes = dailyNotes
        self.templates = templates
        _isLiveMarkdown = AppStorage(wrappedValue: true, EditorPreferences.liveMarkdownKey, store: defaults)
    }

    // MARK: - Commands

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button(String(localized: "New Note")) {
                Task { await VaultActions.createNote(vault: vault, notes: notes) }
            }
            .keyboardShortcut("n")
            .disabled(vault.isOpen == false)

            Button(String(localized: "Duplicate Note")) {
                if let path = notes.path {
                    Task { await VaultActions.duplicate(path, vault: vault, notes: notes) }
                }
            }
            .disabled(notes.path == nil)

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

        CommandGroup(after: .pasteboard) {
            Divider()

            Button(String(localized: "Insert Template…")) {
                templates.showPicker()
            }
            .keyboardShortcut("t", modifiers: [.command, .option])
            .disabled(notes.path == nil)
        }

        CommandMenu(String(localized: "Go")) {
            Button(String(localized: "Quick Switcher…")) {
                Task { await VaultActions.showQuickSwitcher(switcher: switcher, navigation: navigation) }
            }
            .keyboardShortcut("o")
            .disabled(vault.isOpen == false)

            Button(String(localized: "Today's Daily Note")) {
                Task { await dailyNotes.openToday() }
            }
            .keyboardShortcut("d", modifiers: [.command, .option])
            .disabled(vault.isOpen == false)

            Button(String(localized: "Search Vault…")) {
                search.show()
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])
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
            Button(navigation.isReadingView ? String(localized: "Editor") : String(localized: "Reading View")) {
                navigation.isReadingView.toggle()
            }
            .keyboardShortcut("e")
            .disabled(notes.path == nil)

            Toggle(String(localized: "Live Markdown"), isOn: $isLiveMarkdown)

            Divider()

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
