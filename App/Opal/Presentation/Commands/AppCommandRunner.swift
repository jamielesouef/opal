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
    let openSettings: () -> Void

    // MARK: - State

    func isEnabled(_ command: AppCommand) -> Bool {
        switch command {
        case .settings, .openVault, .createVault, .toggleInspector, .toggleLiveMarkdown:
            true
        case .newNote, .newFolder, .reloadVault, .quickSwitcher, .dailyNote, .searchVault, .back, .forward, .newTab, .closeTab, .nextTab, .previousTab:
            vault.isOpen
        case .duplicateNote, .save, .insertTemplate, .toggleReadingView:
            notes.path != nil
        case .splitRight:
            vault.isOpen && navigation.panes.isSplit == false
        }
    }

    // MARK: - Run

    func run(_ command: AppCommand) {
        guard isEnabled(command) else {
            return
        }

        switch command {
        case .settings:
            openSettings()
        case .newNote:
            Task { await VaultActions.createNote(vault: vault, navigation: navigation) }
        case .duplicateNote:
            if let path = notes.path {
                Task { await VaultActions.duplicate(path, vault: vault, navigation: navigation) }
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
        case .splitRight:
            Task { await navigation.splitRight() }
        case .newTab:
            Task { await navigation.openInNewTab(nil) }
        case .closeTab:
            Task { await navigation.closeSelectedTab() }
        case .nextTab:
            Task { await navigation.selectNeighbourTab(by: 1) }
        case .previousTab:
            Task { await navigation.selectNeighbourTab(by: -1) }
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
