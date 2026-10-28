//
//  DailyNotePlanUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation

public enum DailyNotePlanUseCase {
    // MARK: - Plan

    public static func path(on date: Date, timeZone: TimeZone, settings: DailyNoteSettings) -> NotePath? {
        let format = settings.format.trimmingCharacters(in: .whitespaces).isEmpty ? DailyNoteSettings.defaults.format : settings.format
        let name = MomentFormatUseCase.string(from: date, format: format, timeZone: timeZone)
        let folder = NotePath(settings.folder.trimmingCharacters(in: CharacterSet(charactersIn: "/ ")))
        let path = NotePath(components: folder.components + NotePath(name).components).appendingNoteExtension
        guard path.isWithinVault, path.isHidden == false, path.components.isEmpty == false else {
            return nil
        }

        return path
    }

    public static func templatePath(_ template: String) -> NotePath? {
        let trimmed = template.trimmingCharacters(in: CharacterSet(charactersIn: "/ "))
        guard trimmed.isEmpty == false else {
            return nil
        }

        let path = NotePath(trimmed)
        return path.isNote ? path : path.appendingNoteExtension
    }
}
