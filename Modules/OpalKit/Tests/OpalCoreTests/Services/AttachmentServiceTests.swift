//
//  AttachmentServiceTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("Attachments", .tags(.service))
@MainActor
struct AttachmentServiceTests {
    @Test("a pasted image is saved next to the others and never replaces a file")
    func paste() async throws {
        let vault = try FixtureVault()
        defer { vault.remove() }
        let folder = vault.url(".obsidian")
        try Data(#"{"attachmentFolderPath":"Attachments"}"#.utf8).write(to: folder.appending(path: "app.json"))
        let harness = ServiceHarness(store: FileSystemVaultStore(rootURL: vault.rootURL))
        await harness.openVault()
        await harness.navigation.open(NotePath("Welcome.md"))
        let original = try Data(contentsOf: vault.url("Attachments/seedlings.png"))

        let pasted = await harness.notes.attach(Data([1, 2, 3]), named: nil)
        let dropped = await harness.notes.attach(Data([4, 5]), named: "seedlings.png")

        #expect(pasted == "![[Pasted image 20261026183320.png]]")
        #expect(try Data(contentsOf: vault.url("Attachments/Pasted image 20261026183320.png")) == Data([1, 2, 3]))
        #expect(dropped == "![[seedlings 1.png]]")
        #expect(try Data(contentsOf: vault.url("Attachments/seedlings.png")) == original)
        #expect(harness.vault.kind(of: NotePath("Attachments/seedlings 1.png")) == .attachment)
    }
}
