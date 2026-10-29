//
//  PropertyIndexUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

public enum PropertyIndexUseCase {
    // MARK: - Properties

    public static func properties(in text: String) -> [IndexedProperty] {
        guard let frontmatter = FrontmatterParser.parse(text) else {
            return []
        }

        return frontmatter.properties.map { property in
            IndexedProperty(
                name: property.key,
                type: PropertyTypeUseCase.type(of: property, declared: [:]),
                items: property.value.items
            )
        }
    }

    // MARK: - Vault types

    public static func resolvedTypes(
        counts: [String: [PropertyType: Int]],
        declared: [String: PropertyType]
    ) -> [String: PropertyType] {
        var types: [String: PropertyType] = [:]
        for (name, byType) in counts {
            if let type = declared[name] {
                types[name] = type
            } else if let common = mostCommon(byType) {
                types[name] = common
            }
        }
        return types
    }

    // MARK: - Private

    private static func mostCommon(_ counts: [PropertyType: Int]) -> PropertyType? {
        PropertyType.allCases
            .filter { counts[$0, default: 0] > 0 }
            .max { counts[$0, default: 0] < counts[$1, default: 0] }
    }
}
