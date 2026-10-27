//
//  Block.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct Block: Hashable, Sendable {
    // MARK: - Stored

    public let id: String
    public let line: Int

    // MARK: - Init

    public init(id: String, line: Int) {
        self.id = id
        self.line = line
    }
}
