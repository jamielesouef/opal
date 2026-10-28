//
//  ObsidianTypesParser.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation

public enum ObsidianTypesParser {
    // MARK: - Constants

    public static let fileName = "types.json"

    // MARK: - Parse

    public static func parse(_ data: Data?) -> [String: PropertyType] {
        guard let data, let dto = try? JSONDecoder().decode(ObsidianTypesDTO.self, from: data) else {
            return [:]
        }

        return dto.types.compactMapValues(PropertyType.init(rawValue:))
    }
}
