//
//  SearchHit.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct SearchHit: Hashable, Sendable {
    // MARK: - Stored

    public let path: NotePath
    public let text: String

    // MARK: - Init

    public init(path: NotePath, text: String) {
        self.path = path
        self.text = text
    }
}
