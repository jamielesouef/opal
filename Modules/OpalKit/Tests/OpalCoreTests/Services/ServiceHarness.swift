//
//  ServiceHarness.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
@testable import OpalCore

struct ServiceHarness {
    // MARK: - Stored

    let store: any VaultFileStoring
    let locations: StubVaultLocationStore
    let vault: VaultService
    let notes: NoteService
    let links: LinkService
    let navigation: NavigationService
    let switcher: QuickSwitcherService
    let recents: StubRecentNotesStore
    let index: IndexService
    let indexFolder: URL

    // MARK: - Init

    @MainActor
    init(
        store: any VaultFileStoring,
        access: StubVaultAccess = StubVaultAccess(),
        locations: StubVaultLocationStore = StubVaultLocationStore(),
        launchVaultURL: URL? = nil,
        makeWatcher: (@Sendable (URL) -> any VaultWatching)? = nil
    ) {
        self.store = store
        self.locations = locations
        vault = VaultService(access: access, locations: locations, launchVaultURL: launchVaultURL, makeWatcher: makeWatcher) { _ in store }
        let indexFolder = FileManager().temporaryDirectory.appending(component: "OpalIndexTests-\(UUID().uuidString)")
        self.indexFolder = indexFolder
        index = IndexService(vault: vault) { root throws(IndexError) in
            try GRDBIndexStore(folderURL: IndexLocation.folder(forVaultAt: root, in: indexFolder))
        }
        links = LinkService(vault: vault, index: index)
        notes = NoteService(vault: vault, links: links, index: index, saveDelay: .seconds(3600))
        recents = StubRecentNotesStore()
        navigation = NavigationService(vault: vault, notes: notes, links: links, recents: recents)
        switcher = QuickSwitcherService(vault: vault, links: links, navigation: navigation)
        vault.onExternalChange = { [links, notes, index] paths in
            await index.update(paths)
            await links.refresh(paths)
            await notes.reloadIfUnchanged(paths)
        }
    }

    // MARK: - Steps

    @MainActor
    func openVault() async {
        await vault.open(folderURL: store.rootURL)
    }

    @MainActor
    func openVaultWithLinks() async {
        await openVault()
        await links.sync()
    }
}
