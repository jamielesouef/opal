//
//  DailyNoteSettings.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

public struct DailyNoteSettings: Hashable, Sendable {
    // MARK: - Constants

    public static let defaults = DailyNoteSettings(folder: "", format: "YYYY-MM-DD", template: "")

    // MARK: - Stored

    public let folder: String
    public let format: String
    public let template: String

    // MARK: - Init

    public init(folder: String, format: String, template: String) {
        self.folder = folder
        self.format = format
        self.template = template
    }
}
