//
//  TabBarView.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct TabBarView: View {
    // MARK: - Constants

    private enum Constants {
        static let tabMaxWidth: CGFloat = 200
        static let cornerRadius: CGFloat = 6
    }

    // MARK: - Environment

    @Environment(\.navigationService) private var navigation

    // MARK: - Input

    let pane: Int

    // MARK: - Derived

    private var tabs: TabList {
        navigation.panes.panes.indices.contains(pane) ? navigation.panes.panes[pane] : TabList()
    }

    private var isFocused: Bool {
        navigation.panes.focusedIndex == pane
    }

    // MARK: - View

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: AppSpacing.xsmall) {
                ForEach(tabs.tabs) { tab in
                    tabButton(tab)
                }
                Button {
                    Task {
                        await navigation.focusPane(pane)
                        await navigation.openInNewTab(nil)
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help(String(localized: "New Tab (⌘T)"))
            }
            .padding(.horizontal, AppSpacing.small)
            .padding(.vertical, AppSpacing.xsmall)
        }
        .scrollIndicators(.never)
        .background(.bar)
    }

    // MARK: - Tab

    private func tabButton(_ tab: NoteTab) -> some View {
        let isSelected = tab.id == tabs.selectedID
        return HStack(spacing: AppSpacing.xsmall) {
            Text(tab.path?.name ?? String(localized: "New Tab"))
                .lineLimit(1)
                .frame(maxWidth: Constants.tabMaxWidth, alignment: .leading)
            Button {
                Task { await navigation.closeTab(tab.id, inPane: pane) }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.bold())
            }
            .buttonStyle(.borderless)
            .help(String(localized: "Close Tab (⌘W)"))
        }
        .font(.callout)
        .padding(.horizontal, AppSpacing.small)
        .padding(.vertical, AppSpacing.xsmall)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous)
                    .fill(isFocused ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.quinary))
            }
        }
        .foregroundStyle(isSelected && isFocused ? .primary : .secondary)
        .contentShape(.rect)
        .onTapGesture {
            Task { await navigation.selectTab(tab.id, inPane: pane) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
