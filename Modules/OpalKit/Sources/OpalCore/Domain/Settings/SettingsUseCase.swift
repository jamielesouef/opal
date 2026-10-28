//
//  SettingsUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

public enum SettingsUseCase {
    // MARK: - Effective

    public static func appSettings(_ opal: OpalSettings, vault: VaultSettings) -> ObsidianAppSettings {
        ObsidianAppSettings(
            newFileLocation: vault.newFileLocation ?? opal.newFileLocation,
            newFileFolderPath: vault.newFileFolderPath ?? opal.newFileFolderPath,
            attachmentFolderPath: vault.attachmentFolderPath ?? opal.attachmentFolderPath,
            useMarkdownLinks: vault.useMarkdownLinks ?? opal.useMarkdownLinks,
            newLinkFormat: vault.newLinkFormat ?? ObsidianAppSettings.defaults.newLinkFormat
        )
    }

    public static func dailyNoteSettings(_ opal: OpalSettings, vault: VaultSettings) -> DailyNoteSettings {
        DailyNoteSettings(
            folder: vault.dailyFolder ?? opal.dailyFolder,
            format: vault.dailyFormat ?? (opal.dailyFormat.isEmpty ? DailyNoteSettings.defaults.format : opal.dailyFormat),
            template: vault.dailyTemplate ?? opal.dailyTemplate
        )
    }

    public static func linkUpdate(_ opal: OpalSettings, vault: VaultSettings) -> LinkUpdate {
        vault.alwaysUpdateLinks.map { $0 ? .always : .ask } ?? opal.linkUpdate
    }
}
