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

    public private(set) var history = NavigationHistory()
    public private(set) var reveal: RevealRequest?
    public private(set) var recentNotes: [NotePath] = []
    public var isInspectorShown = true
    public var isQuickSwitcherShown = false

    // MARK: - Private

    private let vault: VaultService
    private let notes: NoteService
    private let links: LinkService
    private let recents: any RecentNotesStoring

    private var nextRevealID = 0
    private var recentsRoot: URL?

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
            history.visit(from: notes.path, to: path)
            reveal = nil
            await notes.open(path)
            await record(path)
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

    public func goBack() async {
        guard let path = history.goBack(from: notes.path) else {
            return
        }

        reveal = nil
        await notes.open(path)
        await record(path)
    }

    public func goForward() async {
        guard let path = history.goForward(from: notes.path) else {
            return
        }

        reveal = nil
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

    private func record(_ path: NotePath) async {
        guard notes.path == path, let root = vault.store?.rootURL else {
            return
        }

        await loadRecentNotes()
        recentNotes = QuickSwitcherMatchUseCase.recording(path, in: recentNotes)
        await recents.setRecentNotes(recentNotes, forVaultAt: root)
    }
}
