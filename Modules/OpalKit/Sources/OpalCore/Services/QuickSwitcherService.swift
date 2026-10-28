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
            scheduleSearch()
        }
    }

    public private(set) var selectedIndex = 0
    public private(set) var results: [SwitcherMatch] = []

    public var selected: SwitcherMatch? {
        let results = results
        return results.indices.contains(selectedIndex) ? results[selectedIndex] : nil
    }

    public var canCreate: Bool {
        newNotePath != nil && results.isEmpty && resultsQuery == query
    }

    // MARK: - Link suggestions

    public func linkSuggestions(for query: String) async -> [LinkSuggestion] {
        await Self.suggestions(for: query, candidates: candidates, unresolved: links.map.unresolvedTargets, recent: navigation.recentNotes)
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

    @ObservationIgnored private var cachedCandidates: (key: [Int], candidates: [SwitcherCandidate])?
    @ObservationIgnored private var searchTask: Task<Void, Never>?
    private var resultsQuery: String?

    private var candidates: [SwitcherCandidate] {
        let key = [vault.entriesRevision, links.mapRevision]
        if let cachedCandidates, cachedCandidates.key == key {
            return cachedCandidates.candidates
        }

        let parsed = links.map.parsed
        let built = vault.entries
            .filter { $0.kind == .note }
            .map { SwitcherCandidate(path: $0.path, aliases: parsed[$0.path]?.aliases ?? []) }
        cachedCandidates = (key, built)
        return built
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
        scheduleSearch()
        await waitForResults()
    }

    public func waitForResults() async {
        await searchTask?.value
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
        if resultsQuery != query {
            scheduleSearch()
            await waitForResults()
        }

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

    // MARK: - Search

    private func scheduleSearch() {
        searchTask?.cancel()
        let query = query
        let candidates = candidates
        let recent = navigation.recentNotes
        searchTask = Task { [weak self] in
            let found = await Self.matches(for: query, candidates: candidates, recent: recent)
            guard Task.isCancelled == false, let self, self.query == query else {
                return
            }

            results = found
            resultsQuery = query
        }
    }

    @concurrent
    private nonisolated static func matches(for query: String, candidates: [SwitcherCandidate], recent: [NotePath]) async -> [SwitcherMatch] {
        QuickSwitcherMatchUseCase.matches(query: query, candidates: candidates, recent: recent)
    }

    @concurrent
    private nonisolated static func suggestions(
        for query: String,
        candidates: [SwitcherCandidate],
        unresolved: [String],
        recent: [NotePath]
    ) async -> [LinkSuggestion] {
        LinkSuggestionUseCase.suggestions(for: query, candidates: candidates, unresolved: unresolved, recent: recent)
    }
}
