//
//  SettingsServiceTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("SettingsService", .tags(.service))
@MainActor
struct SettingsServiceTests {
    // MARK: - Helpers

    private static func setUp(_ vault: FixtureVault, store: StubSettingsStore) async -> (ServiceHarness, SettingsService) {
        let harness = ServiceHarness(store: FileSystemVaultStore(rootURL: vault.rootURL))
        let service = SettingsService(vault: harness.vault, store: store, clock: ServiceHarness.clock)
        service.load()
        await harness.openVault()
        return (harness, service)
    }

    private static var mine: OpalSettings {
        var settings = OpalSettings.defaults
        settings.newFileLocation = .current
        settings.attachmentFolderPath = "Files"
        settings.useMarkdownLinks = true
        settings.linkUpdate = .never
        settings.dailyFolder = "Journal"
        settings.dailyFormat = "DD-MM-YYYY"
        return settings
    }

    // MARK: - Tests

    @Test("the Vault's Obsidian settings win where they set a value, and Opal's apply everywhere else")
    func vaultWins() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let (harness, _) = await Self.setUp(vault, store: StubSettingsStore(Self.mine))

        #expect(harness.vault.appSettings.newFileLocation == .folder)
        #expect(harness.vault.appSettings.attachmentFolderPath == "Attachments")
        #expect(harness.vault.appSettings.useMarkdownLinks == false)
        #expect(harness.vault.dailyNoteSettings == DailyNoteSettings(folder: "Daily Notes", format: "YYYY-MM-DD", template: "Templates/Daily"))
        #expect(harness.vault.linkUpdate == .never)
        #expect(harness.vault.vaultSettings.attachmentFolderPath == "Attachments")
        #expect(harness.vault.vaultSettings.alwaysUpdateLinks == nil)
    }

    @Test("without Obsidian settings in the Vault, Opal's settings apply")
    func opalApplies() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        try FileManager().removeItem(at: vault.url(".obsidian"))
        let (harness, _) = await Self.setUp(vault, store: StubSettingsStore(Self.mine))

        #expect(harness.vault.appSettings.newFileLocation == .current)
        #expect(harness.vault.appSettings.attachmentFolderPath == "Files")
        #expect(harness.vault.appSettings.useMarkdownLinks == true)
        #expect(harness.vault.dailyNoteSettings == DailyNoteSettings(folder: "Journal", format: "DD-MM-YYYY", template: ""))
    }

    @Test("alwaysUpdateLinks in the Vault means Always, and false means Ask")
    func alwaysUpdateLinks() {
        #expect(SettingsUseCase.linkUpdate(.defaults, vault: VaultSettings(alwaysUpdateLinks: true)) == .always)
        #expect(SettingsUseCase.linkUpdate(Self.mine, vault: VaultSettings(alwaysUpdateLinks: false)) == .ask)
    }

    @Test("changing a setting saves it in Opal's preferences and writes nothing in the Vault")
    func savesOutsideVault() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let before = try FileManager().subpathsOfDirectory(atPath: vault.rootURL.path).sorted()
        let appJSON = try vault.text(".obsidian/app.json")
        let store = StubSettingsStore()
        let (_, service) = await Self.setUp(vault, store: store)

        service.settings.linkUpdate = .always
        service.settings.dailyFormat = "YYYY/MM/DD"

        #expect(store.saved?.linkUpdate == .always)
        #expect(store.saved?.dailyFormat == "YYYY/MM/DD")
        #expect(try FileManager().subpathsOfDirectory(atPath: vault.rootURL.path).sorted() == before)
        #expect(try vault.text(".obsidian/app.json") == appJSON)
    }

    @Test("settings saved before keep their values, and missing keys take the defaults")
    func decodesOldSettings() throws {
        let decoded = try JSONDecoder().decode(OpalSettings.self, from: Data(#"{"linkUpdate":"never"}"#.utf8))
        #expect(decoded.linkUpdate == .never)
        #expect(decoded.dailyFormat == "YYYY-MM-DD")
    }

    @Test("the Daily Note preview formats today with the clock")
    func preview() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let (_, service) = await Self.setUp(vault, store: StubSettingsStore())

        #expect(service.dailyNotePreview(format: "YYYY-MM-DD") == "2026-10-26")
        #expect(service.dailyNotePreview(format: "") == "2026-10-26")
    }
}
