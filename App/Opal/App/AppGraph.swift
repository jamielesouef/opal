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
    let quickSwitcherService: QuickSwitcherService
    let launchNote: NotePath?
    let launchAppearance: NSAppearance.Name?
    let launchQuickOpen: String?
    let launchTypeText: String?
    let defaults: UserDefaults

    // MARK: - Init

    init(
        vaultService: VaultService,
        defaults: UserDefaults,
        launchNote: NotePath? = nil,
        launchAppearance: NSAppearance.Name? = nil,
        launchQuickOpen: String? = nil,
        launchTypeText: String? = nil
    ) {
        let linkService = LinkService(vault: vaultService)
        let noteService = NoteService(vault: vaultService, links: linkService)
        self.vaultService = vaultService
        self.launchNote = launchNote
        self.launchAppearance = launchAppearance
        self.launchQuickOpen = launchQuickOpen
        self.launchTypeText = launchTypeText
        self.defaults = defaults
        self.noteService = noteService
        self.linkService = linkService
        let navigationService = NavigationService(
            vault: vaultService,
            notes: noteService,
            links: linkService,
            recents: UserDefaultsRecentNotesStore(defaults: defaults)
        )
        self.navigationService = navigationService
        quickSwitcherService = QuickSwitcherService(vault: vaultService, links: linkService, navigation: navigationService)
        vaultService.onExternalChange = { [linkService, noteService] paths in
            await linkService.refresh(paths)
            await noteService.reloadIfUnchanged(paths)
        }
    }
}
