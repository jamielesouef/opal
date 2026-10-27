//
//  LinkQuery.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct LinkQuery: Hashable, Sendable {
    // MARK: - Stored

    public let bracketLocation: Int
    public let queryLocation: Int
    public let text: String

    // MARK: - Init

    public init(bracketLocation: Int, queryLocation: Int, text: String) {
        self.bracketLocation = bracketLocation
        self.queryLocation = queryLocation
        self.text = text
    }

    // MARK: - Derived

    public var queryLength: Int {
        text.utf16.count
    }
}
