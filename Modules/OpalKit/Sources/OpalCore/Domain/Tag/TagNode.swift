//
//  TagNode.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct TagNode: Hashable, Sendable, Identifiable {
    // MARK: - Stored

    public let name: String
    public let fullName: String
    public let noteCount: Int
    public let children: [TagNode]?

    // MARK: - Init

    public init(name: String, fullName: String, noteCount: Int, children: [TagNode]?) {
        self.name = name
        self.fullName = fullName
        self.noteCount = noteCount
        self.children = children
    }

    // MARK: - Identifiable

    public var id: String {
        fullName.lowercased()
    }
}
