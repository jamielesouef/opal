//
//  ObsidianAppSettingsParser.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

public enum ObsidianAppSettingsParser {
    // MARK: - Constants

    public static let fileName = "app.json"

    // MARK: - Parse

    public static func parse(_ data: Data?) -> ObsidianAppSettings {
        guard let data, let dto = try? JSONDecoder().decode(ObsidianAppSettingsDTO.self, from: data) else {
            return .defaults
        }

        return dto.toDomain()
    }
}
