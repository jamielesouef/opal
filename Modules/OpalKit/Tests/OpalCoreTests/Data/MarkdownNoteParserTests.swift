//
//  MarkdownNoteParserTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("MarkdownNoteParser", .tags(.parser))
struct MarkdownNoteParserTests {
    // MARK: - Wikilinks

    @Test(
        "reads each kind of wikilink",
        arguments: [
            ("[[Soil]]", "Soil", nil, nil, false),
            ("[[Soil|rich earth]]", "Soil", nil, "rich earth", false),
            ("[[Tomatoes#Watering]]", "Tomatoes", LinkSubpath.heading("Watering"), nil, false),
            ("[[Soil#^compost-rule]]", "Soil", LinkSubpath.block("compost-rule"), nil, false),
            ("[[Projects/Opal/Opal Roadmap|roadmap]]", "Projects/Opal/Opal Roadmap", nil, "roadmap", false),
            ("![[seedlings.png]]", "seedlings.png", nil, nil, true),
            ("[[#Harvest]]", "", LinkSubpath.heading("Harvest"), nil, false)
        ]
    )
    func wikilinks(text: String, target: String, subpath: LinkSubpath?, display: String?, isEmbed: Bool) throws {
        let link = try #require(MarkdownNoteParser.parse(text).links.first)

        #expect(link.target == target)
        #expect(link.subpath == subpath)
        #expect(link.displayText == display)
        #expect(link.isEmbed == isEmbed)
        #expect(link.style == .wiki)
    }

    @Test("gives each Link its UTF-16 span, line and line text")
    func spans() throws {
        let text = "# Café 🌱\n\nRead [[Soil]] now."
        let link = try #require(MarkdownNoteParser.parse(text).links.first)

        #expect((text as NSString).substring(with: NSRange(location: link.span.location, length: link.span.length)) == "[[Soil]]")
        #expect(link.line == 2)
        #expect(link.lineText == "Read [[Soil]] now.")
    }

    // MARK: - Markdown links

    @Test("reads a Markdown Link and decodes its path")
    func markdownLink() throws {
        let link = try #require(MarkdownNoteParser.parse("See [the roadmap](Projects/Opal/Opal%20Roadmap.md#Milestone%202).").links.first)

        #expect(link.target == "Projects/Opal/Opal Roadmap.md")
        #expect(link.subpath == .heading("Milestone 2"))
        #expect(link.displayText == "the roadmap")
        #expect(link.style == .markdown)
    }

    @Test("reads a Markdown Link in angle brackets")
    func angleBrackets() {
        #expect(MarkdownNoteParser.parse("[x](<My Note.md>)").links.map(\.target) == ["My Note.md"])
    }

    @Test("skips web and mail Links", arguments: ["[site](https://example.com)", "[me](mailto:a@b.c)", "[x](obsidian://open)"])
    func skipsURLs(text: String) {
        #expect(MarkdownNoteParser.parse(text).links.isEmpty)
    }

    // MARK: - Code and frontmatter

    @Test("ignores Links in fenced code, inline code and frontmatter")
    func ignoresCode() {
        let text = """
        ---
        related: "[[Hidden]]"
        ---
        ```swift
        // [[In Fence]]
        ```
        ~~~
        [[In Tilde Fence]]
        ~~~
        Use `[[Inline]]` or ``[[Double]]``, then [[Real]].
        """

        #expect(MarkdownNoteParser.parse(text).links.map(\.target) == ["Real"])
    }

    @Test("an unclosed fence hides the rest of the Note")
    func unclosedFence() {
        #expect(MarkdownNoteParser.parse("```\n[[A]]\n").links.isEmpty)
    }

    // MARK: - Headings and Blocks

    @Test("reads Headings with their level and line, outside code")
    func headings() {
        let parsed = MarkdownNoteParser.parse("# Soil\n\n## Watering ##\n```\n# not\n```\n####### seven\n#tag")

        #expect(parsed.headings == [Heading(level: 1, text: "Soil", line: 0), Heading(level: 2, text: "Watering", line: 2)])
    }

    @Test("reads a Block id at the end of a line")
    func blocks() {
        let parsed = MarkdownNoteParser.parse("Compost improves every kind. ^compost-rule\nnot^this")

        #expect(parsed.blocks == [Block(id: "compost-rule", line: 0)])
    }

    // MARK: - Aliases

    @Test(
        "reads aliases as a list, an inline list or one value",
        arguments: [
            ("---\naliases:\n  - Dirt\n  - \"Earth\"\ntags: [garden]\n---\n", ["Dirt", "Earth"]),
            ("---\naliases: [Dirt, 'Earth']\n---\n", ["Dirt", "Earth"]),
            ("---\nalias: Dirt\n---\n", ["Dirt"]),
            ("---\ntags: [x]\n---\n", []),
            ("aliases: [Dirt]\n", [])
        ]
    )
    func aliases(text: String, expected: [String]) {
        #expect(MarkdownNoteParser.parse(text).aliases == expected)
    }

    // MARK: - Lines

    @Test("keeps offsets right with Windows line endings")
    func crlf() throws {
        let text = "a\r\n[[B]]"
        let link = try #require(MarkdownNoteParser.parse(text).links.first)

        #expect(link.span.location == 3)
        #expect(MarkdownNoteParser.lineStartOffsets(in: text) == [0, 3])
    }

    // MARK: - Fixture

    @Test("reads the fixture Vault's Opal Roadmap without the code Links")
    func fixtureRoadmap() throws {
        let vault = try FixtureVault()
        defer { vault.remove() }

        let parsed = MarkdownNoteParser.parse(try vault.text("Projects/Opal/Opal Roadmap.md"))

        #expect(parsed.links.map(\.target) == ["Welcome"])
        #expect(parsed.headings.map(\.text) == ["Opal Roadmap", "Milestone 1", "Milestone 2"])
    }
}
