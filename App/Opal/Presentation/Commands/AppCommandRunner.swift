//
//  AppCommandRunner.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import OpalCore
import SwiftUI

@MainActor
struct AppCommandRunner {
    // MARK: - Dependencies

    let vault: VaultService
    let notes: NoteService
    let navigation: NavigationService
    let switcher: QuickSwitcherService
    let search: SearchService
    let dailyNotes: DailyNoteService
    let templates: TemplateService
    let toggleLiveMarkdown: () -> Void

    // MARK: - State

    func isEnabled(_ command: AppCommand) -> Bool {
        switch command {
        case .openVault, .createVault, .toggleInspector, .toggleLiveMarkdown:
            true
        case .newNote, .newFolder, .reloadVault, .quickSwitcher, .dailyNote, .searchVault, .back, .forward:
            vault.isOpen
        case .duplicateNote, .save, .insertTemplate, .toggleReadingView:
            notes.path != nil
        }
    }

    // MARK: - Run

    func run(_ command: AppCommand) {
        guard isEnabled(command) else {
            return
        }

        switch command {
        case .newNote:
            Task { await VaultActions.createNote(vault: vault, notes: notes) }
        case .duplicateNote:
            if let path = notes.path {
                Task { await VaultActions.duplicate(path, vault: vault, notes: notes) }
            }
        case .newFolder:
            Task { await VaultActions.createFolder(vault: vault, notes: notes) }
        case .openVault:
            Task { await VaultActions.openVault(vault: vault, notes: notes) }
        case .createVault:
            Task { await VaultActions.createVault(vault: vault, notes: notes) }
        case .save:
            Task { await notes.flush() }
        case .reloadVault:
            Task { await VaultActions.reloadVault(vault: vault, notes: notes) }
        case .insertTemplate:
            templates.showPicker()
        case .quickSwitcher:
            Task { await VaultActions.showQuickSwitcher(switcher: switcher, navigation: navigation) }
        case .dailyNote:
            Task { await dailyNotes.openToday() }
        case .searchVault:
            search.show()
        case .back:
            Task { await navigation.goBack() }
        case .forward:
            Task { await navigation.goForward() }
        case .toggleReadingView:
            navigation.isReadingView.toggle()
        case .toggleLiveMarkdown:
            toggleLiveMarkdown()
        case .toggleInspector:
            navigation.isInspectorShown.toggle()
        }
    }

    // MARK: - Menu

    @ViewBuilder
    func button(_ command: AppCommand, title: String? = nil) -> some View {
        let base = Button(title ?? command.title) {
            run(command)
        }
        .disabled(isEnabled(command) == false)
        if let shortcut = command.shortcut {
            base.keyboardShortcut(shortcut)
        } else {
            base
        }
    }
}
