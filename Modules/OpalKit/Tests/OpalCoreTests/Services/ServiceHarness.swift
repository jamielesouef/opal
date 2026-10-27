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

    // MARK: - Init

    @MainActor
    init(
        store: any VaultFileStoring,
        access: StubVaultAccess = StubVaultAccess(),
        locations: StubVaultLocationStore = StubVaultLocationStore(),
        launchVaultURL: URL? = nil
    ) {
        self.store = store
        self.locations = locations
        vault = VaultService(access: access, locations: locations, launchVaultURL: launchVaultURL) { _ in store }
        notes = NoteService(vault: vault, saveDelay: .seconds(3600))
    }

    // MARK: - Steps

    @MainActor
    func openVault() async {
        await vault.open(folderURL: store.rootURL)
    }
}
