//
//  ObsidianVaultSettingsParser.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation

public enum ObsidianVaultSettingsParser {
    // MARK: - Parse

    public static func parse(app: Data?, dailyNotes: Data?) -> VaultSettings {
        var settings = app.flatMap { try? JSONDecoder().decode(ObsidianAppSettingsDTO.self, from: $0) }?.toVaultSettings() ?? VaultSettings()
        if let daily = dailyNotes.flatMap({ try? JSONDecoder().decode(ObsidianDailyNotesDTO.self, from: $0) }) {
            settings.dailyFolder = daily.folder
            settings.dailyFormat = daily.format.flatMap { $0.isEmpty ? nil : $0 }
            settings.dailyTemplate = daily.template
        }
        return settings
    }
}
