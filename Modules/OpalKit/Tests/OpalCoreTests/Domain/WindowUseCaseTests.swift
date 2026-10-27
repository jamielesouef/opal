//
//  WindowUseCaseTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Testing
@testable import OpalCore

@Suite("Window use cases", .tags(.domain))
struct WindowUseCaseTests {
    @Test("shows an Attachment's panel only when an Attachment is selected")
    func detailContent() {
        let image = NotePath("Attachments/seedlings.png")

        #expect(DetailContentUseCase.content(selection: image, kind: .attachment) == .attachment(image))
        #expect(DetailContentUseCase.content(selection: NotePath("Soil.md"), kind: .note) == .note)
        #expect(DetailContentUseCase.content(selection: NotePath("Areas"), kind: .folder) == .note)
        #expect(DetailContentUseCase.content(selection: nil, kind: nil) == .note)
    }

    @Test("titles the window with the open Note, and its subtitle with the Vault and Folder")
    func title() {
        let note = NotePath("Projects/Opal/Opal Roadmap.md")

        #expect(WindowTitleUseCase.title(vaultName: "Garden", openNote: note) == "Opal Roadmap")
        #expect(WindowTitleUseCase.subtitle(vaultName: "Garden", openNote: note) == "Garden/Projects/Opal")
        #expect(WindowTitleUseCase.subtitle(vaultName: "Garden", openNote: NotePath("Soil.md")) == "Garden")
        #expect(WindowTitleUseCase.title(vaultName: "Garden", openNote: nil) == "Garden")
        #expect(WindowTitleUseCase.subtitle(vaultName: "Garden", openNote: nil) == "")
    }
}
