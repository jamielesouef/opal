//
//  ResolvedVaultBookmark.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

public struct ResolvedVaultBookmark: Hashable, Sendable {
    // MARK: - Stored

    public let folderURL: URL
    public let isStale: Bool

    // MARK: - Init

    public init(folderURL: URL, isStale: Bool) {
        self.folderURL = folderURL
        self.isStale = isStale
    }
}
