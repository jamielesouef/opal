//
//  LinkServiceIndexTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("LinkService reads the Index", .tags(.service))
@MainActor
struct LinkServiceIndexTests {
    @Test("with a ready Index, building the Link map reads no Note file")
    func readsIndex() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let store = CountingVaultStore(rootURL: vault.rootURL)
        let harness = ServiceHarness(store: store)
        defer { try? FileManager().removeItem(at: harness.indexFolder) }
        await harness.openVault()
        await harness.index.sync()
        await store.resetReads()

        await harness.links.sync()

        #expect(await store.reads == 0)
        #expect(harness.links.map.backlinks(to: NotePath("Soil.md")).count == 5)
    }

    @Test("without a ready Index, the Link map reads the files")
    func fallsBack() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let store = CountingVaultStore(rootURL: vault.rootURL)
        let harness = ServiceHarness(store: store)
        await harness.openVault()

        await harness.links.sync()

        #expect(await store.reads > 0)
        #expect(harness.links.map.backlinks(to: NotePath("Soil.md")).count == 5)
    }
}
