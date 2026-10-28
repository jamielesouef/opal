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
    @Environment(\.openSettings) private var openSettings

    // MARK: - Preferences

    @AppStorage(EditorPreferences.appearanceKey) private var appearance = AppearanceChoice.system
    @AppStorage(EditorPreferences.settingsTabKey) private var settingsTab = SettingsTab.editor

    // MARK: - View

    var body: some View {
        content
            .onChange(of: appearance, initial: true) { _, choice in
                if AppDependencies.shared.launchAppearance == nil {
                    NSApp.appearance = choice.appearance
                }
            }
            .task {
                await vault.start()
                if vault.isOpen {
                    await navigation.restoreTabs()
                }
                if let note = launch.note, vault.isOpen {
                    await navigation.open(note)
                }
                for tab in launch.extraTabs where vault.isOpen {
                    await navigation.openInNewTab(tab)
                }
                if let split = launch.splitNote, vault.isOpen {
                    await navigation.splitRight()
                    await navigation.open(split)
                }
                if let tab = launch.settingsTab.flatMap(SettingsTab.init(rawValue:)) {
                    settingsTab = tab
                    openSettings()
                }
                if launch.opensDailyNote, vault.isOpen {
                    await dailyNotes.openToday()
                }
                if launch.showsCommandPalette || launch.showsTemplates, vault.isOpen {
                    try? await Task.sleep(for: .seconds(1))
                    navigation.isCommandPaletteShown = launch.showsCommandPalette
                    if launch.showsTemplates {
                        templates.showPicker()
                    }
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
            .environment(\.vaultService, graph.services.vault)
            .environment(\.noteService, graph.services.notes)
            .environment(\.linkService, graph.services.links)
            .environment(\.indexService, graph.services.index)
            .environment(\.searchService, graph.services.search)
            .environment(\.mentionService, graph.services.mentions)
            .environment(\.dailyNoteService, graph.services.dailyNotes)
            .environment(\.templateService, graph.services.templates)
            .environment(\.renameService, graph.services.renames)
            .environment(\.navigationService, graph.services.navigation)
            .environment(\.quickSwitcherService, graph.services.switcher)
    }

    #Preview("Garden Vault") {
        let graph = PreviewGraph.makeGraph(openingGarden: true)
        RootScreen()
            .environment(\.vaultService, graph.services.vault)
            .environment(\.noteService, graph.services.notes)
            .environment(\.linkService, graph.services.links)
            .environment(\.indexService, graph.services.index)
            .environment(\.searchService, graph.services.search)
            .environment(\.mentionService, graph.services.mentions)
            .environment(\.dailyNoteService, graph.services.dailyNotes)
            .environment(\.templateService, graph.services.templates)
            .environment(\.renameService, graph.services.renames)
            .environment(\.navigationService, graph.services.navigation)
            .environment(\.quickSwitcherService, graph.services.switcher)
    }
#endif
