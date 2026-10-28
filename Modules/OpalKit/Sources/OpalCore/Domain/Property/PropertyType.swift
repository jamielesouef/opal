//
//  PropertyType.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

public enum PropertyType: String, Hashable, Sendable, CaseIterable {
    case text
    case list = "multitext"
    case number
    case checkbox
    case date
    case dateTime = "datetime"
    case tags
    case aliases
}
