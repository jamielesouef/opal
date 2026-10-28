//
//  FolderTreePane.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import OpalCore
import SwiftUI

struct FolderTreePane: View {
    // MARK: - Environment

    @Environment(\.vaultService) private var vaultService

    // MARK: - Input

    @Binding var selection: NotePath?
    @Binding var expandedFolders: Set<NotePath>
    let vaultName: String

    // MARK: - View

    var body: some View {
        FolderTreeView(
            selection: $selection,
            expandedFolders: $expandedFolders,
            vaultName: vaultName,
            tree: vaultService.tree
        ) { path in
            VaultActions.reveal(path, vault: vaultService)
        } onOpenInDefaultApp: { path in
            VaultActions.openInDefaultApp(path, vault: vaultService)
        }
    }
}
