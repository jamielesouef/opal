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

    // MARK: - Runner

    private var runner: AppCommandRunner {
        AppCommandRunner(
            vault: vault,
            notes: notes,
            navigation: navigation,
            switcher: switcher,
            search: search,
            dailyNotes: dailyNotes,
            templates: templates,
            toggleLiveMarkdown: { isLiveMarkdown.toggle() }
        )
    }

    // MARK: - Commands

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            runner.button(.newNote)
            runner.button(.newTab)
            runner.button(.duplicateNote)
            runner.button(.newFolder)
            Divider()
            runner.button(.openVault)
            runner.button(.createVault)
        }

        CommandGroup(after: .pasteboard) {
            Divider()
            runner.button(.insertTemplate)
        }

        CommandMenu(String(localized: "Go")) {
            Button(String(localized: "Command Palette…")) {
                navigation.isCommandPaletteShown = true
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])

            Divider()

            runner.button(.quickSwitcher)
            runner.button(.dailyNote)
            runner.button(.searchVault)
            Divider()
            runner.button(.back)
            runner.button(.forward)
            Divider()
            runner.button(.nextTab)
            runner.button(.previousTab)
        }

        CommandGroup(after: .sidebar) {
            runner.button(.toggleReadingView, title: navigation.isReadingView ? String(localized: "Editor") : String(localized: "Reading View"))
            Toggle(String(localized: "Live Markdown"), isOn: $isLiveMarkdown)
            Divider()
            runner.button(.toggleInspector)
        }

        CommandGroup(replacing: .saveItem) {
            runner.button(.closeTab)
            runner.button(.save)
            runner.button(.reloadVault)
        }
    }
}
