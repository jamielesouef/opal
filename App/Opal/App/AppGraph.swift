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
    let indexService: IndexService
    let navigationService: NavigationService
    let quickSwitcherService: QuickSwitcherService
    let searchService: SearchService
    let mentionService: MentionService
    let launchRequest: LaunchRequest
    let launchAppearance: NSAppearance.Name?
    let launchSnapshotURL: URL?
    let defaults: UserDefaults

    // MARK: - Init

    init(
        vaultService: VaultService,
        indexBaseURL: URL,
        defaults: UserDefaults,
        launchRequest: LaunchRequest = LaunchRequest(),
        launchAppearance: NSAppearance.Name? = nil,
        launchSnapshotURL: URL? = nil
    ) {
        let indexService = IndexService(vault: vaultService) { root throws(IndexError) in
            try GRDBIndexStore(folderURL: IndexLocation.folder(forVaultAt: root, in: indexBaseURL))
        }
        let linkService = LinkService(vault: vaultService, index: indexService)
        let noteService = NoteService(vault: vaultService, links: linkService, index: indexService)
        self.indexService = indexService
        self.vaultService = vaultService
        self.launchRequest = launchRequest
        self.launchAppearance = launchAppearance
        self.launchSnapshotURL = launchSnapshotURL
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
        searchService = SearchService(index: indexService, navigation: navigationService)
        mentionService = MentionService(vault: vaultService, index: indexService, links: linkService, notes: noteService)
        vaultService.onExternalChange = { [linkService, noteService, indexService] paths in
            await indexService.update(paths)
            await linkService.refresh(paths)
            await noteService.reloadIfUnchanged(paths)
        }
    }
}
