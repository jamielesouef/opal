//
//  FolderTreeView.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import SwiftUI

struct FolderTreeView: View {
    // MARK: - Binding

    @Binding var selection: NotePath?
    @Binding var expandedFolders: Set<NotePath>

    // MARK: - Input

    let vaultName: String
    let tree: [VaultTreeNode]
    var onReveal: (NotePath) -> Void = { _ in }
    var onOpenInDefaultApp: (NotePath) -> Void = { _ in }

    // MARK: - View

    var body: some View {
        List(selection: $selection) {
            Section(vaultName) {
                ForEach(tree) { node in
                    FolderTreeRow(
                        node: node,
                        expandedFolders: $expandedFolders,
                        onReveal: onReveal,
                        onOpenInDefaultApp: onOpenInDefaultApp
                    )
                }
            }
        }
        .listStyle(.sidebar)
        .overlay {
            if tree.isEmpty {
                ContentUnavailableView(
                    String(localized: "No Notes Yet"),
                    systemImage: "text.document",
                    description: Text(String(localized: "Press ⌘N to write your first Note."))
                )
            }
        }
    }
}

#if DEBUG
    #Preview("Garden") {
        @Previewable @State var selection: NotePath? = NotePath("Areas/Health.md")
        @Previewable @State var expanded: Set<NotePath> = [NotePath("Areas")]
        FolderTreeView(
            selection: $selection,
            expandedFolders: $expanded,
            vaultName: "Garden",
            tree: VaultTreeUseCase.tree(from: [
                VaultEntry(path: NotePath("Areas"), isFolder: true),
                VaultEntry(path: NotePath("Areas/Health.md"), isFolder: false),
                VaultEntry(path: NotePath("Attachments"), isFolder: true),
                VaultEntry(path: NotePath("Attachments/seedlings.png"), isFolder: false),
                VaultEntry(path: NotePath("Soil.md"), isFolder: false),
                VaultEntry(path: NotePath("A Note With A Very Long Name That Will Not Fit In The Sidebar.md"), isFolder: false)
            ])
        )
        .frame(width: 260, height: 400)
    }

    #Preview("Empty Vault") {
        @Previewable @State var selection: NotePath?
        @Previewable @State var expanded: Set<NotePath> = []
        FolderTreeView(selection: $selection, expandedFolders: $expanded, vaultName: "New Vault", tree: [])
            .frame(width: 260, height: 400)
    }
#endif
