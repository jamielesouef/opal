//
//  QuickSwitcherService.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Observation

@MainActor
@Observable
public final class QuickSwitcherService {
    // MARK: - State

    public var query = "" {
        didSet {
            selectedIndex = 0
        }
    }

    public private(set) var selectedIndex = 0

    public var results: [SwitcherMatch] {
        QuickSwitcherMatchUseCase.matches(query: query, candidates: candidates, recent: navigation.recentNotes)
    }

    public var selected: SwitcherMatch? {
        let results = results
        return results.indices.contains(selectedIndex) ? results[selectedIndex] : nil
    }

    public var canCreate: Bool {
        newNotePath != nil && results.isEmpty
    }

    // MARK: - Link suggestions

    public func linkSuggestions(for query: String) -> [LinkSuggestion] {
        LinkSuggestionUseCase.suggestions(
            for: query,
            candidates: candidates,
            unresolved: links.map.unresolvedTargets,
            recent: navigation.recentNotes
        )
    }

    public func linkInsertion(for suggestion: LinkSuggestion, from source: NotePath) -> String {
        LinkSuggestionUseCase.insertion(
            for: suggestion,
            from: source,
            resolver: links.map.resolver,
            useMarkdownLinks: vault.appSettings.useMarkdownLinks
        )
    }

    // MARK: - Private

    private let vault: VaultService
    private let links: LinkService
    private let navigation: NavigationService

    private var candidates: [SwitcherCandidate] {
        let parsed = links.map.parsed
        return vault.entries
            .filter { $0.kind == .note }
            .map { SwitcherCandidate(path: $0.path, aliases: parsed[$0.path]?.aliases ?? []) }
    }

    private var newNotePath: NotePath? {
        LinkFollowUseCase.newNotePath(for: query, settings: vault.appSettings, openNote: navigation.openNote)
    }

    // MARK: - Init

    public init(vault: VaultService, links: LinkService, navigation: NavigationService) {
        self.vault = vault
        self.links = links
        self.navigation = navigation
    }

    // MARK: - Intent

    public func prepare(query newQuery: String = "") async {
        query = newQuery
        await navigation.loadRecentNotes()
    }

    public func moveSelection(by delta: Int) {
        let count = results.count
        guard count > 0 else {
            return
        }

        selectedIndex = min(max(selectedIndex + delta, 0), count - 1)
    }

    public func select(_ match: SwitcherMatch) {
        guard let index = results.firstIndex(of: match) else {
            return
        }

        selectedIndex = index
    }

    @discardableResult
    public func confirm() async -> NotePath? {
        if let selected {
            await navigation.open(selected.path)
            return selected.path
        }

        guard canCreate, let path = newNotePath else {
            return nil
        }

        do {
            try await vault.createNote(at: path)
        } catch {
            AppLog.error("Creating \(path) from the Quick Switcher failed: \(error)")
            return nil
        }
        await links.sync()
        await navigation.open(path)
        return path
    }
}
