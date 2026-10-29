//
//  RecentVaultRecord.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation

public struct RecentVaultRecord: Hashable, Codable, Sendable {
    // MARK: - Stored

    public var bookmark: Data
    public var path: String

    // MARK: - Init

    public init(bookmark: Data, path: String) {
        self.bookmark = bookmark
        self.path = path
    }
}
