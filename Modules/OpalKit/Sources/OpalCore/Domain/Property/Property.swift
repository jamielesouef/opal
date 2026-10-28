//
//  Property.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

public struct Property: Hashable, Sendable, Identifiable {
    // MARK: - Stored

    public let key: String
    public let value: PropertyValue
    public let lines: Range<Int>

    // MARK: - Init

    public init(key: String, value: PropertyValue, lines: Range<Int>) {
        self.key = key
        self.value = value
        self.lines = lines
    }

    // MARK: - Identifiable

    public var id: String {
        key
    }
}
