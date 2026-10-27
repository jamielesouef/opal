//
//  VaultScreen.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct VaultScreen: View {
    // MARK: - Environment

    @Environment(\.vaultService) private var vaultService
    @Environment(\.noteService) private var notes

    // MARK: - State

    @State private var selection: NotePath?
    @State private var expandedFolders: Set<NotePath> = []

    // MARK: - Input

    let vault: Vault

    // MARK: - View

    var body: some View {
        NavigationSplitView {
            FolderTreeView(
                selection: $selection,
                expandedFolders: $expandedFolders,
                vaultName: vault.name,
                tree: vaultService.tree
            ) { path in
                VaultActions.reveal(path, vault: vaultService)
            } onOpenInDefaultApp: { path in
                VaultActions.openInDefaultApp(path, vault: vaultService)
            }
            .navigationSplitViewColumnWidth(min: EditorMetrics.sidebarMinWidth, ideal: EditorMetrics.sidebarIdealWidth)
        } detail: {
            detail
        }
        .navigationTitle(WindowTitleUseCase.title(vaultName: vault.name, openNote: notes.path))
        .navigationSubtitle(WindowTitleUseCase.subtitle(vaultName: vault.name, openNote: notes.path))
        .toolbar {
            ToolbarItem(placement: .status) {
                SaveStatusView(status: notes.saveStatus, hasNote: notes.path != nil)
            }
        }
        .onChange(of: selection) { _, newSelection in
            guard let newSelection, vaultService.kind(of: newSelection) == .note else {
                return
            }

            Task { await notes.open(newSelection) }
        }
        .onChange(of: notes.path) { _, openPath in
            guard let openPath else {
                return
            }

            expandedFolders.formUnion(openPath.ancestors)
            selection = openPath
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        switch DetailContentUseCase.content(selection: selection, kind: selection.flatMap(vaultService.kind(of:))) {
        case .note:
            NoteScreen()
        case let .attachment(path):
            AttachmentView(name: path.fileName) {
                VaultActions.openInDefaultApp(path, vault: vaultService)
            }
        }
    }
}

#if DEBUG
    #Preview {
        let graph = PreviewGraph.makeGraph(openingGarden: true)
        VaultScreen(vault: Vault(rootURL: PreviewGraph.gardenRoot))
            .environment(\.vaultService, graph.vaultService)
            .environment(\.noteService, graph.noteService)
            .task { await graph.vaultService.start() }
    }
#endif
