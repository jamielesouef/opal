//
//  RevealRequest.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct RevealRequest: Hashable, Sendable {
    // MARK: - Stored

    public let path: NotePath
    public let line: Int
    public let id: Int

    // MARK: - Init

    public init(path: NotePath, line: Int, id: Int) {
        self.path = path
        self.line = line
        self.id = id
    }
}
