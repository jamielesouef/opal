//
//  AttachmentUseCaseTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("AttachmentUseCase")
struct AttachmentUseCaseTests {
    // MARK: - Place

    @Test(
        "places an Attachment by attachmentFolderPath",
        arguments: [
            ("/", ""), ("", ""), ("Attachments", "Attachments"), ("./", "Projects/Opal"), ("./assets", "Projects/Opal/assets")
        ]
    )
    func folder(setting: String, expected: String) {
        #expect(AttachmentUseCase.folder(for: NotePath("Projects/Opal/Roadmap.md"), attachmentFolderPath: setting) == NotePath(expected))
    }

    @Test("names a pasted image by the time, in the user's time zone")
    func pastedName() throws {
        let zone = try #require(TimeZone(identifier: "Australia/Sydney"))
        #expect(AttachmentUseCase.pastedName(at: Date(timeIntervalSince1970: 1_793_000_000), timeZone: zone) == "Pasted image 20261026183320.png")
    }

    @Test("never takes a name that is in use, ignoring case")
    func available() {
        let existing: Set = [NotePath("Attachments/seedlings.png"), NotePath("Attachments/Seedlings 1.PNG")]
        #expect(AttachmentUseCase.availablePath(named: "seedlings.png", in: NotePath("Attachments"), existing: existing) == NotePath("Attachments/seedlings 2.png"))
        #expect(AttachmentUseCase.availablePath(named: "new.png", in: NotePath("Attachments"), existing: existing) == NotePath("Attachments/new.png"))
    }

    // MARK: - Embed

    @Test(
        "writes the Embed in the Vault's Link format",
        arguments: [
            (LinkFormat.shortest, false, "![[seedlings.png]]"),
            (.absolute, false, "![[Attachments/seedlings.png]]"),
            (.relative, false, "![[../../Attachments/seedlings.png]]"),
            (.shortest, true, "![](seedlings.png)")
        ]
    )
    func embed(format: LinkFormat, markdown: Bool, expected: String) {
        let settings = ObsidianAppSettings(newFileLocation: .root, newFileFolderPath: "", attachmentFolderPath: "Attachments", useMarkdownLinks: markdown, newLinkFormat: format)
        let attachment = NotePath("Attachments/seedlings.png")
        #expect(AttachmentUseCase.embedText(for: attachment, from: NotePath("Projects/Opal/Roadmap.md"), existing: [attachment], settings: settings) == expected)
    }

    @Test("uses the full path when the shortest name is not unique")
    func ambiguous() {
        let attachment = NotePath("Attachments/a b.png")
        let text = AttachmentUseCase.embedText(for: attachment, from: NotePath("Note.md"), existing: [attachment, NotePath("Other/a b.png")], settings: ObsidianAppSettings(newFileLocation: .root, newFileFolderPath: "", attachmentFolderPath: "/", useMarkdownLinks: true))
        #expect(text == "![](Attachments/a%20b.png)")
    }
}
