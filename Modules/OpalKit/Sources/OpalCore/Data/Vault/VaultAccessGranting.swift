//
//  VaultAccessGranting.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

public protocol VaultAccessGranting: Sendable {
    func bookmark(for folderURL: URL) throws(VaultError) -> Data
    func resolve(bookmark: Data) throws(VaultError) -> ResolvedVaultBookmark
    func beginAccess(to folderURL: URL) -> Bool
    func endAccess(to folderURL: URL)
    func createVaultFolder(at folderURL: URL) throws(VaultError)
}
