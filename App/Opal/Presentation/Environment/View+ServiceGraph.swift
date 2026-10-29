//
//  View+ServiceGraph.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import OpalCore
import SwiftUI

extension View {
    // MARK: - Injection

    func serviceGraph(_ graph: ServiceGraph) -> some View {
        environment(\.serviceGraph, graph)
            .environment(\.vaultService, graph.vault)
            .environment(\.noteService, graph.notes)
            .environment(\.linkService, graph.links)
            .environment(\.indexService, graph.index)
            .environment(\.searchService, graph.search)
            .environment(\.mentionService, graph.mentions)
            .environment(\.dailyNoteService, graph.dailyNotes)
            .environment(\.templateService, graph.templates)
            .environment(\.renameService, graph.renames)
            .environment(\.navigationService, graph.navigation)
            .environment(\.quickSwitcherService, graph.switcher)
            .environment(\.settingsService, graph.settings)
    }
}
