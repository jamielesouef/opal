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
    @Environment(\.openWindow) private var openWindow
    @Environment(\.serviceGraph) private var graph
    @Environment(\.windowID) private var windowID

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
                await AppDependencies.shared.recents.load()
                for url in launch.recentVaults {
                    await AppDependencies.shared.recents.record(url)
                }
                await vault.start()
                if let windowID, let waiting = AppDependencies.shared.windows.takeWaitingVault(for: windowID) {
                    await VaultActions.open(waiting, in: graph)
                }
                if vault.isOpen, AppDependencies.shared.restoresState {
                    await navigation.restoreWindowState()
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
                    if let share = launch.splitShare {
                        navigation.setSplitShare(share)
                    }
                }
                if launch.opensNewWindow {
                    openWindow(value: AppDependencies.shared.windows.newWindow())
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
                if launch.hidesInspector {
                    navigation.isInspectorShown = false
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
            let recents = AppDependencies.shared.recents
            WelcomeView(message: reason?.message, recents: recents.vaults) {
                Task { await VaultActions.openVault(graph: graph, windowID: windowID, windows: AppDependencies.shared.windows, openWindow: { openWindow(value: $0) }) }
            } onCreate: {
                Task { await VaultActions.createVault(graph: graph, windowID: windowID, windows: AppDependencies.shared.windows, openWindow: { openWindow(value: $0) }) }
            } onChoose: { recent in
                Task { await VaultActions.openRecent(recent, recents: recents, graph: graph, windowID: windowID, windows: AppDependencies.shared.windows, openWindow: { openWindow(value: $0) }) }
            } onRemove: { recent in
                Task { await recents.remove(recent) }
            }
            .task { await recents.load() }
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
            .serviceGraph(graph)
    }

    #Preview("Garden Vault") {
        let graph = PreviewGraph.makeGraph(openingGarden: true)
        RootScreen()
            .serviceGraph(graph)
    }
#endif
