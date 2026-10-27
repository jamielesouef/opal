//
//  VaultPanels.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import AppKit

@MainActor
enum VaultPanels {
    // MARK: - Panels

    static func chooseVaultFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = String(localized: "Open Vault")
        panel.message = String(localized: "Choose a folder of Markdown files. An Obsidian vault works as it is.")
        return panel.runModal() == .OK ? panel.url : nil
    }

    static func chooseNewVaultFolder() -> URL? {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = String(localized: "My Vault")
        panel.prompt = String(localized: "Create Vault")
        panel.message = String(localized: "Name the folder for your new Vault.")
        return panel.runModal() == .OK ? panel.url : nil
    }
}
