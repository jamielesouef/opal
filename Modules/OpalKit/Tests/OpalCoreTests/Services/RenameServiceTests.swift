//
//  RenameServiceTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("RenameService", .tags(.service))
@MainActor
struct RenameServiceTests {
    // MARK: - Helpers

    private static func setUp(_ vault: FixtureVault) async -> (ServiceHarness, RenameService) {
        let harness = ServiceHarness(store: FileSystemVaultStore(rootURL: vault.rootURL))
        await harness.openVaultWithLinks()
        return (harness, harness.graph.renames)
    }

    // MARK: - Tests

    @Test("renaming a Note updates every Link to it and nothing else")
    func renamesAndUpdates() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let (harness, service) = await Self.setUp(vault)
        let basicsBefore = try vault.text("Gardening Basics.md")
        await harness.navigation.open(NotePath("Soil.md"))

        let plan = try service.plan(renaming: NotePath("Soil.md"), to: "Earth").get()
        #expect(plan.linkingNotes == [NotePath("Areas/Health.md"), NotePath("Gardening Basics.md"), NotePath("Reading/The Soil Book.md"), NotePath("Tomatoes.md")])

        let renamed = try await service.perform(plan, from: NotePath("Soil.md"), updatingLinks: true)

        #expect(renamed == NotePath("Earth.md"))
        #expect(FileManager().fileExists(atPath: vault.url("Soil.md").path) == false)
        #expect(try vault.text("Tomatoes.md").contains("[[Earth|rich earth]]"))
        #expect(try vault.text("Tomatoes.md").contains("[[Earth#^compost-rule]]"))
        #expect(try vault.text("Areas/Health.md").contains("[soil](Earth.md)"))
        #expect(try vault.text("Gardening Basics.md") == basicsBefore.replacingOccurrences(of: "[[Soil]]", with: "[[Earth]]"))
        #expect(harness.notes.path == NotePath("Earth.md"))
        #expect(harness.vault.kind(of: NotePath("Earth.md")) == .note)
    }

    @Test("Don't Update renames only the file")
    func renamesOnly() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let (_, service) = await Self.setUp(vault)
        let tomatoes = try vault.text("Tomatoes.md")

        let plan = try service.plan(renaming: NotePath("Soil.md"), to: "Earth").get()
        try await service.perform(plan, from: NotePath("Soil.md"), updatingLinks: false)

        #expect(try vault.text("Tomatoes.md") == tomatoes)
        #expect(FileManager().fileExists(atPath: vault.url("Earth.md").path))
    }

    @Test("a change of case renames the file")
    func caseOnly() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let (harness, service) = await Self.setUp(vault)

        let plan = try service.plan(renaming: NotePath("Soil.md"), to: "soil").get()
        try await service.perform(plan, from: NotePath("Soil.md"), updatingLinks: true)

        #expect(try FileManager().contentsOfDirectory(atPath: vault.rootURL.path).contains("soil.md"))
        #expect(harness.vault.kind(of: NotePath("soil.md")) == .note)
    }

    @Test("renaming a Folder moves everything in it and updates Links by path only")
    func renamesFolder() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let (harness, service) = await Self.setUp(vault)
        await harness.navigation.open(NotePath("Projects/Opal/Opal Roadmap.md"))

        let plan = try service.plan(renaming: NotePath("Projects"), to: "Work").get()
        #expect(plan.moves[NotePath("Projects/Opal/Opal Roadmap.md")] == NotePath("Work/Opal/Opal Roadmap.md"))
        try await service.perform(plan, from: NotePath("Projects"), updatingLinks: true)

        #expect(try vault.text("Welcome.md").contains("[[Work/Opal/Opal Roadmap|roadmap]]"))
        #expect(harness.vault.kind(of: NotePath("Work/Opal/Opal Roadmap.md")) == .note)
        #expect(harness.vault.kind(of: NotePath("Projects")) == nil)
        #expect(harness.notes.path == NotePath("Work/Opal/Opal Roadmap.md"))
    }

    @Test("moving a Note into a Folder updates path Links and keeps name Links")
    func moves() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let (harness, service) = await Self.setUp(vault)

        let plan = try service.plan(moving: NotePath("Soil.md"), into: NotePath("Areas")).get()
        try await service.perform(plan, from: NotePath("Soil.md"), updatingLinks: true)

        #expect(harness.vault.kind(of: NotePath("Areas/Soil.md")) == .note)
        #expect(try vault.text("Tomatoes.md").contains("[[Soil|rich earth]]"))
        #expect(try vault.text("Areas/Health.md").contains("[soil](Soil.md)"))
    }

    @Test("deleting moves a Note to the Trash, closes it, and leaves Links to it Unresolved")
    func trashes() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let trash = FileManager().temporaryDirectory.appending(component: "OpalTrash-\(UUID().uuidString)")
        defer { try? FileManager().removeItem(at: trash) }
        let harness = ServiceHarness(store: FileSystemVaultStore(rootURL: vault.rootURL, trashFolderURL: trash))
        await harness.openVaultWithLinks()
        let service = harness.graph.renames
        let tomatoes = try vault.text("Tomatoes.md")
        await harness.navigation.open(NotePath("Soil.md"))

        try await service.trash(NotePath("Soil.md"))

        #expect(FileManager().fileExists(atPath: vault.url("Soil.md").path) == false)
        #expect(try FileManager().contentsOfDirectory(atPath: trash.path).contains { $0.hasSuffix("Soil.md") })
        #expect(harness.notes.path == nil)
        #expect(harness.vault.kind(of: NotePath("Soil.md")) == nil)
        #expect(try vault.text("Tomatoes.md") == tomatoes)
        #expect(service.notesInside(NotePath("Projects")) == 2)
    }
}
