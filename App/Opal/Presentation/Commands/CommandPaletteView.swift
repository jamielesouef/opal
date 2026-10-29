//
//  CommandPaletteView.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct CommandPaletteView: View {
    // MARK: - Constants

    private enum Constants {
        static let recentKey = "recentCommands"
        static let separator: Character = ","
    }

    // MARK: - Environment

    @Environment(\.serviceGraph) private var graph
    @Environment(\.windowID) private var windowID
    @Environment(\.openWindow) private var openWindow
    @Environment(\.vaultService) private var vault
    @Environment(\.openSettings) private var openSettings
    @Environment(\.noteService) private var notes
    @Environment(\.navigationService) private var navigation
    @Environment(\.quickSwitcherService) private var switcher
    @Environment(\.searchService) private var search
    @Environment(\.dailyNoteService) private var dailyNotes
    @Environment(\.templateService) private var templates

    // MARK: - State

    @AppStorage(Constants.recentKey) private var recentText = ""
    @AppStorage(EditorPreferences.liveMarkdownKey) private var isLiveMarkdown = true
    @State private var query = ""
    @State private var selectedIndex = 0
    @FocusState private var isQueryFocused: Bool

    // MARK: - View

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppSpacing.small) {
                Image(systemName: "command")
                    .foregroundStyle(.secondary)
                TextField(String(localized: "Run a command"), text: $query)
                    .textFieldStyle(.plain)
                    .focused($isQueryFocused)
            }
            .font(.title3)
            .padding(AppSpacing.regular)
            .onKeyPress(.downArrow) {
                selectedIndex = min(selectedIndex + 1, max(commands.count - 1, 0))
                return .handled
            }
            .onKeyPress(.upArrow) {
                selectedIndex = max(selectedIndex - 1, 0)
                return .handled
            }
            .onSubmit(runSelected)

            Divider()

            list
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(width: EditorMetrics.switcherWidth, height: EditorMetrics.switcherHeight)
        .onAppear { isQueryFocused = true }
        .onChange(of: query) { selectedIndex = 0 }
        .onExitCommand { navigation.isCommandPaletteShown = false }
    }

    // MARK: - List

    @ViewBuilder
    private var list: some View {
        let shown = commands
        if shown.isEmpty {
            ContentUnavailableView.search(text: query)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(shown.enumerated()), id: \.element) { index, command in
                            CommandPaletteRow(command: command, isSelected: index == selectedIndex, isEnabled: runner.isEnabled(command))
                                .id(command)
                                .onTapGesture {
                                    selectedIndex = index
                                    runSelected()
                                }
                        }
                    }
                    .padding(AppSpacing.small)
                }
                .onChange(of: selectedIndex) { _, index in
                    if shown.indices.contains(index) {
                        proxy.scrollTo(shown[index])
                    }
                }
            }
        }
    }

    // MARK: - Commands

    private var runner: AppCommandRunner {
        AppCommandRunner(
            graph: graph,
            windowID: windowID,
            windows: AppDependencies.shared.windows,
            toggleLiveMarkdown: { isLiveMarkdown.toggle() },
            openSettings: { openSettings() },
            openWindow: { openWindow(value: $0) }
        )
    }

    private var recent: [String] {
        recentText.split(separator: Constants.separator).map(String.init)
    }

    private var commands: [AppCommand] {
        let all = AppCommand.allCases
        let names = Dictionary(uniqueKeysWithValues: all.map { ($0.id, "\($0.group) \($0.title)") })
        return CommandMatchUseCase.ordered(ids: all.map(\.id), names: names, query: query, recent: recent)
            .compactMap(AppCommand.init(rawValue:))
    }

    private func runSelected() {
        let shown = commands
        guard shown.indices.contains(selectedIndex), runner.isEnabled(shown[selectedIndex]) else {
            return
        }

        let command = shown[selectedIndex]
        recentText = CommandMatchUseCase.recording(command.id, in: recent).joined(separator: String(Constants.separator))
        navigation.isCommandPaletteShown = false
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            runner.run(command)
        }
    }
}
