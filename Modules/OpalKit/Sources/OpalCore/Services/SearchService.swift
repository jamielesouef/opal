//
//  SearchService.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Observation

@MainActor
@Observable
public final class SearchService {
    // MARK: - State

    public enum LoadState: Hashable, Sendable {
        case idle
        case searching
        case results([SearchResult])
        case unavailable
    }

    public var query = "" {
        didSet {
            guard query != oldValue else {
                return
            }
            scheduleSearch()
        }
    }

    public private(set) var loadState = LoadState.idle
    public private(set) var focusRequest = 0

    // MARK: - Constants

    public static let resultLimit = 100
    public static let typingDelay = Duration.milliseconds(120)

    // MARK: - Private

    private let index: IndexService
    private let navigation: NavigationService

    @ObservationIgnored private var searchTask: Task<Void, Never>?

    // MARK: - Init

    public init(index: IndexService, navigation: NavigationService) {
        self.index = index
        self.navigation = navigation
    }

    // MARK: - Intent

    public func show(query newQuery: String? = nil) {
        navigation.sidebarPane = .search
        if let newQuery {
            query = newQuery
        }
        focusRequest += 1
    }

    public func search() async {
        let parsed = SearchQueryUseCase.parse(query)
        guard parsed.isEmpty == false else {
            loadState = .idle
            return
        }

        guard let store = index.store else {
            loadState = .unavailable
            return
        }

        loadState = .searching
        do {
            let hits = try await store.search(parsed, limit: Self.resultLimit)
            let results = await Self.results(for: hits, query: parsed)
            guard Task.isCancelled == false, SearchQueryUseCase.parse(query) == parsed else {
                return
            }
            loadState = .results(results)
        } catch {
            loadState = .unavailable
        }
    }

    public func waitForSearch() async {
        await searchTask?.value
    }

    public func open(_ result: SearchResult, line: Int?) async {
        await navigation.open(result.path, line: line)
    }

    // MARK: - Private

    private func scheduleSearch() {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            do {
                try await Task.sleep(for: Self.typingDelay)
            } catch {
                return
            }
            await self?.search()
        }
    }

    @concurrent
    private nonisolated static func results(for hits: [SearchHit], query: SearchQuery) async -> [SearchResult] {
        hits
            .filter { SearchSnippetUseCase.passesFilters($0.path, text: $0.text, query: query) }
            .map { SearchSnippetUseCase.result(for: $0.path, text: $0.text, query: query) }
    }
}
