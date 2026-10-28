//
//  CountingVaultStore.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
@testable import OpalCore

actor CountingVaultStore: VaultFileStoring {
    // MARK: - Stored

    nonisolated let rootURL: URL

    private let base: FileSystemVaultStore
    private(set) var reads = 0

    // MARK: - Init

    init(rootURL: URL) {
        base = FileSystemVaultStore(rootURL: rootURL)
        self.rootURL = base.rootURL
    }

    // MARK: - VaultFileStoring

    func listEntries() async throws(VaultError) -> [VaultEntry] {
        try await base.listEntries()
    }

    func readNote(at path: NotePath) async throws(VaultError) -> String? {
        reads += 1
        return try await base.readNote(at: path)
    }

    func noteStamps() async throws(VaultError) -> [NotePath: FileStamp] {
        try await base.noteStamps()
    }

    func stamp(of path: NotePath) async -> FileStamp? {
        await base.stamp(of: path)
    }

    func writeNote(_ text: String, at path: NotePath) async throws(VaultError) {
        try await base.writeNote(text, at: path)
    }

    func createNote(at path: NotePath, text: String) async throws(VaultError) {
        try await base.createNote(at: path, text: text)
    }

    func createFile(at path: NotePath, data: Data) async throws(VaultError) {
        try await base.createFile(at: path, data: data)
    }

    func moveItem(from source: NotePath, to destination: NotePath) async throws(VaultError) {
        try await base.moveItem(from: source, to: destination)
    }

    func createFolder(at path: NotePath) async throws(VaultError) {
        try await base.createFolder(at: path)
    }

    func readObsidianSettings(named fileName: String) async -> Data? {
        await base.readObsidianSettings(named: fileName)
    }

    nonisolated func url(for path: NotePath) -> URL {
        base.url(for: path)
    }

    // MARK: - Test configuration

    func resetReads() {
        reads = 0
    }
}
