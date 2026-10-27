//
//  QuickSwitcherView.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct QuickSwitcherView: View {
    // MARK: - Environment

    @Environment(\.quickSwitcherService) private var switcher
    @Environment(\.navigationService) private var navigation

    // MARK: - State

    @FocusState private var isQueryFocused: Bool

    // MARK: - View

    var body: some View {
        @Bindable var switcher = switcher
        VStack(spacing: 0) {
            HStack(spacing: AppSpacing.small) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(String(localized: "Find or create a Note"), text: $switcher.query)
                    .textFieldStyle(.plain)
                    .focused($isQueryFocused)
            }
            .font(.title3)
            .padding(AppSpacing.regular)
            .onKeyPress(.downArrow) {
                switcher.moveSelection(by: 1)
                return .handled
            }
            .onKeyPress(.upArrow) {
                switcher.moveSelection(by: -1)
                return .handled
            }
            .onSubmit {
                confirm()
            }

            Divider()

            results
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(width: EditorMetrics.switcherWidth, height: EditorMetrics.switcherHeight)
        .onAppear {
            isQueryFocused = true
        }
        .onExitCommand {
            navigation.isQuickSwitcherShown = false
        }
    }

    // MARK: - Results

    @ViewBuilder
    private var results: some View {
        let matches = switcher.results
        if matches.isEmpty {
            ContentUnavailableView {
                Label(String(localized: "No Matching Notes"), systemImage: "magnifyingglass")
            } description: {
                if switcher.canCreate {
                    Text(String(localized: "Press Return to create “\(switcher.query)”."))
                }
            }
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(matches.enumerated()), id: \.element.id) { index, match in
                            QuickSwitcherRow(match: match, isSelected: index == switcher.selectedIndex)
                                .id(match.id)
                                .onTapGesture {
                                    switcher.select(match)
                                    confirm()
                                }
                        }
                    }
                    .padding(AppSpacing.small)
                }
                .onChange(of: switcher.selectedIndex) { _, index in
                    guard matches.indices.contains(index) else {
                        return
                    }
                    proxy.scrollTo(matches[index].id)
                }
            }
        }
    }

    // MARK: - Actions

    private func confirm() {
        Task {
            guard await switcher.confirm() != nil else {
                return
            }
            navigation.isQuickSwitcherShown = false
        }
    }
}
