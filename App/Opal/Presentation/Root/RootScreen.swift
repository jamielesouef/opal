//
//  RootScreen.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct RootScreen: View {
    // MARK: - Environment

    @Environment(\.vaultService) private var vault
    @Environment(\.noteService) private var notes
    @Environment(\.navigationService) private var navigation
    @Environment(\.quickSwitcherService) private var switcher
    @Environment(\.searchService) private var search
    @Environment(\.launchRequest) private var launch
    @Environment(\.dailyNoteService) private var dailyNotes
    @Environment(\.templateService) private var templates

    // MARK: - View

    var body: some View {
        content
            .task {
                await vault.start()
                if let note = launch.note, vault.isOpen {
                    await navigation.open(note)
                }
                if launch.opensDailyNote, vault.isOpen {
                    await dailyNotes.openToday()
                }
                if launch.showsTemplates, vault.isOpen {
                    templates.showPicker()
                }
                if launch.isReadingView {
                    navigation.isReadingView = true
                }
                if let pane = launch.sidebarPane, vault.isOpen {
                    navigation.sidebarPane = pane
                }
                if let query = launch.search, vault.isOpen {
                    search.show(query: query)
                }
                if let switcherQuery = launch.quickOpen, vault.isOpen {
                    await VaultActions.showQuickSwitcher(query: switcherQuery, switcher: switcher, navigation: navigation)
                }
            }
    }

    // MARK: - Load state

    @ViewBuilder
    private var content: some View {
        switch vault.loadState {
        case let .closed(reason):
            WelcomeView(message: reason?.message) {
                Task { await VaultActions.openVault(vault: vault, notes: notes) }
            } onCreate: {
                Task { await VaultActions.createVault(vault: vault, notes: notes) }
            }
        case .opening:
            ProgressView(String(localized: "Opening Vault…"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .open(openVault):
            VaultScreen(vault: openVault)
        }
    }
}

#if DEBUG
    #Preview("No Vault") {
        let graph = PreviewGraph.makeGraph(openingGarden: false)
        RootScreen()
            .environment(\.vaultService, graph.vaultService)
            .environment(\.noteService, graph.noteService)
            .environment(\.linkService, graph.linkService)
            .environment(\.indexService, graph.indexService)
            .environment(\.searchService, graph.searchService)
            .environment(\.mentionService, graph.mentionService)
            .environment(\.dailyNoteService, graph.dailyNoteService)
            .environment(\.templateService, graph.templateService)
            .environment(\.renameService, graph.renameService)
            .environment(\.navigationService, graph.navigationService)
            .environment(\.quickSwitcherService, graph.quickSwitcherService)
    }

    #Preview("Garden Vault") {
        let graph = PreviewGraph.makeGraph(openingGarden: true)
        RootScreen()
            .environment(\.vaultService, graph.vaultService)
            .environment(\.noteService, graph.noteService)
            .environment(\.linkService, graph.linkService)
            .environment(\.indexService, graph.indexService)
            .environment(\.searchService, graph.searchService)
            .environment(\.mentionService, graph.mentionService)
            .environment(\.dailyNoteService, graph.dailyNoteService)
            .environment(\.templateService, graph.templateService)
            .environment(\.renameService, graph.renameService)
            .environment(\.navigationService, graph.navigationService)
            .environment(\.quickSwitcherService, graph.quickSwitcherService)
    }
#endif
