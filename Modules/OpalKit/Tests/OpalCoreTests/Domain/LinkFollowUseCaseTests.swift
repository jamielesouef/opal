//
//  LinkFollowUseCaseTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Testing
@testable import OpalCore

@Suite("LinkFollowUseCase", .tags(.domain))
struct LinkFollowUseCaseTests {
    // MARK: - Fixtures

    private static let map = LinkMap(
        paths: ["Soil.md", "Tomatoes.md", "Attachments/seedlings.png"].map(NotePath.init),
        parsed: [
            NotePath("Soil.md"): MarkdownNoteParser.parse("# Soil\n\nCompost. ^compost-rule\n"),
            NotePath("Tomatoes.md"): MarkdownNoteParser.parse("# Tomatoes\n\n## Watering\n\nDeep.\n")
        ]
    )

    private static let inbox = ObsidianAppSettings(
        newFileLocation: .folder,
        newFileFolderPath: "Inbox",
        attachmentFolderPath: "/",
        useMarkdownLinks: false
    )

    private static func destination(_ text: String, from source: String = "Welcome.md") throws -> LinkDestination {
        let link = try #require(MarkdownNoteParser.parse(text).links.first)
        return LinkFollowUseCase.destination(for: link, from: NotePath(source), map: map, settings: inbox)
    }

    // MARK: - Tests

    @Test("opens a resolved Note at its top")
    func note() throws {
        #expect(try Self.destination("[[soil]]") == .note(NotePath("Soil.md"), line: nil))
    }

    @Test("opens a Note at the Heading or Block a Link names", arguments: [
        ("[[Tomatoes#watering]]", 2),
        ("[[Tomatoes#Tomatoes#Watering]]", 2),
        ("[[Soil#^compost-rule]]", 2)
    ])
    func subpath(text: String, line: Int) throws {
        #expect(try Self.destination(text).note?.line == line)
    }

    @Test("a missing Heading opens the Note at its top")
    func missingHeading() throws {
        #expect(try Self.destination("[[Tomatoes#Pruning]]") == .note(NotePath("Tomatoes.md"), line: nil))
    }

    @Test("an Attachment opens outside Opal")
    func attachment() throws {
        #expect(try Self.destination("![[seedlings.png]]") == .attachment(NotePath("Attachments/seedlings.png")))
    }

    @Test("an Unresolved Link plans a new Note where new Notes go, or in the Folder it names", arguments: [
        ("[[Ideas That Do Not Exist Yet]]", "Inbox/Ideas That Do Not Exist Yet.md"),
        ("[[Ideas/New Idea]]", "Ideas/New Idea.md"),
        ("[New](New%20One.md)", "Inbox/New One.md")
    ])
    func create(text: String, expected: String) throws {
        #expect(try Self.destination(text) == .create(NotePath(expected)))
    }

    @Test("never plans a Note outside the Vault or in a hidden Folder", arguments: ["../Out", ".obsidian/x", "a/../../b"])
    func unsafe(target: String) {
        #expect(LinkFollowUseCase.newNotePath(for: target, settings: .defaults, openNote: nil) == nil)
    }
}

private extension LinkDestination {
    var note: (path: NotePath, line: Int?)? {
        guard case let .note(path, line) = self else {
            return nil
        }
        return (path, line)
    }
}
