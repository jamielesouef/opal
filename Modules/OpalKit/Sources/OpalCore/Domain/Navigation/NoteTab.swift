//
//  NoteTab.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

public struct NoteTab: Hashable, Sendable, Identifiable {
    // MARK: - Stored

    public let id: Int
    public var path: NotePath?
    public var history = NavigationHistory()
    public var topOffset = 0

    // MARK: - Init

    public init(id: Int, path: NotePath?) {
        self.id = id
        self.path = path
    }
}
