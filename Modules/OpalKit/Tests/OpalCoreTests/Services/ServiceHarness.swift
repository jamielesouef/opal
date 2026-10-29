//
//  ServiceHarness.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
@testable import OpalCore

struct ServiceHarness {
    // MARK: - Constants

    static let clock = FixedClock(now: Date(timeIntervalSince1970: 1_793_000_000), timeZone: TimeZone(identifier: "Australia/Sydney") ?? .gmt)

    // MARK: - Stored

    let store: any VaultFileStoring
    let graph: ServiceGraph
    let locations: StubVaultLocationStore
    let vault: VaultService
    let notes: NoteService
    let links: LinkService
    let navigation: NavigationService
    let switcher: QuickSwitcherService
    let recents: StubRecentNotesStore
    let windowID: UUID
    let windows: StubWindowListStore
    let index: IndexService
    let search: SearchService
    let mentions: MentionService
    let indexFolder: URL

    // MARK: - Init

    @MainActor
    init(
        store: any VaultFileStoring,
        access: StubVaultAccess = StubVaultAccess(),
        locations: StubVaultLocationStore = StubVaultLocationStore(),
        launchVaultURL: URL? = nil,
        makeWatcher: (@Sendable (URL) -> any VaultWatching)? = nil,
        settingsStore: StubSettingsStore = StubSettingsStore()
    ) {
        self.store = store
        self.locations = locations
        let vault = VaultService(access: access, locations: locations, launchVaultURL: launchVaultURL, makeWatcher: makeWatcher) { _ in store }
        let indexFolder = FileManager().temporaryDirectory.appending(component: "OpalIndexTests-\(UUID().uuidString)")
        let recents = StubRecentNotesStore()
        let windowID = UUID()
        let windows = StubWindowListStore()
        let graph = ServiceGraph(
            vault: vault,
            makeIndex: { root throws(IndexError) in
                try GRDBIndexStore(folderURL: IndexLocation.folder(forVaultAt: root, in: indexFolder))
            },
            recents: recents,
            windowID: windowID,
            windows: windows,
            settings: SettingsService(store: settingsStore, clock: Self.clock),
            clock: Self.clock,
            saveDelay: .seconds(3600)
        )
        self.graph = graph
        self.vault = vault
        self.indexFolder = indexFolder
        self.recents = recents
        self.windowID = windowID
        self.windows = windows
        index = graph.index
        links = graph.links
        notes = graph.notes
        navigation = graph.navigation
        switcher = graph.switcher
        search = graph.search
        mentions = graph.mentions
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
