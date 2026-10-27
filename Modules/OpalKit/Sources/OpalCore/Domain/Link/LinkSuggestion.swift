//
//  LinkSuggestion.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public enum LinkSuggestion: Hashable, Sendable {
    case note(NotePath, alias: String?)
    case unresolved(String)

    // MARK: - Derived

    public var name: String {
        switch self {
        case let .note(path, alias):
            alias ?? path.name
        case let .unresolved(name):
            name
        }
    }
}
