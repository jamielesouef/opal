//
//  TagTreeUseCaseTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Testing
@testable import OpalCore

@Suite("Tags", .tags(.domain))
struct TagTreeUseCaseTests {
    // MARK: - Parsing

    @Test("reads Tags from the body, skipping Headings, numbers, code and URLs")
    func bodyTags() {
        let text = """
        # Heading
        ## Harvest #garden/harvest
        Pick #Garden and #garden again. #123 is not a Tag, nor `#code`, nor https://x.com/#frag.
        (#in-brackets) end#nope
        """

        #expect(MarkdownNoteParser.parse(text).tags == ["garden/harvest", "Garden", "in-brackets"])
    }

    @Test(
        "reads the tags Property as a list, an inline list or one value",
        arguments: [
            ("---\ntags:\n  - garden\n  - '#howto'\n---\n", ["garden", "howto"]),
            ("---\ntags: [garden, reading]\n---\n", ["garden", "reading"]),
            ("---\ntags: garden howto\n---\n", ["garden", "howto"]),
            ("---\ntag: meta\n---\n", ["meta"])
        ]
    )
    func propertyTags(text: String, expected: [String]) {
        #expect(MarkdownNoteParser.parse(text).tags == expected)
    }

    @Test("does not read a Tag inside frontmatter values other than tags")
    func frontmatterOnly() {
        #expect(MarkdownNoteParser.parse("---\nnote: \"#notatag\"\n---\nbody").tags.isEmpty)
    }

    // MARK: - Tree

    @Test("nests Tags by / and counts each Note once per Tag, parents included")
    func tree() {
        let tree = TagTreeUseCase.tree(from: [
            NotePath("A.md"): ["garden", "garden/harvest"],
            NotePath("B.md"): ["Garden/Harvest"],
            NotePath("C.md"): ["project/opal"]
        ])

        #expect(tree.map(\.fullName) == ["garden", "project"])
        #expect(tree.first?.noteCount == 2)
        #expect(tree.first?.children?.map(\.name) == ["harvest"])
        #expect(tree.first?.children?.first?.noteCount == 2)
        #expect(tree.last?.children?.first?.fullName == "project/opal")
    }

    @Test("choosing a Tag searches for it")
    func query() {
        #expect(TagTreeUseCase.searchQuery(for: TagNode(name: "harvest", fullName: "garden/harvest", noteCount: 1, children: nil)) == "tag:#garden/harvest")
    }
}
