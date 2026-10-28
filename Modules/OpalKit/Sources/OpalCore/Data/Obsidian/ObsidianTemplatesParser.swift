//
//  ObsidianTemplatesParser.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation

public enum ObsidianTemplatesParser {
    // MARK: - Constants

    public static let fileName = "templates.json"

    // MARK: - Parse

    public static func parse(_ data: Data?) -> TemplateSettings? {
        guard let data, let dto = try? JSONDecoder().decode(ObsidianTemplatesDTO.self, from: data) else {
            return nil
        }

        let defaults = TemplateSettings.defaults
        return TemplateSettings(
            folder: dto.folder ?? defaults.folder,
            dateFormat: dto.dateFormat.flatMap { $0.isEmpty ? nil : $0 } ?? defaults.dateFormat,
            timeFormat: dto.timeFormat.flatMap { $0.isEmpty ? nil : $0 } ?? defaults.timeFormat
        )
    }
}
