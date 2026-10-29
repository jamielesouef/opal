//
//  TemplatePickerView.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct TemplatePickerView: View {
    // MARK: - Environment

    @Environment(\.templateService) private var templates

    // MARK: - State

    @State private var query = ""
    @State private var selectedIndex = 0
    @FocusState private var isQueryFocused: Bool

    // MARK: - View

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppSpacing.small) {
                Image(systemName: "doc.on.doc")
                    .foregroundStyle(.secondary)
                TextField(String(localized: "Insert a Template"), text: $query)
                    .textFieldStyle(.plain)
                    .focused($isQueryFocused)
            }
            .font(.title3)
            .padding(AppSpacing.regular)
            .onKeyPress(.downArrow) {
                selectedIndex = min(selectedIndex + 1, max(matches.count - 1, 0))
                return .handled
            }
            .onKeyPress(.upArrow) {
                selectedIndex = max(selectedIndex - 1, 0)
                return .handled
            }
            .onSubmit(insertSelected)

            Divider()

            list
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(width: EditorMetrics.switcherWidth, height: EditorMetrics.switcherHeight)
        .onAppear { isQueryFocused = true }
        .onChange(of: query) { selectedIndex = 0 }
        .onExitCommand { templates.isPickerShown = false }
    }

    // MARK: - List

    @ViewBuilder
    private var list: some View {
        if let folder = templates.folder {
            if matches.isEmpty {
                ContentUnavailableView(
                    String(localized: "No Templates"),
                    systemImage: "doc.on.doc",
                    description: Text(query.isEmpty
                        ? String(localized: "Add a Note to “\(folder.rawValue)” to use it as a Template.")
                        : String(localized: "No Template matches “\(query)”."))
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(matches.enumerated()), id: \.element) { index, template in
                            row(template, folder: folder, isSelected: index == selectedIndex)
                                .onTapGesture {
                                    selectedIndex = index
                                    insertSelected()
                                }
                        }
                    }
                    .padding(AppSpacing.small)
                }
            }
        } else {
            ContentUnavailableView(
                String(localized: "No Templates Folder"),
                systemImage: "folder.badge.questionmark",
                description: Text(String(localized: "Choose a Templates Folder in Obsidian's Templates settings for this Vault."))
            )
        }
    }

    private func row(_ template: NotePath, folder: NotePath, isSelected: Bool) -> some View {
        let subfolder = template.parent.components.dropFirst(folder.components.count).joined(separator: "/")
        return HStack(spacing: AppSpacing.small) {
            Image(systemName: "doc.on.doc")
                .foregroundStyle(isSelected ? AppColor.onAccent : .secondary)
            VStack(alignment: .leading, spacing: AppSpacing.tiny) {
                Text(template.name)
                    .lineLimit(1)
                if subfolder.isEmpty == false {
                    Text(subfolder)
                        .font(.caption)
                        .opacity(AppOpacity.subdued)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: AppSpacing.small)
            if isSelected {
                Text("↩")
                    .font(.callout)
                    .opacity(AppOpacity.emphasized)
            }
        }
        .foregroundStyle(isSelected ? AppColor.onAccent : .primary)
        .padding(.horizontal, AppSpacing.small)
        .padding(.vertical, AppSpacing.compact)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: AppRadius.row, style: .continuous)
                    .fill(AppColor.accent)
            }
        }
        .contentShape(.rect)
    }

    // MARK: - Matching

    private var matches: [NotePath] {
        let needle = query.trimmingCharacters(in: .whitespaces)
        guard needle.isEmpty == false else {
            return templates.templates
        }

        return templates.templates.filter { $0.rawValue.localizedCaseInsensitiveContains(needle) }
    }

    private func insertSelected() {
        let list = matches
        guard list.indices.contains(selectedIndex) else {
            return
        }

        let template = list[selectedIndex]
        Task { await templates.insert(template) }
    }
}
