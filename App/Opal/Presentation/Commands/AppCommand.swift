//
//  AppCommand.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import SwiftUI

enum AppCommand: String, CaseIterable, Identifiable {
    case settings
    case newNote
    case duplicateNote
    case newFolder
    case openVault
    case createVault
    case save
    case reloadVault
    case insertTemplate
    case quickSwitcher
    case dailyNote
    case searchVault
    case back
    case forward
    case toggleReadingView
    case toggleLiveMarkdown
    case toggleInspector
    case splitRight
    case newTab
    case closeTab
    case nextTab
    case previousTab

    // MARK: - Identifiable

    var id: String {
        rawValue
    }

    // MARK: - Display

    var title: String {
        switch self {
        case .settings:
            String(localized: "Settings…")
        case .newNote:
            String(localized: "New Note")
        case .duplicateNote:
            String(localized: "Duplicate Note")
        case .newFolder:
            String(localized: "New Folder")
        case .openVault:
            String(localized: "Open Vault…")
        case .createVault:
            String(localized: "Create Vault…")
        case .save:
            String(localized: "Save")
        case .reloadVault:
            String(localized: "Reload Vault")
        case .insertTemplate:
            String(localized: "Insert Template…")
        case .quickSwitcher:
            String(localized: "Quick Switcher…")
        case .dailyNote:
            String(localized: "Today's Daily Note")
        case .searchVault:
            String(localized: "Search Vault…")
        case .back:
            String(localized: "Back")
        case .forward:
            String(localized: "Forward")
        case .toggleReadingView:
            String(localized: "Toggle Reading View")
        case .toggleLiveMarkdown:
            String(localized: "Toggle Live Markdown")
        case .toggleInspector:
            String(localized: "Toggle Inspector")
        case .splitRight:
            String(localized: "Split Right")
        case .newTab:
            String(localized: "New Tab")
        case .closeTab:
            String(localized: "Close Tab")
        case .nextTab:
            String(localized: "Next Tab")
        case .previousTab:
            String(localized: "Previous Tab")
        }
    }

    var group: String {
        switch self {
        case .settings:
            String(localized: "Opal")
        case .newNote, .duplicateNote, .newFolder, .openVault, .createVault, .save, .reloadVault, .newTab, .closeTab:
            String(localized: "File")
        case .insertTemplate:
            String(localized: "Edit")
        case .quickSwitcher, .dailyNote, .searchVault, .back, .forward, .nextTab, .previousTab:
            String(localized: "Go")
        case .toggleReadingView, .toggleLiveMarkdown, .toggleInspector, .splitRight:
            String(localized: "View")
        }
    }

    // MARK: - Shortcut

    var shortcut: KeyboardShortcut? {
        switch self {
        case .newNote:
            KeyboardShortcut("n")
        case .newFolder:
            KeyboardShortcut("n", modifiers: [.command, .shift])
        case .openVault:
            KeyboardShortcut("o", modifiers: [.command, .shift])
        case .save:
            KeyboardShortcut("s")
        case .reloadVault:
            KeyboardShortcut("r")
        case .insertTemplate:
            KeyboardShortcut("t", modifiers: [.command, .option])
        case .quickSwitcher:
            KeyboardShortcut("o")
        case .dailyNote:
            KeyboardShortcut("d", modifiers: [.command, .option])
        case .searchVault:
            KeyboardShortcut("f", modifiers: [.command, .shift])
        case .back:
            KeyboardShortcut("[")
        case .forward:
            KeyboardShortcut("]")
        case .toggleReadingView:
            KeyboardShortcut("e")
        case .toggleInspector:
            KeyboardShortcut("0", modifiers: [.command, .option])
        case .splitRight:
            KeyboardShortcut("\\")
        case .settings:
            KeyboardShortcut(",")
        case .newTab:
            KeyboardShortcut("t")
        case .closeTab:
            KeyboardShortcut("w")
        case .nextTab:
            KeyboardShortcut(.tab, modifiers: .control)
        case .previousTab:
            KeyboardShortcut(.tab, modifiers: [.control, .shift])
        case .duplicateNote, .createVault, .toggleLiveMarkdown:
            nil
        }
    }

    var shortcutText: String {
        guard let shortcut else {
            return ""
        }

        let modifiers = shortcut.modifiers
        var text = ""
        if modifiers.contains(.control) {
            text += "⌃"
        }
        if modifiers.contains(.option) {
            text += "⌥"
        }
        if modifiers.contains(.shift) {
            text += "⇧"
        }
        if modifiers.contains(.command) {
            text += "⌘"
        }
        let key = shortcut.key == .tab ? "⇥" : String(shortcut.key.character).uppercased()
        return text + key
    }
}
