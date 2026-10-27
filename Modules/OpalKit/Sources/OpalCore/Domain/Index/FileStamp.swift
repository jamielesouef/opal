//
//  FileStamp.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

public struct FileStamp: Hashable, Sendable, Codable {
    // MARK: - Stored

    public let modified: Date
    public let size: Int

    // MARK: - Init

    public init(modified: Date, size: Int) {
        self.modified = modified
        self.size = size
    }
}
