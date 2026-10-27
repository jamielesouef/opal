//
//  VaultError.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public enum VaultError: Error, Hashable, Sendable {
    case folderUnreadable
    case accessDenied
    case vaultMissing
    case noVaultOpen
    case outsideVault
    case notFound(NotePath)
    case unreadable(NotePath)
    case notUTF8(NotePath)
    case writeFailed(NotePath)
    case alreadyExists(NotePath)
}
