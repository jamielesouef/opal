//
//  ObsidianDailyNotesParser.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation

public enum ObsidianDailyNotesParser {
    // MARK: - Constants

    public static let fileName = "daily-notes.json"

    // MARK: - Parse

    public static func parse(_ data: Data?) -> DailyNoteSettings? {
        guard let data, let dto = try? JSONDecoder().decode(ObsidianDailyNotesDTO.self, from: data) else {
            return nil
        }

        let defaults = DailyNoteSettings.defaults
        return DailyNoteSettings(
            folder: dto.folder ?? defaults.folder,
            format: dto.format.flatMap { $0.isEmpty ? nil : $0 } ?? defaults.format,
            template: dto.template ?? defaults.template
        )
    }
}
