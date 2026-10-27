//
//  RootScreen.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct RootScreen: View {
    // MARK: - Environment

    @Environment(\.vaultService) private var vault
    @Environment(\.noteService) private var notes

    // MARK: - View

    var body: some View {
        content
            .task {
                await vault.start()
            }
    }

    // MARK: - Load state

    @ViewBuilder
    private var content: some View {
        switch vault.loadState {
        case let .closed(reason):
            WelcomeView(message: reason?.message) {
                Task { await VaultActions.openVault(vault: vault, notes: notes) }
            } onCreate: {
                Task { await VaultActions.createVault(vault: vault, notes: notes) }
            }
        case .opening:
            ProgressView(String(localized: "Opening Vault…"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .open(openVault):
            VaultScreen(vault: openVault)
        }
    }
}

#if DEBUG
    #Preview("No Vault") {
        let graph = PreviewGraph.makeGraph(openingGarden: false)
        RootScreen()
            .environment(\.vaultService, graph.vaultService)
            .environment(\.noteService, graph.noteService)
    }

    #Preview("Garden Vault") {
        let graph = PreviewGraph.makeGraph(openingGarden: true)
        RootScreen()
            .environment(\.vaultService, graph.vaultService)
            .environment(\.noteService, graph.noteService)
    }
#endif
