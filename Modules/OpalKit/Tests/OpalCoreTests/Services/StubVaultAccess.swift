//
//  StubVaultAccess.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
@testable import OpalCore

struct StubVaultAccess: VaultAccessGranting {
    // MARK: - Stored

    let resolvesBookmarks: Bool
    let resolvesStale: Bool

    // MARK: - Init

    init(resolvesBookmarks: Bool = true, resolvesStale: Bool = false) {
        self.resolvesBookmarks = resolvesBookmarks
        self.resolvesStale = resolvesStale
    }

    // MARK: - VaultAccessGranting

    func bookmark(for folderURL: URL) throws(VaultError) -> Data {
        Data(folderURL.path.utf8)
    }

    func resolve(bookmark: Data) throws(VaultError) -> ResolvedVaultBookmark {
        guard resolvesBookmarks else {
            throw .vaultMissing
        }

        return ResolvedVaultBookmark(folderURL: URL(filePath: String(decoding: bookmark, as: UTF8.self)), isStale: resolvesStale)
    }

    func beginAccess(to folderURL: URL) -> Bool {
        true
    }

    func endAccess(to folderURL: URL) {}

    func createVaultFolder(at folderURL: URL) throws(VaultError) {}
}
