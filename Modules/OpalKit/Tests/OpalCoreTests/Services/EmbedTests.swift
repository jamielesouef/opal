//
//  EmbedTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("Embeds", .tags(.service))
@MainActor
struct EmbedTests {
    // MARK: - Helpers

    private static func harness(_ vault: FixtureVault) async -> ServiceHarness {
        let harness = ServiceHarness(store: FileSystemVaultStore(rootURL: vault.rootURL))
        await harness.openVaultWithLinks()
        return harness
    }

    private static func embed(_ text: String, in harness: ServiceHarness, from source: String = "Welcome.md", chain: [String] = ["Welcome.md"]) async throws -> EmbedContent {
        let link = try #require(MarkdownNoteParser.parse(text).links.first)
        return await harness.links.embed(link, from: NotePath(source), chain: chain.map(NotePath.init))
    }

    // MARK: - Tests

    @Test("embeds a whole Note, a Heading's section and a Block's paragraph")
    func notes() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = await Self.harness(vault)

        guard case let .note(path, title, blocks) = try await Self.embed("![[Tomatoes]]", in: harness) else {
            Issue.record("Not a Note")
            return
        }
        #expect(path == NotePath("Tomatoes.md"))
        #expect(title == "Tomatoes")
        #expect(blocks.filter(\.isHeading).count == 3)

        guard case let .note(_, sectionTitle, section) = try await Self.embed("![[Tomatoes#Watering]]", in: harness) else {
            Issue.record("Not a Note")
            return
        }
        #expect(sectionTitle == "Tomatoes > Watering")
        #expect(section.map(\.kind) == [
            .heading(level: 2, text: [ReadingInline(text: "Watering")]),
            .paragraph([ReadingInline(text: "Deep and even. Uneven watering splits the fruit.")])
        ])

        guard case let .note(_, _, block) = try await Self.embed("![[Soil#^compost-rule]]", in: harness) else {
            Issue.record("Not a Note")
            return
        }
        #expect(block.map(\.kind) == [.paragraph([ReadingInline(text: "Compost improves every kind.")])])
    }

    @Test("embeds images with their width, and says when a target is missing")
    func media() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = await Self.harness(vault)

        #expect(try await Self.embed("![[seedlings.png|300]]", in: harness) == .image(path: NotePath("Attachments/seedlings.png"), width: 300))
        #expect(try await Self.embed("![seedlings](Attachments/seedlings.png)", in: harness) == .image(path: NotePath("Attachments/seedlings.png"), width: nil))
        #expect(try await Self.embed("![[Nowhere]]", in: harness) == .unresolved("Nowhere"))
    }

    @Test("an Embed of a Note already being shown stops")
    func recursion() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let harness = await Self.harness(vault)

        #expect(try await Self.embed("![[Welcome]]", in: harness) == .recursive(NotePath("Welcome.md")))
        #expect(try await Self.embed("![[Soil]]", in: harness, chain: ["Welcome.md", "Soil.md"]) == .recursive(NotePath("Soil.md")))
    }

    @Test("Reading view puts an Embed below its line and drops a line that is only an Embed")
    func blocks() {
        let text = "Intro\n![[Soil]]\n\nSee ![[seedlings.png]] here"
        let parsed = MarkdownNoteParser.parse(text)
        let kinds = MarkdownReadingParser.blocks(in: text, parsed: parsed, styles: MarkdownStyleParser.runs(in: text, parsed: parsed)).map(\.kind)
        #expect(kinds.count == 4)
        #expect(kinds[0] == .paragraph([ReadingInline(text: "Intro")]))
        #expect(kinds[2] == .paragraph([ReadingInline(text: "See  here")]))
        guard case let .embed(link) = kinds[3] else {
            Issue.record("No Embed")
            return
        }
        #expect(link.target == "seedlings.png")
    }

    @Test("reads widths and media kinds", arguments: [
        ("Attachments/a.PNG", EmbedMedia.image), ("doc.pdf", .pdf), ("Note.md", .note), ("song.mp3", .file)
    ])
    func mediaKinds(path: String, media: EmbedMedia) {
        #expect(EmbedUseCase.media(of: NotePath(path)) == media)
        #expect(EmbedUseCase.width(from: "300x200") == 300)
        #expect(EmbedUseCase.width(from: "caption") == nil)
    }
}
