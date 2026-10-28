//
//  MoveToFolderView.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct MoveToFolderView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Input

    let item: NotePath
    let folders: [NotePath]
    let vaultName: String
    var onMove: (NotePath) -> Void = { _ in }

    // MARK: - State

    @State private var query = ""
    @State private var choice: NotePath?

    // MARK: - View

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.regular) {
            Text(String(localized: "Move “\(item.name)” to…"))
                .font(.headline)
            TextField(String(localized: "Filter Folders"), text: $query)
                .textFieldStyle(.roundedBorder)
            List(choices, id: \.self, selection: $choice) { folder in
                Label(folder.isRoot ? vaultName : folder.rawValue, systemImage: folder.isRoot ? "archivebox" : "folder")
                    .tag(folder)
            }
            .frame(minHeight: EditorMetrics.switcherHeight / 2)
            HStack {
                Spacer()
                Button(String(localized: "Cancel"), role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button(String(localized: "Move")) {
                    if let choice {
                        dismiss()
                        onMove(choice)
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(choice == nil)
            }
        }
        .padding(AppSpacing.large)
        .frame(width: EditorMetrics.switcherWidth * 0.8)
    }

    // MARK: - Choices

    private var choices: [NotePath] {
        let all = ([NotePath.root] + folders).filter { $0 != item.parent && ($0.isRoot || $0.components.starts(with: item.components) == false) }
        let needle = query.trimmingCharacters(in: .whitespaces)
        return needle.isEmpty ? all : all.filter { $0.rawValue.localizedCaseInsensitiveContains(needle) }
    }
}
