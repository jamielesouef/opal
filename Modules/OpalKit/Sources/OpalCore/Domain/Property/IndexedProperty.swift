//
//  IndexedProperty.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

public struct IndexedProperty: Hashable, Sendable {
    // MARK: - Stored

    public let name: String
    public let type: PropertyType
    public let items: [String]

    // MARK: - Init

    public init(name: String, type: PropertyType, items: [String]) {
        self.name = name
        self.type = type
        self.items = items
    }
}
