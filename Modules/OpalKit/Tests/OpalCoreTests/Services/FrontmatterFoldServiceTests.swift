//
//  FrontmatterFoldServiceTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("Folded frontmatter", .tags(.service))
@MainActor
struct FrontmatterFoldServiceTests {
    // MARK: - Constants

    private static let tomatoes = NotePath("Tomatoes.md")

    // MARK: - Helpers

    private static func open() async throws -> (ServiceHarness, FixtureVault, String) {
        let vault = try FixtureVault()
        let harness = ServiceHarness(store: FileSystemVaultStore(rootURL: vault.rootURL))
        await harness.openVault()
        let before = try vault.text(tomatoes.rawValue)
        await harness.navigation.open(tomatoes)
        await harness.links.waitForOpenNote()
        return (harness, vault, before)
    }

    // MARK: - Tests

    @Test("the fold hides the frontmatter lines and nothing of the body")
    func foldCoversFrontmatter() async throws {
        let (harness, vault, before) = try await Self.open()
        defer { vault.remove() }
        let text = try #require(harness.notes.loadState.note?.text)
        let fold = try #require(FrontmatterFoldUseCase.fold(in: text))

        #expect(text == before)
        #expect((text as NSString).substring(from: fold.end).hasPrefix("# Tomatoes"))
    }

    @Test("opening a folded Note and leaving it writes nothing")
    func openingWritesNothing() async throws {
        let (harness, vault, before) = try await Self.open()
        defer { vault.remove() }
        await harness.notes.flush()

        #expect(try vault.text(Self.tomatoes.rawValue) == before)
    }

    @Test("typing in the body of a folded Note saves the frontmatter byte for byte")
    func bodyEditKeepsFrontmatter() async throws {
        let (harness, vault, before) = try await Self.open()
        defer { vault.remove() }
        let fold = try #require(FrontmatterFoldUseCase.fold(in: before))
        let edited = (before as NSString).replacingCharacters(in: NSRange(location: fold.end, length: 0), with: "Sun first. ")

        harness.notes.document(for: Self.tomatoes)?.edit(edited)
        await harness.notes.flush()

        #expect(try vault.text(Self.tomatoes.rawValue) == edited)
        #expect(try vault.text(Self.tomatoes.rawValue).hasPrefix((before as NSString).substring(to: fold.end)))
    }

    @Test("an edit made through the form changes only its line, and the Note stays folded")
    func formEditStaysFolded() async throws {
        let (harness, vault, before) = try await Self.open()
        defer { vault.remove() }
        let planted = try #require(harness.notes.frontmatter?.properties.first { $0.key == "planted" })

        harness.notes.setProperty(planted, to: .text("2026-04-01"))
        await harness.notes.flush()
        await harness.links.waitForOpenNote()

        let after = try vault.text(Self.tomatoes.rawValue)
        #expect(after == before.replacingOccurrences(of: "planted: 2026-03-14", with: "planted: 2026-04-01"))
        #expect(harness.notes.frontmatter?.properties.first { $0.key == "planted" }?.value == .text("2026-04-01"))
        let fold = try #require(FrontmatterFoldUseCase.fold(in: after))
        #expect((after as NSString).substring(from: fold.end) == (before as NSString).substring(from: try #require(FrontmatterFoldUseCase.fold(in: before)).end))
    }

    @Test("adding a Property grows the folded lines and leaves the body")
    func addGrowsFold() async throws {
        let (harness, vault, before) = try await Self.open()
        defer { vault.remove() }
        let oldFold = try #require(FrontmatterFoldUseCase.fold(in: before))

        harness.notes.addProperty(named: "status")
        await harness.notes.flush()

        let after = try vault.text(Self.tomatoes.rawValue)
        let newFold = try #require(FrontmatterFoldUseCase.fold(in: after))
        #expect(newFold.end == oldFold.end + "status:\n".utf16.count)
        #expect((after as NSString).substring(from: newFold.end) == (before as NSString).substring(from: oldFold.end))
    }

    @Test("Edit as YAML unfolds a Note, and unfolding is remembered per Note")
    func unfoldIsPerNote() async throws {
        let (harness, vault, _) = try await Self.open()
        defer { vault.remove() }

        #expect(harness.navigation.unfoldedFrontmatter.isEmpty)
        harness.navigation.unfoldFrontmatter(of: Self.tomatoes)
        #expect(harness.navigation.unfoldedFrontmatter == [Self.tomatoes])
        #expect(harness.navigation.unfoldedFrontmatter.contains(NotePath("Soil.md")) == false)
    }
}
