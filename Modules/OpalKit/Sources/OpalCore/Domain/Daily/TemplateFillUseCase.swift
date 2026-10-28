//
//  TemplateFillUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation

public enum TemplateFillUseCase {
    // MARK: - Constants

    public static let defaultDateFormat = "YYYY-MM-DD"
    public static let defaultTimeFormat = "HH:mm"

    // MARK: - Fill

    public static func fill(
        _ template: String,
        title: String,
        date: Date,
        timeZone: TimeZone,
        dateFormat: String = defaultDateFormat,
        timeFormat: String = defaultTimeFormat
    ) -> String {
        template.replacing(/\{\{\s*(date|time|title)\s*(?::([^}]*))?\}\}/.ignoresCase()) { match in
            let format = match.2.map { String($0).trimmingCharacters(in: .whitespaces) }
            switch match.1.lowercased() {
            case "title":
                return title
            case "time":
                return MomentFormatUseCase.string(from: date, format: format ?? timeFormat, timeZone: timeZone)
            default:
                return MomentFormatUseCase.string(from: date, format: format ?? dateFormat, timeZone: timeZone)
            }
        }
    }
}
