//
//  WaitingVault.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation

public struct WaitingVault: Hashable, Sendable {
    // MARK: - Stored

    public let folderURL: URL
    public let isNew: Bool

    // MARK: - Init

    public init(folderURL: URL, isNew: Bool) {
        self.folderURL = folderURL
        self.isNew = isNew
    }
}
