//
//  NotePathTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Testing
@testable import OpalCore

@Suite("NotePath", .tags(.domain))
struct NotePathTests {
    @Test(
        "names a Note by its file name without .md and anything else by its file name",
        arguments: [
            ("Soil.md", "Soil", true),
            ("Reading/The Soil Book.md", "The Soil Book", true),
            ("Notes/Upper.MD", "Upper", true),
            ("Attachments/seedlings.png", "seedlings.png", false),
            ("Projects", "Projects", false),
            ("Folder.v2/notes", "notes", false)
        ]
    )
    func naming(raw: String, name: String, isNote: Bool) {
        let path = NotePath(raw)

        #expect(path.name == name)
        #expect(path.isNote == isNote)
    }

    @Test("ignores empty components, so leading, trailing and doubled slashes mean the same path")
    func normalisesSlashes() {
        #expect(NotePath("/Projects//Opal/") == NotePath("Projects/Opal"))
    }

    @Test("treats any dot-prefixed component as hidden")
    func hidden() {
        #expect(NotePath(".obsidian/app.json").isHidden)
        #expect(NotePath("Notes/.git/HEAD").isHidden)
        #expect(NotePath("Notes/a.md").isHidden == false)
    }

    @Test("refuses components that would leave the Vault", arguments: ["../outside.md", "Notes/../../x.md", "./a.md"])
    func outsideVault(raw: String) {
        #expect(NotePath(raw).isWithinVault == false)
    }

    @Test("a file at the Vault root has the root as its parent")
    func rootParent() {
        #expect(NotePath("Soil.md").parent == .root)
        #expect(NotePath("Daily Notes/2026-10-27.md").parent == NotePath("Daily Notes"))
    }

    @Test("lists the Folders that contain a path, outermost first")
    func ancestors() {
        #expect(NotePath("Projects/Opal/Opal Roadmap.md").ancestors == [NotePath("Projects"), NotePath("Projects/Opal")])
        #expect(NotePath("Soil.md").ancestors.isEmpty)
    }

    @Test("a dot file has no extension")
    func dotFileExtension() {
        #expect(NotePath(".md").fileExtension == "")
        #expect(NotePath(".md").isNote == false)
    }
}
