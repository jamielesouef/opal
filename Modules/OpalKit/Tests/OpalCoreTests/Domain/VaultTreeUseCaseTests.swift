//
//  VaultTreeUseCaseTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Testing
@testable import OpalCore

@Suite("VaultTreeUseCase", .tags(.domain))
struct VaultTreeUseCaseTests {
    // MARK: - Fixtures

    private static func folder(_ raw: String) -> VaultEntry {
        VaultEntry(path: NotePath(raw), isFolder: true)
    }

    private static func file(_ raw: String) -> VaultEntry {
        VaultEntry(path: NotePath(raw), isFolder: false)
    }

    // MARK: - Tests

    @Test("lists Folders first, then Notes and Attachments together in name order")
    func foldersFirst() {
        let tree = VaultTreeUseCase.tree(from: [
            Self.file("b.md"),
            Self.folder("Zeta"),
            Self.file("A.png"),
            Self.folder("alpha")
        ])

        #expect(tree.map(\.displayName) == ["alpha", "Zeta", "A.png", "b"])
    }

    @Test("orders numbers the way Finder does")
    func numericOrder() {
        let tree = VaultTreeUseCase.tree(from: [Self.file("Note 10.md"), Self.file("Note 2.md"), Self.file("Note 1.md")])

        #expect(tree.map(\.displayName) == ["Note 1", "Note 2", "Note 10"])
    }

    @Test("nests entries under their Folder and gives files no children")
    func nesting() {
        let tree = VaultTreeUseCase.tree(from: [
            Self.folder("Projects"),
            Self.folder("Projects/Opal"),
            Self.file("Projects/Opal/Opal Roadmap.md")
        ])

        let roadmap = tree.first?.children?.first?.children?.first
        #expect(roadmap?.displayName == "Opal Roadmap")
        #expect(roadmap?.kind == .note)
        #expect(roadmap?.children == nil)
    }

    @Test("hides dot Folders and everything inside them")
    func hidesHidden() {
        let tree = VaultTreeUseCase.tree(from: [
            Self.folder(".obsidian"),
            Self.file(".obsidian/app.json"),
            Self.file(".DS_Store"),
            Self.file("Soil.md")
        ])

        #expect(tree.map(\.displayName) == ["Soil"])
    }

    @Test("orders Notes by name, so Untitled comes before Untitled 1")
    func displayNameOrder() {
        let tree = VaultTreeUseCase.tree(from: [Self.file("Untitled 1.md"), Self.file("Untitled.md")])

        #expect(tree.map(\.displayName) == ["Untitled", "Untitled 1"])
    }

    @Test("an empty Vault has an empty tree")
    func empty() {
        #expect(VaultTreeUseCase.tree(from: []).isEmpty)
    }

    @Test("adding an entry also adds its missing ancestor Folders, once")
    func addsAncestors() {
        let entries = VaultTreeUseCase.entriesAddingAncestors(
            of: Self.file("Inbox/Later/Untitled.md"),
            to: [Self.folder("Inbox")]
        )

        #expect(Set(entries) == [Self.folder("Inbox"), Self.folder("Inbox/Later"), Self.file("Inbox/Later/Untitled.md")])
    }
}
