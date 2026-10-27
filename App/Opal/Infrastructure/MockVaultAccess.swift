//
//  MockVaultAccess.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

#if DEBUG
    import Foundation
    import OpalCore

    struct MockVaultAccess: VaultAccessGranting {
        // MARK: - VaultAccessGranting

        func bookmark(for folderURL: URL) throws(VaultError) -> Data {
            Data(folderURL.path.utf8)
        }

        func resolve(bookmark: Data) throws(VaultError) -> ResolvedVaultBookmark {
            ResolvedVaultBookmark(folderURL: URL(filePath: String(decoding: bookmark, as: UTF8.self)), isStale: false)
        }

        func beginAccess(to folderURL: URL) -> Bool {
            false
        }

        func endAccess(to folderURL: URL) {}

        func createVaultFolder(at folderURL: URL) throws(VaultError) {}
    }
#endif
