//
//  PropertyValue.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

public enum PropertyValue: Hashable, Sendable {
    case text(String)
    case list([String])
    case unreadable(String)

    // MARK: - Derived

    public var items: [String] {
        switch self {
        case let .text(value):
            value.isEmpty ? [] : [value]
        case let .list(values):
            values
        case .unreadable:
            []
        }
    }
}
