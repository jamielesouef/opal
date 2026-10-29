//
//  LaunchArguments.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import AppKit
import OpalCore

struct LaunchArguments {
    // MARK: - Constants

    private enum Constants {
        static let vaultPath = "-OpalVaultPath"
        static let defaultsSuite = "-OpalDefaultsSuite"
        static let openNote = "-OpalOpenNote"
        static let appearance = "-OpalAppearance"
        static let quickOpen = "-OpalQuickOpen"
        static let typeText = "-OpalTypeText"
        static let indexFolder = "-OpalIndexFolder"
        static let search = "-OpalSearch"
        static let sidebarPane = "-OpalSidebarPane"
        static let snapshot = "-OpalSnapshot"
        static let readingView = "-OpalReadingView"
        static let dailyNote = "-OpalDailyNote"
        static let templates = "-OpalTemplates"
        static let rename = "-OpalRename"
        static let move = "-OpalMove"
        static let delete = "-OpalDelete"
        static let palette = "-OpalCommandPalette"
        static let tabs = "-OpalTabs"
        static let split = "-OpalSplit"
        static let splitShare = "-OpalSplitShare"
        static let hideInspector = "-OpalHideInspector"
        static let settings = "-OpalSettings"
        static let newWindow = "-OpalNewWindow"
        static let restoreState = "-OpalRestoreState"
    }

    // MARK: - Stored

    let vaultURL: URL?
    let defaultsSuite: String?
    let openNote: NotePath?
    let appearance: String?
    let quickOpen: String?
    let typeText: String?
    let indexFolderURL: URL?
    let search: String?
    let sidebarPane: SidebarPane?
    let snapshotURL: URL?
    let isReadingView: Bool
    let opensDailyNote: Bool
    let showsTemplates: Bool
    let renaming: NotePath?
    let moving: NotePath?
    let deleting: NotePath?
    let showsCommandPalette: Bool
    let extraTabs: [NotePath]
    let splitNote: NotePath?
    let splitShare: Double?
    let hidesInspector: Bool
    let settingsTab: String?
    let opensNewWindow: Bool
    let forcesRestore: Bool

    // MARK: - Derived

    var request: LaunchRequest {
        #if DEBUG
            let typed = typeText
        #else
            let typed: String? = nil
        #endif
        return LaunchRequest(note: openNote, quickOpen: quickOpen, search: search, sidebarPane: sidebarPane, typeText: typed, isReadingView: isReadingView, opensDailyNote: opensDailyNote, showsTemplates: showsTemplates, renaming: renaming, moving: moving, deleting: deleting, showsCommandPalette: showsCommandPalette, extraTabs: extraTabs, splitNote: splitNote, splitShare: splitShare, hidesInspector: hidesInspector, settingsTab: settingsTab, opensNewWindow: opensNewWindow)
    }

    var restoresState: Bool {
        vaultURL == nil || forcesRestore
    }

    var appearanceName: NSAppearance.Name? {
        switch appearance {
        case "light":
            .aqua
        case "dark":
            .darkAqua
        default:
            nil
        }
    }

    // MARK: - Init

    init(_ arguments: [String]) {
        vaultURL = Self.value(after: Constants.vaultPath, in: arguments).map { URL(filePath: $0, directoryHint: .isDirectory) }
        defaultsSuite = Self.value(after: Constants.defaultsSuite, in: arguments)
        openNote = Self.value(after: Constants.openNote, in: arguments).map(NotePath.init)
        appearance = Self.value(after: Constants.appearance, in: arguments)
        quickOpen = Self.value(after: Constants.quickOpen, in: arguments)
        typeText = Self.value(after: Constants.typeText, in: arguments)
        search = Self.value(after: Constants.search, in: arguments)
        sidebarPane = Self.value(after: Constants.sidebarPane, in: arguments).flatMap(SidebarPane.init(rawValue:))
        isReadingView = arguments.contains(Constants.readingView)
        opensDailyNote = arguments.contains(Constants.dailyNote)
        showsTemplates = arguments.contains(Constants.templates)
        renaming = Self.value(after: Constants.rename, in: arguments).map(NotePath.init)
        moving = Self.value(after: Constants.move, in: arguments).map(NotePath.init)
        deleting = Self.value(after: Constants.delete, in: arguments).map(NotePath.init)
        showsCommandPalette = arguments.contains(Constants.palette)
        extraTabs = (Self.value(after: Constants.tabs, in: arguments) ?? "").split(separator: ",").map { NotePath(String($0)) }
        opensNewWindow = arguments.contains(Constants.newWindow)
        forcesRestore = arguments.contains(Constants.restoreState)
        settingsTab = Self.value(after: Constants.settings, in: arguments)
        splitNote = Self.value(after: Constants.split, in: arguments).map(NotePath.init)
        splitShare = Self.value(after: Constants.splitShare, in: arguments).flatMap(Double.init)
        hidesInspector = arguments.contains(Constants.hideInspector)
        snapshotURL = Self.value(after: Constants.snapshot, in: arguments).map { URL(filePath: $0) }
        indexFolderURL = Self.value(after: Constants.indexFolder, in: arguments).map { URL(filePath: $0, directoryHint: .isDirectory) }
    }

    // MARK: - Private

    private static func value(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
            return nil
        }

        return arguments[index + 1]
    }
}
