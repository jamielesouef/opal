//
//  SearchView.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct SearchView: View {
    // MARK: - Environment

    @Environment(\.searchService) private var search

    // MARK: - State

    @FocusState private var isQueryFocused: Bool

    // MARK: - View

    var body: some View {
        @Bindable var search = search
        VStack(spacing: 0) {
            TextField(String(localized: "Search"), text: $search.query, prompt: Text(String(localized: "Search the Vault")))
                .textFieldStyle(.roundedBorder)
                .focused($isQueryFocused)
                .padding(.horizontal, AppSpacing.small)
                .padding(.bottom, AppSpacing.small)
                .help(String(localized: "Words, \"phrases\", -exclude, path:, file:, tag:#name"))

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .onAppear {
            isQueryFocused = true
        }
        .onChange(of: search.focusRequest) {
            isQueryFocused = true
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch search.loadState {
        case .idle:
            ContentUnavailableView(
                String(localized: "Search the Vault"),
                systemImage: "magnifyingglass",
                description: Text(String(localized: "Use \"quotes\" for a phrase, -word to exclude, and path:, file: or tag:#name to narrow."))
            )
        case .searching:
            ProgressView()
                .controlSize(.small)
                .padding()
        case .unavailable:
            ContentUnavailableView(
                String(localized: "Search Is Not Ready"),
                systemImage: "hourglass",
                description: Text(String(localized: "Opal is still reading the Vault."))
            )
        case let .results(results) where results.isEmpty:
            ContentUnavailableView.search(text: search.query)
        case let .results(results):
            List {
                ForEach(results) { result in
                    Section {
                        ForEach(result.lines, id: \.line) { line in
                            Button {
                                Task { await search.open(result, line: line.line) }
                            } label: {
                                Text(SearchLineText.attributed(line))
                                    .font(.callout)
                                    .lineLimit(3)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Button {
                            Task { await search.open(result, line: nil) }
                        } label: {
                            HStack {
                                Label(result.path.name, systemImage: "text.document")
                                    .lineLimit(1)
                                Spacer()
                                Text(result.matchCount, format: .number)
                                    .monospacedDigit()
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.trailing, AppSpacing.small)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.sidebar)
        }
    }
}
