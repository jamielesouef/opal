//
//  FileSystemVaultStoreTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("FileSystemVaultStore", .tags(.data))
struct FileSystemVaultStoreTests {
    @Test("lists every Folder, Note and Attachment at any depth, skipping hidden items")
    func listsEntries() async throws {
        let fixture = try FixtureVault()
        defer { fixture.remove() }
        let store = FileSystemVaultStore(rootURL: fixture.rootURL)

        let entries = try await store.listEntries()

        let paths = Set(entries.map(\.path.rawValue))
        #expect(paths.contains("Projects/Opal/Opal Roadmap.md"))
        #expect(paths.contains("Attachments/seedlings.png"))
        #expect(paths.contains("Daily Notes"))
        #expect(paths.contains { $0.hasPrefix(".obsidian") } == false)
        #expect(entries.first { $0.path.rawValue == "Attachments/seedlings.png" }?.kind == .attachment)
        #expect(entries.first { $0.path.rawValue == "Daily Notes" }?.kind == .folder)
    }

    @Test("reads a Note's text exactly as it is on disk")
    func readsExactly() async throws {
        let fixture = try FixtureVault()
        defer { fixture.remove() }
        let original = "---\r\ntags: [a]\r\n---\r\n\u{FEFF}Body  \r\n"
        try fixture.write(original, to: "CRLF.md")
        let store = FileSystemVaultStore(rootURL: fixture.rootURL)

        let text = try await store.readNote(at: NotePath("CRLF.md"))

        #expect(text == original)
    }

    @Test("returns nil for a Note that does not exist")
    func missingNote() async throws {
        let fixture = try FixtureVault()
        defer { fixture.remove() }
        let store = FileSystemVaultStore(rootURL: fixture.rootURL)

        #expect(try await store.readNote(at: NotePath("Nope.md")) == nil)
    }

    @Test("refuses a file that is not UTF-8")
    func notUTF8() async throws {
        let fixture = try FixtureVault()
        defer { fixture.remove() }
        try Data([0xFF, 0xFE, 0xFD]).write(to: fixture.url("Binary.md"))
        let store = FileSystemVaultStore(rootURL: fixture.rootURL)

        await #expect(throws: VaultError.notUTF8(NotePath("Binary.md"))) {
            try await store.readNote(at: NotePath("Binary.md"))
        }
    }

    @Test("writes exactly the given text and round-trips it byte for byte")
    func writesExactly() async throws {
        let fixture = try FixtureVault()
        defer { fixture.remove() }
        let store = FileSystemVaultStore(rootURL: fixture.rootURL)
        let text = "# Soil\r\n\r\nTrailing   \n\tTabbed\n"

        try await store.writeNote(text, at: NotePath("Soil.md"))

        #expect(try Data(contentsOf: fixture.url("Soil.md")) == Data(text.utf8))
    }

    @Test("refuses paths that leave the Vault", arguments: ["../escape.md", "Notes/../../escape.md"])
    func refusesEscape(raw: String) async throws {
        let fixture = try FixtureVault()
        defer { fixture.remove() }
        let store = FileSystemVaultStore(rootURL: fixture.rootURL)

        await #expect(throws: VaultError.outsideVault) {
            try await store.writeNote("x", at: NotePath(raw))
        }
        #expect(FileManager().fileExists(atPath: fixture.containerURL.appending(component: "escape.md").path) == false)
    }

    @Test("creating a Note that exists fails and leaves the file alone")
    func createExisting() async throws {
        let fixture = try FixtureVault()
        defer { fixture.remove() }
        let store = FileSystemVaultStore(rootURL: fixture.rootURL)
        let before = try fixture.text("Soil.md")

        await #expect(throws: VaultError.alreadyExists(NotePath("Soil.md"))) {
            try await store.createNote(at: NotePath("Soil.md"), text: "")
        }
        #expect(try fixture.text("Soil.md") == before)
    }

    @Test("creates a Note and its missing Folders")
    func createsWithFolders() async throws {
        let fixture = try FixtureVault()
        defer { fixture.remove() }
        let store = FileSystemVaultStore(rootURL: fixture.rootURL)

        try await store.createNote(at: NotePath("Inbox/Untitled.md"), text: "")

        #expect(try fixture.text("Inbox/Untitled.md") == "")
    }

    @Test("reads Obsidian's settings without writing to .obsidian")
    func readsObsidianSettings() async throws {
        let fixture = try FixtureVault()
        defer { fixture.remove() }
        let store = FileSystemVaultStore(rootURL: fixture.rootURL)
        let before = try FileManager().contentsOfDirectory(atPath: fixture.url(".obsidian").path).sorted()

        let data = await store.readObsidianSettings(named: "app.json")

        #expect(ObsidianAppSettingsParser.parse(data).newFileFolderPath == "Inbox")
        #expect(await store.readObsidianSettings(named: "../Soil.md") == nil)
        #expect(try FileManager().contentsOfDirectory(atPath: fixture.url(".obsidian").path).sorted() == before)
    }

    @Test("does not follow a symbolic link out of the Vault")
    func skipsSymlinks() async throws {
        let fixture = try FixtureVault()
        defer { fixture.remove() }
        let outside = fixture.containerURL.appending(component: "Outside.md")
        try Data("secret".utf8).write(to: outside)
        try FileManager().createSymbolicLink(at: fixture.url("Link.md"), withDestinationURL: outside)
        let store = FileSystemVaultStore(rootURL: fixture.rootURL)

        let entries = try await store.listEntries()

        #expect(entries.contains { $0.path.rawValue == "Link.md" } == false)
        await #expect(throws: VaultError.outsideVault) {
            try await store.readNote(at: NotePath("Link.md"))
        }
    }

    @Test("keeps walking past a hidden file that sits beside a Folder")
    func walksPastHiddenFile() async throws {
        let fixture = try FixtureVault()
        defer { fixture.remove() }
        for folder in ["daily/2026/01-Jan", "daily/2026/10-Oct"] {
            try FileManager().createDirectory(at: fixture.url(folder), withIntermediateDirectories: true)
        }
        try fixture.write("", to: "daily/.gitkeep")
        try fixture.write("# Day", to: "daily/2026/01-Jan/26-01-1.md")
        try fixture.write("# Day", to: "daily/2026/10-Oct/26-10-1.md")
        try fixture.write("# Day", to: "daily/2026/26-07-27.md")
        let store = FileSystemVaultStore(rootURL: fixture.rootURL)

        let paths = try await Set(store.listEntries().map(\.path.rawValue))

        #expect(paths.isSuperset(of: ["daily/2026", "daily/2026/01-Jan", "daily/2026/10-Oct", "daily/2026/10-Oct/26-10-1.md", "daily/2026/26-07-27.md"]))
        #expect(paths.contains("daily/.gitkeep") == false)
    }

    @Test("lists nested Folders when the Vault root is a symbolic link")
    func listsThroughSymlinkedRoot() async throws {
        let container = FileManager().temporaryDirectory.appending(component: "Opal-Link-\(UUID().uuidString)")
        defer { try? FileManager().removeItem(at: container) }
        let real = container.appending(component: "Drive/obsidian")
        let months = ["01-Jan", "02-Feb", "10-Oct"]
        for month in months {
            let folder = real.appending(component: "daily/2026/\(month)")
            try FileManager().createDirectory(at: folder, withIntermediateDirectories: true)
            try Data("# Day".utf8).write(to: folder.appending(component: "26-01-1.md"))
        }
        try Data("# Day".utf8).write(to: real.appending(component: "daily/2026/26-07-27.md"))
        try Data().write(to: real.appending(component: "daily/.gitkeep"))
        let link = container.appending(component: "obsidian")
        try FileManager().createSymbolicLink(at: link, withDestinationURL: real)
        let store = FileSystemVaultStore(rootURL: link)

        let paths = try await Set(store.listEntries().map(\.path.rawValue))

        #expect(paths.isSuperset(of: ["daily", "daily/2026", "daily/2026/01-Jan", "daily/2026/10-Oct", "daily/2026/10-Oct/26-01-1.md", "daily/2026/26-07-27.md"]))
    }

    @Test("reports a missing Vault folder as unreadable")
    func missingRoot() async {
        let store = FileSystemVaultStore(rootURL: FileManager().temporaryDirectory.appending(component: "Missing-\(UUID().uuidString)"))

        await #expect(throws: VaultError.folderUnreadable) {
            try await store.listEntries()
        }
    }
}
