//
//  LargeVaultPerformanceTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite(
    "Large Vault performance",
    .tags(.performance),
    .serialized,
    .enabled(if: ProcessInfo.processInfo.environment["OPAL_PERF"] != nil, "Set OPAL_PERF=1 and use -c release")
)
@MainActor
struct LargeVaultPerformanceTests {
    // MARK: - Constants

    private enum Constants {
        static let noteCount = 10_000
        static let firstIndexLimit = Duration.seconds(20)
        static let reopenLimit = Duration.seconds(1)
        static let searchLimit = Duration.milliseconds(100)
        static let words = "soil water seed root leaf compost garden harvest tomato pea bean sun rain frost mulch spade trowel bed row weed".split(separator: " ")
    }

    // MARK: - Helpers

    private static func makeVault() throws -> URL {
        let root = FileManager().temporaryDirectory.appending(component: "OpalLargeVault-\(UUID().uuidString)")
        var generator = SystemRandomNumberGenerator()
        for index in 0 ..< Constants.noteCount {
            let folder = root.appending(component: "Area \(index % 40)")
            try FileManager().createDirectory(at: folder, withIntermediateDirectories: true)
            let body = (0 ..< 25).map { _ in
                (0 ..< 14).map { _ in String(Constants.words.randomElement(using: &generator) ?? "soil") }.joined(separator: " ")
            }.joined(separator: ".\n")
            let links = (0 ..< 3).map { _ in "[[Note \(Int.random(in: 0 ..< Constants.noteCount, using: &generator))]]" }.joined(separator: " ")
            let text = "---\ntags: [garden]\n---\n# Note \(index)\n\n\(body)\n\nSee \(links) #topic/soil\n"
            try Data(text.utf8).write(to: folder.appending(component: "Note \(index).md"))
        }
        return root
    }

    private static func open(_ root: URL, indexFolder: URL) async -> (VaultService, IndexService, LinkService) {
        let vault = VaultService(access: StubVaultAccess(), locations: StubVaultLocationStore(), launchVaultURL: nil) { FileSystemVaultStore(rootURL: $0) }
        let index = IndexService(vault: vault) { root throws(IndexError) in
            try GRDBIndexStore(folderURL: IndexLocation.folder(forVaultAt: root, in: indexFolder))
        }
        let links = LinkService(vault: vault, index: index)
        await vault.open(folderURL: root)
        return (vault, index, links)
    }

    // MARK: - Test

    @Test("10,000 Notes: first index, reopen with no changes, and Search stay within budget")
    func largeVault() async throws {
        let root = try Self.makeVault()
        let indexFolder = FileManager().temporaryDirectory.appending(component: "OpalLargeIndex-\(UUID().uuidString)")
        defer {
            try? FileManager().removeItem(at: root)
            try? FileManager().removeItem(at: indexFolder)
        }
        let clock = ContinuousClock()

        let (_, firstIndex, firstLinks) = await Self.open(root, indexFolder: indexFolder)
        let first = await clock.measure {
            await firstIndex.sync()
            await firstLinks.sync()
        }

        let (_, index, links) = await Self.open(root, indexFolder: indexFolder)
        let reopen = await clock.measure {
            await index.sync()
            await links.sync()
        }

        let store = try #require(index.store)
        var hits: [SearchHit] = []
        let search = try await clock.measure {
            hits = try await store.search(SearchQueryUseCase.parse("compost harv"), limit: SearchService.resultLimit)
        }

        #expect(hits.isEmpty == false)
        #expect(links.map.parsed.count == Constants.noteCount)
        #expect(first < Constants.firstIndexLimit, "First index took \(first)")
        #expect(reopen < Constants.reopenLimit, "Reopen took \(reopen)")
        #expect(search < Constants.searchLimit, "Search took \(search)")
    }
}
