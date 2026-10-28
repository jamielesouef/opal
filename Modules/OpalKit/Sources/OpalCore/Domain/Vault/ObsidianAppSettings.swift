//
//  ObsidianAppSettings.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct ObsidianAppSettings: Hashable, Sendable {
    // MARK: - Defaults

    public static let defaults = ObsidianAppSettings(
        newFileLocation: .root,
        newFileFolderPath: "",
        attachmentFolderPath: "/",
        useMarkdownLinks: false
    )

    // MARK: - Stored

    public let newFileLocation: NewFileLocation
    public let newFileFolderPath: String
    public let attachmentFolderPath: String
    public let useMarkdownLinks: Bool
    public let newLinkFormat: LinkFormat

    // MARK: - Init

    public init(
        newFileLocation: NewFileLocation,
        newFileFolderPath: String,
        attachmentFolderPath: String,
        useMarkdownLinks: Bool,
        newLinkFormat: LinkFormat = .shortest
    ) {
        self.newFileLocation = newFileLocation
        self.newFileFolderPath = newFileFolderPath
        self.attachmentFolderPath = attachmentFolderPath
        self.useMarkdownLinks = useMarkdownLinks
        self.newLinkFormat = newLinkFormat
    }
}
