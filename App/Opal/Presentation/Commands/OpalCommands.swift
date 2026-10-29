//
//  OpalCommands.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import SwiftUI

struct OpalCommands: Commands {
    // MARK: - Environment

    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow
    @FocusedValue(\.serviceGraph) private var focusedGraph
    @FocusedValue(\.windowID) private var windowID

    // MARK: - Dependencies

    let windows: WindowRegistry
    let recents: RecentVaultsService
    let placeholder: ServiceGraph

    // MARK: - Preferences

    @AppStorage private var isLiveMarkdown: Bool

    // MARK: - Init

    init(windows: WindowRegistry, recents: RecentVaultsService, placeholder: ServiceGraph, defaults: UserDefaults) {
        self.windows = windows
        self.recents = recents
        self.placeholder = placeholder
        _isLiveMarkdown = AppStorage(wrappedValue: true, EditorPreferences.liveMarkdownKey, store: defaults)
    }

    // MARK: - Runner

    private var navigation: NavigationService {
        (focusedGraph ?? placeholder).navigation
    }

    private var runner: AppCommandRunner {
        AppCommandRunner(
            graph: focusedGraph ?? placeholder,
            windowID: focusedGraph == nil ? nil : windowID,
            windows: windows,
            toggleLiveMarkdown: { isLiveMarkdown.toggle() },
            openSettings: { openSettings() },
            openWindow: { openWindow(value: $0) }
        )
    }

    // MARK: - Commands

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            runner.button(.settings)
        }

        CommandGroup(replacing: .newItem) {
            runner.button(.newWindow)
            Divider()
            runner.button(.newNote)
            runner.button(.newTab)
            runner.button(.duplicateNote)
            runner.button(.newFolder)
            Divider()
            runner.button(.openVault)
            openRecentMenu
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
            .disabled(focusedGraph == nil)

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
            runner.button(.splitRight)
            runner.button(.toggleInspector)
        }

        CommandGroup(replacing: .saveItem) {
            runner.button(.closeTab)
            runner.button(.save)
            runner.button(.reloadVault)
        }
    }

    // MARK: - Open Recent

    private var openRecentMenu: some View {
        Menu(String(localized: "Open Recent")) {
            ForEach(recents.vaults) { vault in
                Button {
                    openRecent(vault)
                } label: {
                    Text(vault.name)
                    Text(vault.isMissing ? String(localized: "Folder not found") : vault.parentPath)
                }
                .disabled(vault.isMissing)
            }
            Divider()
            Button(String(localized: "Clear Menu")) {
                Task { await recents.clear() }
            }
            .disabled(recents.vaults.isEmpty)
        }
        .disabled(runner.isEnabled(.openVault) == false)
    }

    private func openRecent(_ vault: RecentVault) {
        guard let focusedGraph, let windowID else {
            return
        }

        Task {
            await VaultActions.openRecent(vault, recents: recents, graph: focusedGraph, windowID: windowID, windows: windows, openWindow: { openWindow(value: $0) })
        }
    }
}
