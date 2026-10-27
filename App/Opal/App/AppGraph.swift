//
//  AppGraph.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import AppKit
import OpalCore

@MainActor
struct AppGraph {
    // MARK: - Services

    let vaultService: VaultService
    let noteService: NoteService
    let linkService: LinkService
    let navigationService: NavigationService
    let launchNote: NotePath?
    let launchAppearance: NSAppearance.Name?

    // MARK: - Init

    init(vaultService: VaultService, launchNote: NotePath? = nil, launchAppearance: NSAppearance.Name? = nil) {
        let linkService = LinkService(vault: vaultService)
        let noteService = NoteService(vault: vaultService, links: linkService)
        self.vaultService = vaultService
        self.launchNote = launchNote
        self.launchAppearance = launchAppearance
        self.noteService = noteService
        self.linkService = linkService
        navigationService = NavigationService(vault: vaultService, notes: noteService, links: linkService)
    }
}
