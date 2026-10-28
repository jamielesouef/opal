//
//  VaultSync.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import SwiftUI

struct VaultSync: View {
    // MARK: - Environment

    @Environment(\.vaultService) private var vault
    @Environment(\.linkService) private var links
    @Environment(\.indexService) private var index
    @Environment(\.searchService) private var search

    // MARK: - View

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .onChange(of: index.revision) {
                Task { await search.search() }
            }
            .task(id: vault.entriesRevision) {
                await index.sync()
                await links.sync()
            }
    }
}
