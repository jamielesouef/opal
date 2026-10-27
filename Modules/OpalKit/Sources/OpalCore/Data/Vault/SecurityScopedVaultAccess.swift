//
//  SecurityScopedVaultAccess.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

public final class SecurityScopedVaultAccess: VaultAccessGranting {
    // MARK: - Init

    public init() {}

    // MARK: - VaultAccessGranting

    public func bookmark(for folderURL: URL) throws(VaultError) -> Data {
        do {
            return try folderURL.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        } catch {
            throw .accessDenied
        }
    }

    public func resolve(bookmark: Data) throws(VaultError) -> ResolvedVaultBookmark {
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: bookmark,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            return ResolvedVaultBookmark(folderURL: url, isStale: isStale)
        } catch {
            throw .vaultMissing
        }
    }

    public func beginAccess(to folderURL: URL) -> Bool {
        folderURL.startAccessingSecurityScopedResource()
    }

    public func endAccess(to folderURL: URL) {
        folderURL.stopAccessingSecurityScopedResource()
    }

    public func createVaultFolder(at folderURL: URL) throws(VaultError) {
        do {
            try FileManager().createDirectory(at: folderURL, withIntermediateDirectories: true)
        } catch {
            throw .accessDenied
        }
    }
}
