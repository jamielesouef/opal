//
//  WindowRegistryTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("WindowRegistry", .tags(.service))
@MainActor
struct WindowRegistryTests {
    // MARK: - Fixtures

    @MainActor
    private final class Fixture {
        let defaults: UserDefaults
        let suite = "OpalWindowTests-\(UUID().uuidString)"
        let indexFolder = FileManager().temporaryDirectory.appending(component: "OpalWindowIndexes-\(UUID().uuidString)")
        let windows = StubWindowListStore()
        let settings = SettingsService(store: StubSettingsStore(), clock: ServiceHarness.clock)

        init() {
            defaults = UserDefaults(suiteName: suite) ?? .standard
        }

        func registry() -> WindowRegistry {
            WindowRegistry(store: windows) { [self] id, isFirst in
                let vault = VaultService(
                    access: StubVaultAccess(),
                    locations: UserDefaultsVaultLocationStore(defaults: defaults, windowID: id, fallsBackToLastVault: isFirst),
                    launchVaultURL: nil
                ) { FileSystemVaultStore(rootURL: $0) }
                return ServiceGraph(
                    vault: vault,
                    makeIndex: { [indexFolder] root throws(IndexError) in
                        try GRDBIndexStore(folderURL: IndexLocation.folder(forVaultAt: root, in: indexFolder))
                    },
                    recents: StubRecentNotesStore(),
                    windowID: id,
                    windows: windows,
                    settings: settings,
                    clock: ServiceHarness.clock,
                    saveDelay: .seconds(3600)
                )
            }
        }

        func remove() {
            defaults.removePersistentDomain(forName: suite)
            try? FileManager().removeItem(at: indexFolder)
        }
    }

    // MARK: - Tests

    @Test("two windows on two Vaults share no Notes, Links, tabs or history")
    func windowsAreSeparate() async throws {
        let garden = try FixtureVault()
        let empty = try FixtureVault.empty()
        let fixture = Fixture()
        defer { garden.remove(); empty.remove(); fixture.remove() }
        let registry = fixture.registry()
        let first = registry.graph(for: UUID())
        let second = registry.graph(for: UUID())

        await first.vault.open(folderURL: garden.rootURL)
        await second.vault.open(folderURL: empty.rootURL)
        await first.syncFollowers()
        await second.syncFollowers()
        await first.navigation.open(NotePath("Soil.md"))
        first.notes.edit("# Soil\n\nLoam.\n")

        #expect(second.notes.path == nil)
        #expect(second.navigation.tabs.paths.isEmpty)
        #expect(second.navigation.history.canGoBack == false)
        #expect(first.links.map.backlinks(to: NotePath("Soil.md")).isEmpty == false)
        #expect(second.links.map.backlinks(to: NotePath("Soil.md")).isEmpty)
        #expect(second.vault.kind(of: NotePath("Soil.md")) == nil)
        await first.notes.flush()
        #expect(try garden.text("Soil.md") == "# Soil\n\nLoam.\n")
    }

    @Test("a Vault already open in a window brings that window to the front")
    func oneWindowPerVault() async throws {
        let garden = try FixtureVault()
        let fixture = Fixture()
        defer { garden.remove(); fixture.remove() }
        let registry = fixture.registry()
        let firstID = UUID()
        let secondID = UUID()
        await registry.graph(for: firstID).vault.open(folderURL: garden.rootURL)
        _ = registry.graph(for: secondID)

        #expect(registry.decide(opening: garden.rootURL, from: secondID) == .bringToFront(firstID))
        #expect(registry.decide(opening: garden.rootURL.appending(path: "Areas/.."), from: secondID) == .bringToFront(firstID))
        #expect(registry.decide(opening: garden.rootURL, from: firstID) == .openHere)
        #expect(registry.window(showing: garden.rootURL) == firstID)
    }

    @Test("Open Vault opens here in an empty window and in a new window otherwise")
    func decidesWhereToOpen() {
        let window = UUID()
        let other = URL(filePath: "/Vaults/Work")
        #expect(OpenVaultUseCase.decide(opening: other, from: window, roots: [:]) == .openHere)
        #expect(OpenVaultUseCase.decide(opening: other, from: window, roots: [window: URL(filePath: "/Vaults/Garden")]) == .openInNewWindow)
    }

    @Test("windows and their Vaults come back at the next launch")
    func restores() async throws {
        let garden = try FixtureVault()
        let empty = try FixtureVault.empty()
        let fixture = Fixture()
        defer { garden.remove(); empty.remove(); fixture.remove() }
        let firstID = UUID()
        let secondID = UUID()
        let before = fixture.registry()
        await before.graph(for: firstID).vault.open(folderURL: garden.rootURL)
        await before.graph(for: secondID).vault.open(folderURL: empty.rootURL)
        before.isQuitting = true
        await before.close(firstID)
        await before.close(secondID)

        let after = fixture.registry()
        #expect(after.restoredIDs == [firstID, secondID])
        #expect(after.firstWindowID == firstID)
        await after.graph(for: firstID).vault.start()
        await after.graph(for: secondID).vault.start()
        #expect(after.window(showing: garden.rootURL) == firstID)
        #expect(after.window(showing: empty.rootURL) == secondID)
    }

    @Test("closing a window saves its Notes and forgets it")
    func closes() async throws {
        let garden = try FixtureVault()
        let fixture = Fixture()
        defer { garden.remove(); fixture.remove() }
        let registry = fixture.registry()
        let id = UUID()
        let graph = registry.graph(for: id)
        await graph.vault.open(folderURL: garden.rootURL)
        await graph.navigation.open(NotePath("Soil.md"))
        graph.notes.edit("# Soil\n\nClosed.\n")

        await registry.close(id)

        #expect(try garden.text("Soil.md") == "# Soil\n\nClosed.\n")
        #expect(registry.windowIDs.isEmpty)
        #expect(fixture.windows.windowIDs().isEmpty)
        #expect(fixture.windows.windowState(for: id) == nil)
        #expect(graph.vault.isOpen == false)
        #expect(fixture.settings.activeVault == nil)
    }

    @Test("each window's panes, focus, split share and frame come back, without Notes that are gone")
    func restoresWindowState() async throws {
        let garden = try FixtureVault()
        let empty = try FixtureVault.empty()
        let fixture = Fixture()
        defer { garden.remove(); empty.remove(); fixture.remove() }
        let firstID = UUID()
        let secondID = UUID()
        let firstFrame = WindowFrame(x: 40, y: 60, width: 900, height: 700)
        let secondFrame = WindowFrame(x: 500, y: 80, width: 800, height: 600)
        let before = fixture.registry()
        let first = before.graph(for: firstID)
        await first.vault.open(folderURL: garden.rootURL)
        await first.syncFollowers()
        await first.navigation.open(NotePath("Welcome.md"))
        await first.navigation.openInNewTab(NotePath("Tomatoes.md"))
        await first.navigation.splitRight()
        await first.navigation.open(NotePath("Soil.md"))
        first.navigation.setSplitShare(0.65)
        await first.navigation.focusPane(0)
        before.setFrame(firstFrame, for: firstID)
        await before.graph(for: secondID).vault.open(folderURL: empty.rootURL)
        before.setFrame(secondFrame, for: secondID)
        before.isQuitting = true
        await before.close(firstID)
        await before.close(secondID)
        try FileManager().removeItem(at: garden.rootURL.appending(path: "Soil.md"))

        let after = fixture.registry()
        let restored = after.graph(for: firstID)
        await restored.vault.start()
        await restored.navigation.restoreWindowState()
        #expect(restored.navigation.panes.paths == [[NotePath("Welcome.md"), NotePath("Tomatoes.md")], []])
        #expect(restored.navigation.panes.focusedIndex == 0)
        #expect(restored.navigation.panes.splitShare == 0.65)
        #expect(after.savedFrame(for: firstID) == firstFrame)
        #expect(after.savedFrame(for: secondID) == secondFrame)
        let other = after.graph(for: secondID)
        await other.vault.start()
        await other.navigation.restoreWindowState()
        #expect(other.navigation.panes.isSplit == false)
        #expect(other.navigation.panes.paths == [[]])
    }
}
