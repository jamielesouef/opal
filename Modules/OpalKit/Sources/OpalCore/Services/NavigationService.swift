//
//  NavigationService.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Observation

@MainActor
@Observable
public final class NavigationService {
    // MARK: - State

    public private(set) var tabs = TabList()
    public private(set) var reveal: RevealRequest?
    public private(set) var recentNotes: [NotePath] = []
    public var isInspectorShown = true
    public var isReadingView = false
    @ObservationIgnored public var editorTopOffset = 0
    public var isQuickSwitcherShown = false
    public var isCommandPaletteShown = false
    public var sidebarPane = SidebarPane.files

    public var openNote: NotePath? {
        notes.path
    }

    public var history: NavigationHistory {
        tabs.selected.history
    }

    // MARK: - Private

    private let vault: VaultService
    private let notes: NoteService
    private let links: LinkService
    private let recents: any RecentNotesStoring

    private var nextRevealID = 0
    private var recentsRoot: URL?
    private var tabsRoot: URL?

    // MARK: - Init

    public init(vault: VaultService, notes: NoteService, links: LinkService, recents: any RecentNotesStoring) {
        self.vault = vault
        self.notes = notes
        self.links = links
        self.recents = recents
    }

    // MARK: - Intent

    public func open(_ path: NotePath, line: Int? = nil) async {
        if path != notes.path {
            resetTabsIfVaultChanged()
            tabs.visit(path)
            editorTopOffset = 0
            reveal = nil
            await notes.open(path)
            await record(path)
            await saveTabs()
        }

        guard let line else {
            return
        }

        nextRevealID += 1
        reveal = RevealRequest(path: path, line: line, id: nextRevealID)
    }

    @discardableResult
    public func follow(_ link: Link, from source: NotePath) async -> LinkDestination {
        let destination = LinkFollowUseCase.destination(for: link, from: source, map: links.map, settings: vault.appSettings)
        switch destination {
        case let .note(path, line):
            await open(path, line: line)
        case let .create(path):
            do {
                try await vault.createNote(at: path)
            } catch {
                AppLog.error("Creating \(path) from a Link failed: \(error)")
                return .nowhere
            }
            await links.sync()
            await open(path)
        case .attachment,
             .nowhere:
            break
        }
        return destination
    }

    public func forget(_ path: NotePath) {
        tabs.forget(path)
        recentNotes.removeAll { $0 == path }
    }

    public func move(from old: NotePath, to new: NotePath) {
        tabs.move(from: old, to: new)
        recentNotes = recentNotes.map { $0 == old ? new : $0 }
    }

    // MARK: - Tabs

    public func openInNewTab(_ path: NotePath?) async {
        resetTabsIfVaultChanged()
        tabs.setTopOffset(editorTopOffset)
        tabs.add(path)
        reveal = nil
        await showSelectedTab()
        if let path {
            await record(path)
        }
        await saveTabs()
    }

    public func selectTab(_ id: Int) async {
        guard id != tabs.selectedID else {
            return
        }

        tabs.setTopOffset(editorTopOffset)
        tabs.select(id)
        await showSelectedTab()
        await saveTabs()
    }

    public func selectNeighbourTab(by offset: Int) async {
        tabs.setTopOffset(editorTopOffset)
        tabs.selectNeighbour(by: offset)
        await showSelectedTab()
    }

    public func closeTab(_ id: Int) async {
        let wasSelected = id == tabs.selectedID
        tabs.close(id)
        if wasSelected {
            await showSelectedTab()
        }
        await saveTabs()
    }

    public func closeSelectedTab() async {
        await closeTab(tabs.selectedID)
    }

    public func restoreTabs() async {
        guard let root = vault.store?.rootURL else {
            return
        }

        tabsRoot = root
        let saved = await recents.openTabs(forVaultAt: root).filter { vault.kind(of: $0) == .note }
        guard saved.isEmpty == false else {
            return
        }

        tabs = TabList(paths: saved)
        await showSelectedTab()
    }

        public func goBack() async {
        guard let path = tabs.goBack() else {
            return
        }

        reveal = nil
        editorTopOffset = 0
        await notes.open(path)
        await record(path)
    }

    public func goForward() async {
        guard let path = tabs.goForward() else {
            return
        }

        reveal = nil
        editorTopOffset = 0
        await notes.open(path)
        await record(path)
    }

    public func loadRecentNotes() async {
        guard let root = vault.store?.rootURL, root != recentsRoot else {
            return
        }

        recentsRoot = root
        recentNotes = await recents.recentNotes(forVaultAt: root)
    }

    // MARK: - Private

    private func resetTabsIfVaultChanged() {
        let root = vault.store?.rootURL
        guard root != tabsRoot else {
            return
        }

        tabsRoot = root
        tabs = TabList()
    }

    private func showSelectedTab() async {
        reveal = nil
        editorTopOffset = tabs.selected.topOffset
        if let path = tabs.selected.path {
            await notes.open(path)
        } else {
            await notes.close()
        }
    }

    private func saveTabs() async {
        guard let root = vault.store?.rootURL else {
            return
        }

        await recents.setOpenTabs(tabs.paths, forVaultAt: root)
    }

    private func record(_ path: NotePath) async {
        guard notes.path == path, let root = vault.store?.rootURL else {
            return
        }

        await loadRecentNotes()
        recentNotes = QuickSwitcherMatchUseCase.recording(path, in: recentNotes)
        await recents.setRecentNotes(recentNotes, forVaultAt: root)
    }
}
