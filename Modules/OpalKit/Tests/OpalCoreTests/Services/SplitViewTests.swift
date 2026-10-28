//
//  SplitViewTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("Split view", .tags(.service))
@MainActor
struct SplitViewTests {
    // MARK: - Constants

    private static let soil = NotePath("Soil.md")
    private static let tomatoes = NotePath("Tomatoes.md")

    // MARK: - Helpers

    private static func split() async -> (ServiceHarness, StubVaultFileStore) {
        let store = StubVaultFileStore(files: ["Soil.md": "# Soil\n", "Tomatoes.md": "# Tomatoes\n"])
        let harness = ServiceHarness(store: store)
        await harness.openVault()
        await harness.navigation.open(soil)
        await harness.navigation.splitRight()
        return (harness, store)
    }

    // MARK: - Tests

    @Test("the same Note in both panes is one text, and an edit is saved once")
    func sharesOneDocument() async {
        let (harness, store) = await Self.split()

        #expect(harness.notes.documents.count == 1)
        harness.notes.document(for: Self.soil)?.edit("# Soil\n\nLoam.\n")
        await harness.navigation.focusPane(0)
        #expect(harness.notes.loadState.note?.text == "# Soil\n\nLoam.\n")
        await harness.notes.flush()

        #expect(await store.writeCount == 1)
        #expect(await store.text("Soil.md") == "# Soil\n\nLoam.\n")
    }

    @Test("the focused pane gets new Notes and the other pane keeps its own")
    func focusedPaneOpens() async {
        let (harness, _) = await Self.split()

        await harness.navigation.open(Self.tomatoes)

        #expect(harness.navigation.panes.panes.map(\.selected.path) == [Self.soil, Self.tomatoes])
        #expect(harness.notes.path == Self.tomatoes)
        #expect(harness.notes.document(for: Self.soil)?.loadState.note?.text == "# Soil\n")
        await harness.navigation.focusPane(0)
        #expect(harness.notes.path == Self.soil)
    }

    @Test("closing a pane saves and drops a Note no pane shows any more")
    func closingPaneDropsDocument() async {
        let (harness, store) = await Self.split()
        await harness.navigation.open(Self.tomatoes)
        harness.notes.edit("# Tomatoes\n\nStaked.\n")

        await harness.navigation.closeTab(harness.navigation.tabs.selectedID)

        #expect(harness.navigation.panes.isSplit == false)
        #expect(harness.notes.path == Self.soil)
        #expect(harness.notes.document(for: Self.tomatoes) == nil)
        #expect(await store.text("Tomatoes.md") == "# Tomatoes\n\nStaked.\n")
    }
}
