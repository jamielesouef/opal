//
//  MockVaultFileStore.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

#if DEBUG
    import Foundation
    import OpalCore

    actor MockVaultFileStore: VaultFileStoring {
        // MARK: - Stored

        nonisolated let rootURL: URL

        private var files: [NotePath: String]
        private var folders: Set<NotePath>

        // MARK: - Init

        init(rootURL: URL = URL(filePath: "/Preview/Garden"), files: [String: String], folders: [String]) {
            self.rootURL = rootURL
            self.files = Dictionary(uniqueKeysWithValues: files.map { (NotePath($0.key), $0.value) })
            self.folders = Set(folders.map(NotePath.init))
        }

        // MARK: - VaultFileStoring

        func listEntries() throws(VaultError) -> [VaultEntry] {
            folders.map { VaultEntry(path: $0, kind: .folder) } + files.keys.map { VaultEntry(path: $0, isFolder: false) }
        }

        func noteStamps() throws(VaultError) -> [NotePath: FileStamp] {
            Dictionary(uniqueKeysWithValues: files.filter { $0.key.isNote }.map { ($0.key, Self.stamp(for: $0.value)) })
        }

        func stamp(of path: NotePath) -> FileStamp? {
            files[path].map(Self.stamp(for:))
        }

        private static func stamp(for text: String) -> FileStamp {
            FileStamp(modified: Date(timeIntervalSince1970: Double(text.hashValue & 0xFFFF)), size: text.utf8.count)
        }

        func readNote(at path: NotePath) throws(VaultError) -> String? {
            files[path]
        }

        func writeNote(_ text: String, at path: NotePath) throws(VaultError) {
            files[path] = text
        }

        func createNote(at path: NotePath, text: String) throws(VaultError) {
            files[path] = text
        }

        func createFolder(at path: NotePath) throws(VaultError) {
            folders.insert(path)
        }

        func readObsidianSettings(named fileName: String) -> Data? {
            nil
        }

        nonisolated func url(for path: NotePath) -> URL {
            rootURL.appending(path: path.rawValue)
        }
    }
#endif
