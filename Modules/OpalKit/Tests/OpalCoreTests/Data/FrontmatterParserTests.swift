//
//  FrontmatterParserTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("Frontmatter and Properties", .tags(.parser))
struct FrontmatterParserTests {
    // MARK: - Constants

    private static let note = """
    ---
    title: "Soil: a guide"
    rating: 4.5
    done: true
    sown: 2026-03-01
    watered: 2026-03-01T08:30
    # a comment Obsidian keeps
    tags:
      - garden
      - soil
    aliases: [Dirt, 'Earth']
    note: |
      two
      lines
    empty:
    ---
    # Body
    """

    // MARK: - Parse

    @Test("reads each kind of Property with its source lines")
    func parse() throws {
        let frontmatter = try #require(FrontmatterParser.parse(Self.note))
        #expect(frontmatter.isReadable)
        #expect(frontmatter.endLine == 16)
        let byKey = Dictionary(uniqueKeysWithValues: frontmatter.properties.map { ($0.key, $0) })
        #expect(byKey["title"]?.value == .text("Soil: a guide"))
        #expect(byKey["tags"]?.value == .list(["garden", "soil"]))
        #expect(byKey["tags"]?.lines == 7 ..< 10)
        #expect(byKey["aliases"]?.value == .list(["Dirt", "Earth"]))
        #expect(byKey["note"]?.value == .unreadable("|\n  two\n  lines"))
        #expect(byKey["empty"]?.value == .text(""))
    }

    @Test("infers types from values, names and types.json")
    func types() throws {
        let frontmatter = try #require(FrontmatterParser.parse(Self.note))
        let types = frontmatter.properties.map { PropertyTypeUseCase.type(of: $0, declared: ["rating": .text]) }
        #expect(types == [.text, .text, .checkbox, .date, .dateTime, .tags, .aliases, .text, .text])
    }

    @Test("marks YAML it cannot read")
    func unreadable() throws {
        #expect(try #require(FrontmatterParser.parse("---\njust words\n---\n")).isReadable == false)
        #expect(FrontmatterParser.parse("No frontmatter") == nil)
    }

    // MARK: - Edits

    @Test("changing one Property changes only its lines")
    func setOne() throws {
        let frontmatter = try #require(FrontmatterParser.parse(Self.note))
        let tags = try #require(frontmatter.properties.first { $0.key == "tags" })
        let edited = PropertyEditUseCase.set(tags, to: .list(["garden", "compost"]), type: .tags, in: Self.note)
        #expect(edited == Self.note.replacingOccurrences(of: "  - soil\n", with: "  - compost\n"))

        let done = try #require(frontmatter.properties.first { $0.key == "done" })
        #expect(PropertyEditUseCase.set(done, to: .text("false"), type: .checkbox, in: Self.note) == Self.note.replacingOccurrences(of: "done: true", with: "done: false"))
    }

    @Test("quotes text that YAML would read as something else", arguments: [
        ("Soil: a guide", #""Soil: a guide""#),
        ("true", #""true""#),
        ("42", #""42""#),
        ("#garden", ##""#garden""##),
        ("plain words", "plain words")
    ])
    func quoting(value: String, written: String) throws {
        let text = "---\ntitle: old\n---\n"
        let property = try #require(FrontmatterParser.parse(text)?.properties.first)
        let edited = PropertyEditUseCase.set(property, to: .text(value), type: .text, in: text)
        #expect(edited == "---\ntitle: \(written)\n---\n")
        #expect(FrontmatterParser.parse(edited)?.properties.first?.value == .text(value))
    }

    @Test("keeps Windows line endings and every other byte")
    func lineEndings() throws {
        let text = "---\r\ntitle: old\r\nkeep:   spaced  # odd\r\n---\r\nBody\r\n"
        let property = try #require(FrontmatterParser.parse(text)?.properties.first)
        #expect(PropertyEditUseCase.set(property, to: .text("new"), type: .text, in: text) == "---\r\ntitle: new\r\nkeep:   spaced  # odd\r\n---\r\nBody\r\n")
    }

    @Test("adds a Property at the end, or a new frontmatter, and removes one")
    func addAndRemove() throws {
        let text = "---\ntitle: old\n---\nBody"
        let frontmatter = try #require(FrontmatterParser.parse(text))
        #expect(PropertyEditUseCase.add(key: "status", type: .text, to: text, frontmatter: frontmatter) == "---\ntitle: old\nstatus:\n---\nBody")
        #expect(PropertyEditUseCase.add(key: "tags", type: .tags, to: "Body", frontmatter: nil) == "---\ntags: []\n---\nBody")
        let title = try #require(frontmatter.properties.first)
        #expect(PropertyEditUseCase.remove(title, from: text) == "---\n---\nBody")
    }
}
