//
//  TextInsertion.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

public struct TextInsertion: Hashable, Sendable {
    // MARK: - Stored

    public let path: NotePath
    public let text: String
    public let id: Int

    // MARK: - Init

    public init(path: NotePath, text: String, id: Int) {
        self.path = path
        self.text = text
        self.id = id
    }
}
