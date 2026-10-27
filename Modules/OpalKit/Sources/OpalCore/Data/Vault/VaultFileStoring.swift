//
//  VaultFileStoring.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

public protocol VaultFileStoring: Sendable {
    var rootURL: URL { get }

    func listEntries() async throws(VaultError) -> [VaultEntry]
    func readNote(at path: NotePath) async throws(VaultError) -> String?
    func writeNote(_ text: String, at path: NotePath) async throws(VaultError)
    func createNote(at path: NotePath, text: String) async throws(VaultError)
    func createFolder(at path: NotePath) async throws(VaultError)
    func readObsidianSettings(named fileName: String) async -> Data?
    func url(for path: NotePath) -> URL
}
