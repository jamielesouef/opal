//
//  OpalSettings.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

public struct OpalSettings: Hashable, Sendable, Codable {
    // MARK: - Defaults

    public static let defaults = OpalSettings()

    // MARK: - Stored

    public var newFileLocation = ObsidianAppSettings.defaults.newFileLocation
    public var newFileFolderPath = ObsidianAppSettings.defaults.newFileFolderPath
    public var attachmentFolderPath = ObsidianAppSettings.defaults.attachmentFolderPath
    public var useMarkdownLinks = ObsidianAppSettings.defaults.useMarkdownLinks
    public var linkUpdate = LinkUpdate.ask
    public var dailyFolder = DailyNoteSettings.defaults.folder
    public var dailyFormat = DailyNoteSettings.defaults.format
    public var dailyTemplate = DailyNoteSettings.defaults.template

    // MARK: - Init

    public init() {}

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Self.defaults
        newFileLocation = try container.decodeIfPresent(NewFileLocation.self, forKey: .newFileLocation) ?? defaults.newFileLocation
        newFileFolderPath = try container.decodeIfPresent(String.self, forKey: .newFileFolderPath) ?? defaults.newFileFolderPath
        attachmentFolderPath = try container.decodeIfPresent(String.self, forKey: .attachmentFolderPath) ?? defaults.attachmentFolderPath
        useMarkdownLinks = try container.decodeIfPresent(Bool.self, forKey: .useMarkdownLinks) ?? defaults.useMarkdownLinks
        linkUpdate = try container.decodeIfPresent(LinkUpdate.self, forKey: .linkUpdate) ?? defaults.linkUpdate
        dailyFolder = try container.decodeIfPresent(String.self, forKey: .dailyFolder) ?? defaults.dailyFolder
        dailyFormat = try container.decodeIfPresent(String.self, forKey: .dailyFormat) ?? defaults.dailyFormat
        dailyTemplate = try container.decodeIfPresent(String.self, forKey: .dailyTemplate) ?? defaults.dailyTemplate
    }
}
