//
//  NewItemPlanUseCaseTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Testing
@testable import OpalCore

@Suite("NewItemPlanUseCase", .tags(.domain))
struct NewItemPlanUseCaseTests {
    // MARK: - Fixtures

    private static func settings(_ location: NewFileLocation, folder: String = "") -> ObsidianAppSettings {
        ObsidianAppSettings(newFileLocation: location, newFileFolderPath: folder, attachmentFolderPath: "/", useMarkdownLinks: false)
    }

    // MARK: - Where

    @Test("places a new Note where Obsidian's newFileLocation says")
    func location() {
        let open = NotePath("Projects/Opal/Opal Roadmap.md")

        #expect(NewItemPlanUseCase.folderForNewNote(settings: Self.settings(.root), openNote: open) == .root)
        #expect(NewItemPlanUseCase.folderForNewNote(settings: Self.settings(.current), openNote: open) == NotePath("Projects/Opal"))
        #expect(NewItemPlanUseCase.folderForNewNote(settings: Self.settings(.current), openNote: nil) == .root)
        #expect(NewItemPlanUseCase.folderForNewNote(settings: Self.settings(.folder, folder: "Inbox"), openNote: open) == NotePath("Inbox"))
    }

    @Test("falls back to the Vault root for a configured Folder outside the Vault or hidden", arguments: ["../Elsewhere", ".obsidian"])
    func unsafeFolder(folder: String) {
        #expect(NewItemPlanUseCase.folderForNewNote(settings: Self.settings(.folder, folder: folder), openNote: nil) == .root)
    }

    @Test("a new Folder goes inside a selected Folder, beside a selected file, or at the root")
    func containingFolder() {
        #expect(NewItemPlanUseCase.containingFolder(of: NotePath("Areas"), kind: .folder) == NotePath("Areas"))
        #expect(NewItemPlanUseCase.containingFolder(of: NotePath("Areas/Health.md"), kind: .note) == NotePath("Areas"))
        #expect(NewItemPlanUseCase.containingFolder(of: nil, kind: nil) == .root)
    }

    // MARK: - Name

    @Test("names a new Note Untitled, then Untitled 1, Untitled 2 when taken")
    func untitled() {
        let existing: Set = [NotePath("Inbox/Untitled.md"), NotePath("Inbox/Untitled 1.md")]

        #expect(NewItemPlanUseCase.newNotePath(in: NotePath("Inbox"), existing: []) == NotePath("Inbox/Untitled.md"))
        #expect(NewItemPlanUseCase.newNotePath(in: NotePath("Inbox"), existing: existing) == NotePath("Inbox/Untitled 2.md"))
    }

    @Test("treats names that differ only in case as taken, as the Mac file system does")
    func caseInsensitive() {
        #expect(NewItemPlanUseCase.newNotePath(in: .root, existing: [NotePath("untitled.md")]) == NotePath("Untitled 1.md"))
    }

    @Test("names a new Folder without an extension")
    func folderName() {
        #expect(NewItemPlanUseCase.newFolderPath(in: .root, existing: [NotePath("Untitled")]) == NotePath("Untitled 1"))
    }
}
