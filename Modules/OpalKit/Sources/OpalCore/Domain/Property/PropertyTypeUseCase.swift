//
//  PropertyTypeUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation

public enum PropertyTypeUseCase {
    // MARK: - Type

    public static func type(of property: Property, declared: [String: PropertyType]) -> PropertyType {
        if let type = declared[property.key] {
            return type
        }

        switch property.key.lowercased() {
        case "tags", "tag":
            return .tags
        case "aliases", "alias":
            return .aliases
        default:
            break
        }

        switch property.value {
        case .list:
            return .list
        case .unreadable:
            return .text
        case let .text(value):
            return inferred(value)
        }
    }

    // MARK: - Private

    private static func inferred(_ value: String) -> PropertyType {
        let lowered = value.lowercased()
        if lowered == "true" || lowered == "false" {
            return .checkbox
        }
        if Double(value) != nil {
            return .number
        }
        if value.wholeMatch(of: /\d{4}-\d{2}-\d{2}/) != nil {
            return .date
        }
        if value.wholeMatch(of: /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2})?/) != nil {
            return .dateTime
        }
        return .text
    }
}
