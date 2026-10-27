//
//  VaultServiceTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("VaultService", .tags(.service))
struct VaultServiceTests {
    @Test("is closed with no message before a Vault was ever opened")
    func initialState() async {
        let harness = await ServiceHarness(store: StubVaultFileStore())

        await harness.vault.start()

        #expect(await harness.vault.loadState == .closed(nil))
    }

    @Test("opening a Vault builds its tree, reads Obsidian's settings and remembers it")
    func opens() async {
        let store = StubVaultFileStore(
            files: ["Soil.md": "", "Areas/Health.md": "", ".obsidian/app.json": "{}"],
            folders: ["Areas", ".obsidian"],
            settingsJSON: #"{"newFileLocation":"folder","newFileFolderPath":"Inbox"}"#
        )
        let harness = await ServiceHarness(store: store)

        await harness.openVault()

        #expect(await harness.vault.loadState == .open(Vault(rootURL: store.rootURL)))
        #expect(await harness.vault.tree.map(\.displayName) == ["Areas", "Soil"])
        #expect(await harness.vault.appSettings.newFileLocation == .folder)
        #expect(await harness.locations.bookmark == Data(store.rootURL.path.utf8))
    }

    @Test("start reopens the remembered Vault")
    func reopensLastVault() async {
        let store = StubVaultFileStore(files: ["Soil.md": ""])
        let locations = StubVaultLocationStore(bookmark: Data(store.rootURL.path.utf8))
        let harness = await ServiceHarness(store: store, locations: locations)

        await harness.vault.start()
        await harness.vault.start()

        #expect(await harness.vault.loadState == .open(Vault(rootURL: store.rootURL)))
        #expect(await store.listCount == 1)
        #expect(await locations.setCount == 0)
    }

    @Test("a remembered Vault that has gone away leaves Opal closed with a reason")
    func missingVault() async {
        let locations = StubVaultLocationStore(bookmark: Data("/Gone".utf8))
        let harness = await ServiceHarness(store: StubVaultFileStore(), access: StubVaultAccess(resolvesBookmarks: false), locations: locations)

        await harness.vault.start()

        #expect(await harness.vault.loadState == .closed(.vaultMissing))
    }

    @Test("a stale bookmark is replaced after the Vault opens")
    func refreshesStaleBookmark() async {
        let store = StubVaultFileStore()
        let locations = StubVaultLocationStore(bookmark: Data(store.rootURL.path.utf8))
        let harness = await ServiceHarness(store: store, access: StubVaultAccess(resolvesStale: true), locations: locations)

        await harness.vault.start()

        #expect(await locations.setCount == 1)
    }

    @Test("a launch Vault opens without being remembered")
    func launchVault() async {
        let store = StubVaultFileStore()
        let harness = await ServiceHarness(store: store, launchVaultURL: store.rootURL)

        await harness.vault.start()

        #expect(await harness.vault.isOpen)
        #expect(await harness.locations.setCount == 0)
    }

    @Test("an unreadable Vault folder leaves Opal closed with a reason")
    func unreadable() async {
        let store = StubVaultFileStore()
        await store.failLists(with: .folderUnreadable)
        let harness = await ServiceHarness(store: store)

        await harness.openVault()

        #expect(await harness.vault.loadState == .closed(.folderUnreadable))
        #expect(await harness.vault.store == nil)
    }

    @Test("a new Note goes to Obsidian's new Note Folder, created if missing, and appears in the tree without a reload")
    func createsNote() async throws {
        let store = StubVaultFileStore(files: ["Soil.md": ""], settingsJSON: #"{"newFileLocation":"folder","newFileFolderPath":"Inbox"}"#)
        let harness = await ServiceHarness(store: store)
        await harness.openVault()

        let first = try await harness.vault.createNote(openNote: nil)
        let second = try await harness.vault.createNote(openNote: nil)

        #expect(first == NotePath("Inbox/Untitled.md"))
        #expect(second == NotePath("Inbox/Untitled 1.md"))
        #expect(await store.text("Inbox/Untitled.md") == "")
        #expect(await harness.vault.tree.first?.displayName == "Inbox")
        let inboxNames = await harness.vault.tree.first?.children?.map(\.displayName)
        #expect(inboxNames == ["Untitled", "Untitled 1"])
        #expect(await harness.vault.kind(of: NotePath("Inbox")) == .folder)
        #expect(await store.listCount == 1)
    }

    @Test("a new Folder goes inside the selected Folder")
    func createsFolder() async throws {
        let store = StubVaultFileStore(folders: ["Areas"])
        let harness = await ServiceHarness(store: store)
        await harness.openVault()

        let folder = try await harness.vault.createFolder(near: NotePath("Areas"))

        #expect(folder == NotePath("Areas/Untitled"))
        #expect(await harness.vault.kind(of: folder) == .folder)
    }

    @Test("creating a Note with no Vault open fails")
    func createWithoutVault() async {
        let harness = await ServiceHarness(store: StubVaultFileStore())

        await #expect(throws: VaultError.noVaultOpen) {
            try await harness.vault.createNote(openNote: nil)
        }
    }

    @Test("refresh reads the tree again")
    func refresh() async {
        let store = StubVaultFileStore(files: ["Soil.md": ""])
        let harness = await ServiceHarness(store: store)
        await harness.openVault()

        await store.changeOnDisk("Tomatoes.md", to: "")
        await harness.vault.refresh()

        #expect(await harness.vault.tree.map(\.displayName) == ["Soil", "Tomatoes"])
    }
}
