//
//  VaultError+Message.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore

extension VaultError {
    // MARK: - Message

    var message: String {
        switch self {
        case .folderUnreadable:
            String(localized: "Opal can’t read this folder. Check that it exists and that you have access to it.")
        case .accessDenied:
            String(localized: "Opal doesn’t have permission to use this folder. Choose it again to give access.")
        case .vaultMissing:
            String(localized: "The Vault you used last can’t be found. It may have been moved or deleted.")
        case .noVaultOpen:
            String(localized: "No Vault is open.")
        case .outsideVault:
            String(localized: "This file is outside the Vault, so Opal won’t open it.")
        case let .notFound(path):
            String(localized: "“\(path.name)” no longer exists.")
        case let .unreadable(path):
            String(localized: "Opal can’t read “\(path.name)”.")
        case let .notUTF8(path):
            String(localized: "“\(path.name)” isn’t UTF-8 text, so Opal won’t open it to avoid changing it.")
        case let .writeFailed(path):
            String(localized: "Opal couldn’t save “\(path.name)”. Your edits are still here.")
        case let .alreadyExists(path):
            String(localized: "“\(path.fileName)” already exists.")
        }
    }
}
