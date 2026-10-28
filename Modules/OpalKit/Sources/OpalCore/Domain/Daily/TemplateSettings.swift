//
//  TemplateSettings.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

public struct TemplateSettings: Hashable, Sendable {
    // MARK: - Constants

    public static let defaults = TemplateSettings(folder: "", dateFormat: TemplateFillUseCase.defaultDateFormat, timeFormat: TemplateFillUseCase.defaultTimeFormat)

    // MARK: - Stored

    public let folder: String
    public let dateFormat: String
    public let timeFormat: String

    // MARK: - Init

    public init(folder: String, dateFormat: String, timeFormat: String) {
        self.folder = folder
        self.dateFormat = dateFormat
        self.timeFormat = timeFormat
    }

    // MARK: - Derived

    public var folderPath: NotePath? {
        let trimmed = folder.trimmingCharacters(in: .init(charactersIn: "/ "))
        return trimmed.isEmpty ? nil : NotePath(trimmed)
    }
}
