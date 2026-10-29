//
//  RecentVaultsTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("Recent Vaults", .tags(.service))
@MainActor
struct RecentVaultsTests {
    // MARK: - Fixtures

    @MainActor
    private final class Fixture {
        let suite = "OpalRecentVaultsTests-\(UUID().uuidString)"
        let defaults: UserDefaults
        let container = FileManager().temporaryDirectory.appending(component: "OpalRecentVaults-\(UUID().uuidString)")

        init() throws {
            defaults = try #require(UserDefaults(suiteName: suite))
            try FileManager().createDirectory(at: container, withIntermediateDirectories: true)
        }

        func service(access: StubVaultAccess = StubVaultAccess()) -> RecentVaultsService {
            RecentVaultsService(access: access, locations: UserDefaultsVaultLocationStore(defaults: defaults))
        }

        func folder(_ name: String) throws -> URL {
            let url = container.appending(component: name, directoryHint: .isDirectory)
            try FileManager().createDirectory(at: url, withIntermediateDirectories: true)
            return url
        }

        func remove() {
            defaults.removePersistentDomain(forName: suite)
            try? FileManager().removeItem(at: container)
        }
    }

    // MARK: - Tests

    @Test("keeps a Vault once, by resolved path, newest first, and stops at ten")
    func recording() {
        let records = (1 ... 12).map { RecentVaultRecord(bookmark: Data(), path: "/Vaults/V\($0)") }
        let capped = records.reduce([RecentVaultRecord]()) { RecentVaultsUseCase.recording($1, in: $0) }

        #expect(capped.count == RecentVaultsUseCase.limit)
        #expect(capped.map(\.path).first == "/Vaults/V12")
        #expect(capped.map(\.path).last == "/Vaults/V3")

        let again = RecentVaultsUseCase.recording(RecentVaultRecord(bookmark: Data(), path: "/Vaults/V5/"), in: capped)
        #expect(again.map(\.path).first == "/Vaults/V5/")
        #expect(again.count == RecentVaultsUseCase.limit)
        #expect(again.filter { RecentVaultsUseCase.key(for: $0.path) == RecentVaultsUseCase.key(for: "/Vaults/V5") }.count == 1)
    }

    @Test("remembers the last ten Vaults in the suite, outside the Vault, newest first")
    func remembers() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let folders = try (1 ... 12).map { try fixture.folder("V\($0)") }
        let service = fixture.service()

        for folder in folders {
            await service.record(folder)
        }
        await service.record(folders[5])

        let reopened = fixture.service()
        await reopened.load()
        #expect(reopened.vaults.count == 10)
        #expect(reopened.vaults.map(\.name) == ["V6", "V12", "V11", "V10", "V9", "V8", "V7", "V5", "V4", "V3"])
        #expect(reopened.vaults.allSatisfy { $0.isMissing == false })
        #expect(reopened.vaults.first?.parentPath == fixture.container.path(percentEncoded: false))
    }

    @Test("shows a Vault whose folder is gone as missing, and removing it leaves the others")
    func missingFolder() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let gone = try fixture.folder("Gone")
        let kept = try fixture.folder("Kept")
        let service = fixture.service()
        await service.record(gone)
        await service.record(kept)

        try FileManager().removeItem(at: gone)
        await service.load()

        let missing = try #require(service.vaults.first { $0.name == "Gone" })
        #expect(missing.isMissing)
        #expect(service.vaults.first { $0.name == "Kept" }?.isMissing == false)

        await service.remove(missing)
        #expect(service.vaults.map(\.name) == ["Kept"])
        await service.clear()
        #expect(service.vaults.isEmpty)
        #expect(fixture.service().vaults.isEmpty)
    }

    @Test("a bookmark that no longer resolves is shown as missing with its last path")
    func unresolvedBookmark() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let folder = try fixture.folder("Moved")
        await fixture.service().record(folder)

        let service = fixture.service(access: StubVaultAccess(resolvesBookmarks: false))
        await service.load()

        #expect(service.vaults.map(\.isMissing) == [true])
        #expect(service.vaults.map(\.name) == ["Moved"])
    }

    @Test("opening a Vault records it, and a Vault passed at launch is not recorded")
    func vaultServiceRecords() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let folder = try fixture.folder("Garden")
        let recents = fixture.service()
        let access = StubVaultAccess()
        let locations = UserDefaultsVaultLocationStore(defaults: fixture.defaults)
        let makeStore: @Sendable (URL) -> any VaultFileStoring = { FileSystemVaultStore(rootURL: $0) }

        let launched = VaultService(access: access, locations: locations, launchVaultURL: folder, recents: recents, makeStore: makeStore)
        await launched.start()
        #expect(recents.vaults.isEmpty)

        let opening = VaultService(access: access, locations: locations, launchVaultURL: nil, recents: recents, makeStore: makeStore)
        await opening.open(folderURL: folder)
        #expect(recents.vaults.map(\.name) == ["Garden"])
    }

    @Test("choosing a Vault opens it here with no Vault, in its own window if shown, and in a new window otherwise")
    func choosing() {
        let recent = RecentVault(record: RecentVaultRecord(bookmark: Data(), path: "/Vaults/Garden"), folderURL: URL(filePath: "/Vaults/Garden", directoryHint: .isDirectory), isMissing: false)
        let empty = UUID()
        let showing = UUID()
        let other = UUID()

        #expect(OpenVaultUseCase.decide(opening: recent.folderURL, from: empty, roots: [:]) == .openHere)
        #expect(OpenVaultUseCase.decide(opening: recent.folderURL, from: other, roots: [showing: recent.folderURL, other: URL(filePath: "/Vaults/Other")]) == .bringToFront(showing))
        #expect(OpenVaultUseCase.decide(opening: recent.folderURL, from: other, roots: [other: URL(filePath: "/Vaults/Other")]) == .openInNewWindow)
        #expect(OpenVaultUseCase.decide(opening: recent.folderURL, from: showing, roots: [showing: recent.folderURL]) == .openHere)
    }
}
