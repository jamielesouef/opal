//
//  ObsidianAppSettingsDTO.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

struct ObsidianAppSettingsDTO: Decodable {
    // MARK: - Stored

    let newFileLocation: String?
    let newFileFolderPath: String?
    let attachmentFolderPath: String?
    let useMarkdownLinks: Bool?
    let newLinkFormat: String?

    // MARK: - Domain

    func toDomain() -> ObsidianAppSettings {
        let defaults = ObsidianAppSettings.defaults
        return ObsidianAppSettings(
            newFileLocation: newFileLocation.flatMap(NewFileLocation.init(rawValue:)) ?? defaults.newFileLocation,
            newFileFolderPath: newFileFolderPath ?? defaults.newFileFolderPath,
            attachmentFolderPath: attachmentFolderPath ?? defaults.attachmentFolderPath,
            useMarkdownLinks: useMarkdownLinks ?? defaults.useMarkdownLinks,
            newLinkFormat: newLinkFormat.flatMap(LinkFormat.init(rawValue:)) ?? defaults.newLinkFormat
        )
    }
}
