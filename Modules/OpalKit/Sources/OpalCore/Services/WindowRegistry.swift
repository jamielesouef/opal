//
//  WindowRegistry.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation
import Observation

@MainActor
@Observable
public final class WindowRegistry {
    // MARK: - State

    @ObservationIgnored public private(set) var windowIDs: [UUID]
    public let restoredIDs: [UUID]
    public var isQuitting = false

    public var firstWindowID: UUID {
        windowIDs.first ?? restoredIDs.first ?? fallbackID
    }

    // MARK: - Private

    private let store: any WindowListStoring
    private let makeGraph: @MainActor (UUID, Bool) -> ServiceGraph
    private let fallbackID = UUID()
    @ObservationIgnored private var graphs: [UUID: ServiceGraph] = [:]
    @ObservationIgnored private var waitingVaults: [UUID: WaitingVault] = [:]

    // MARK: - Init

    public init(store: any WindowListStoring, makeGraph: @escaping @MainActor (_ id: UUID, _ isFirst: Bool) -> ServiceGraph) {
        self.store = store
        self.makeGraph = makeGraph
        restoredIDs = store.windowIDs()
        windowIDs = []
    }

    // MARK: - Graphs

    public func graph(for id: UUID) -> ServiceGraph {
        if let graph = graphs[id] {
            return graph
        }

        let graph = makeGraph(id, id == firstWindowID)
        graphs[id] = graph
        if windowIDs.contains(id) == false {
            windowIDs.append(id)
            store.setWindowIDs(windowIDs)
        }
        return graph
    }

    public func window(showing folderURL: URL) -> UUID? {
        guard case let .bringToFront(id) = OpenVaultUseCase.decide(opening: folderURL, from: UUID(), roots: roots) else {
            return nil
        }

        return id
    }

    public func decide(opening folderURL: URL, from id: UUID) -> OpenVaultDecision {
        OpenVaultUseCase.decide(opening: folderURL, from: id, roots: roots)
    }

    // MARK: - New windows

    public func defaultWindowID() -> UUID {
        graphs.isEmpty ? firstWindowID : UUID()
    }

    public func newWindow(opening waiting: WaitingVault? = nil) -> UUID {
        let id = UUID()
        waitingVaults[id] = waiting
        return id
    }

    public func takeWaitingVault(for id: UUID) -> WaitingVault? {
        waitingVaults.removeValue(forKey: id)
    }

    // MARK: - Closing

    public func close(_ id: UUID) async {
        guard let graph = graphs.removeValue(forKey: id) else {
            return
        }

        await graph.notes.flush()
        guard isQuitting == false else {
            return
        }

        graph.vault.close()
        graph.settings.detach(graph.vault)
        windowIDs.removeAll { $0 == id }
        store.setWindowIDs(windowIDs)
    }

    public func flushAll() async {
        for graph in graphs.values {
            await graph.notes.flush()
        }
    }

    // MARK: - Private

    private var roots: [UUID: URL] {
        graphs.compactMapValues(\.vault.rootURL)
    }
}
