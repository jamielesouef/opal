//
//  PropertyServiceTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("NoteService Properties", .tags(.service))
@MainActor
struct PropertyServiceTests {
    @Test("editing a Property in the form writes only its lines")
    func editWritesOnlyItsLines() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = ServiceHarness(store: FileSystemVaultStore(rootURL: vault.rootURL))
        await harness.openVault()
        let path = NotePath("Welcome.md")
        let before = try vault.text(path.rawValue)
        await harness.navigation.open(path)
        await harness.links.waitForOpenNote()

        let created = try #require(harness.notes.frontmatter?.properties.first { $0.key == "created" })
        harness.notes.setProperty(created, to: .text("2026-02-01"))
        await harness.notes.flush()

        #expect(try vault.text(path.rawValue) == before.replacingOccurrences(of: "created: 2026-01-04", with: "created: 2026-02-01"))
    }

    @Test("types come from .obsidian/types.json when it is there")
    func declaredTypes() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let folder = vault.url(".obsidian")
        try FileManager().createDirectory(at: folder, withIntermediateDirectories: true)
        try Data(#"{"types":{"created":"text","rating":"number","odd":"unknown"}}"#.utf8).write(to: folder.appending(path: "types.json"))
        let harness = ServiceHarness(store: FileSystemVaultStore(rootURL: vault.rootURL))
        await harness.openVault()
        await harness.navigation.open(NotePath("Welcome.md"))
        await harness.links.waitForOpenNote()

        #expect(harness.vault.propertyTypes == ["created": .text, "rating": .number])
        let created = try #require(harness.notes.frontmatter?.properties.first { $0.key == "created" })
        #expect(harness.notes.type(of: created) == .text)
    }

    @Test("adding a Property appends it to the frontmatter")
    func add() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = ServiceHarness(store: FileSystemVaultStore(rootURL: vault.rootURL))
        await harness.openVault()
        await harness.navigation.open(NotePath("Welcome.md"))
        await harness.links.waitForOpenNote()

        harness.notes.addProperty(named: "status")
        harness.notes.addProperty(named: "status")
        await harness.links.waitForOpenNote()

        #expect(harness.notes.frontmatter?.properties.map(\.key) == ["aliases", "tags", "created", "status"])
    }

    @Test("a Property takes its type from the Vault, and from its own value until the Index is ready")
    func vaultWideType() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        for (index, rating) in ["4", "5", "3"].enumerated() {
            try vault.write("---\nrating: \(rating)\n---\n", to: "Rated \(index).md")
        }
        try vault.write("---\nrating: high\n---\n", to: "Odd.md")
        let harness = ServiceHarness(store: FileSystemVaultStore(rootURL: vault.rootURL))
        await harness.openVault()
        await harness.navigation.open(NotePath("Odd.md"))
        await harness.links.waitForOpenNote()
        let document = try #require(harness.notes.focused)
        let rating = try #require(harness.notes.frontmatter?.properties.first { $0.key == "rating" })

        await document.refreshPropertyTypes()
        #expect(document.type(of: rating) == .text)

        await harness.index.sync()
        await document.refreshPropertyTypes()
        #expect(document.type(of: rating) == .number)
        #expect(harness.notes.type(of: rating) == .number)
    }

    @Test("types.json still wins over the Vault-wide type")
    func declaredBeatsVaultWide() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let folder = vault.url(".obsidian")
        try FileManager().createDirectory(at: folder, withIntermediateDirectories: true)
        try Data(#"{"types":{"rating":"text"}}"#.utf8).write(to: folder.appending(path: "types.json"))
        for index in 0 ..< 3 {
            try vault.write("---\nrating: \(index)\n---\n", to: "Rated \(index).md")
        }
        let harness = ServiceHarness(store: FileSystemVaultStore(rootURL: vault.rootURL))
        await harness.openVault()
        await harness.navigation.open(NotePath("Rated 0.md"))
        await harness.links.waitForOpenNote()
        await harness.index.sync()
        let document = try #require(harness.notes.focused)
        let rating = try #require(harness.notes.frontmatter?.properties.first { $0.key == "rating" })

        await document.refreshPropertyTypes()

        #expect(document.type(of: rating) == .text)
    }

    @Test("when the Index changes, the form's types follow")
    func typesFollowTheIndex() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        try vault.write("---\nrating: 4\n---\n", to: "Mine.md")
        let harness = ServiceHarness(store: FileSystemVaultStore(rootURL: vault.rootURL))
        await harness.openVault()
        await harness.index.sync()
        await harness.navigation.open(NotePath("Mine.md"))
        await harness.links.waitForOpenNote()
        let document = try #require(harness.notes.focused)
        let rating = try #require(harness.notes.frontmatter?.properties.first { $0.key == "rating" })
        await document.refreshPropertyTypes()
        #expect(document.type(of: rating) == .number)

        var paths: Set<NotePath> = []
        for index in 0 ..< 3 {
            try vault.write("---\nrating: low\n---\n", to: "Text \(index).md")
            paths.insert(NotePath("Text \(index).md"))
        }
        await harness.index.update(paths)
        await document.refreshPropertyTypes()

        #expect(document.type(of: rating) == .text)
    }
}
