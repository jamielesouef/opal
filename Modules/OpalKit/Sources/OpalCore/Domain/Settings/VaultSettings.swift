//
//  VaultSettings.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

public struct VaultSettings: Hashable, Sendable {
    // MARK: - Stored

    public var newFileLocation: NewFileLocation?
    public var newFileFolderPath: String?
    public var attachmentFolderPath: String?
    public var useMarkdownLinks: Bool?
    public var newLinkFormat: LinkFormat?
    public var alwaysUpdateLinks: Bool?
    public var dailyFolder: String?
    public var dailyFormat: String?
    public var dailyTemplate: String?

    // MARK: - Init

    public init(
        newFileLocation: NewFileLocation? = nil,
        newFileFolderPath: String? = nil,
        attachmentFolderPath: String? = nil,
        useMarkdownLinks: Bool? = nil,
        newLinkFormat: LinkFormat? = nil,
        alwaysUpdateLinks: Bool? = nil,
        dailyFolder: String? = nil,
        dailyFormat: String? = nil,
        dailyTemplate: String? = nil
    ) {
        self.newFileLocation = newFileLocation
        self.newFileFolderPath = newFileFolderPath
        self.attachmentFolderPath = attachmentFolderPath
        self.useMarkdownLinks = useMarkdownLinks
        self.newLinkFormat = newLinkFormat
        self.alwaysUpdateLinks = alwaysUpdateLinks
        self.dailyFolder = dailyFolder
        self.dailyFormat = dailyFormat
        self.dailyTemplate = dailyTemplate
    }
}
