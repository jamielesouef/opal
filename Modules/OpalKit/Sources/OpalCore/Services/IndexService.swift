//
//  IndexService.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Observation

@MainActor
@Observable
public final class IndexService {
    // MARK: - State

    public enum LoadState: Hashable, Sendable {
        case closed
        case indexing(done: Int, total: Int)
        case ready
        case failed(IndexError)
    }

    public private(set) var loadState = LoadState.closed
    public private(set) var revision = 0
    public private(set) var store: (any IndexStoring)?

    // MARK: - Constants

    public static let batchSize = 200

    // MARK: - Private

    private let vault: VaultService
    private let makeIndex: @Sendable (URL) throws(IndexError) -> any IndexStoring

    private var rootURL: URL?

    // MARK: - Init

    public init(vault: VaultService, makeIndex: @escaping @Sendable (URL) throws(IndexError) -> any IndexStoring) {
        self.vault = vault
        self.makeIndex = makeIndex
    }

    // MARK: - Intent

    public func sync() async {
        guard let vaultStore = vault.store else {
            close()
            return
        }

        guard let index = openIndex(for: vaultStore.rootURL) else {
            return
        }

        do {
            let plan = try await IndexSyncPlanUseCase.plan(disk: vaultStore.noteStamps(), indexed: index.stamps())
            try await index.remove(plan.toRemove)
            var done = 0

            loadState = plan.toRead.isEmpty ? .ready : .indexing(done: done, total: plan.toRead.count)

            for start in stride(from: 0, to: plan.toRead.count, by: Self.batchSize) {
                let batch = Array(plan.toRead[start ..< min(start + Self.batchSize, plan.toRead.count)])
                try await index.upsert(Self.read(batch, from: vaultStore))

                guard rootURL == vaultStore.rootURL else {
                    return
                }

                done += batch.count
                loadState = .indexing(done: done, total: plan.toRead.count)
            }
            loadState = .ready
            revision += 1
        } catch let error as IndexError {
            fail(error)
        } catch {
            fail(.readFailed)
        }
    }

    public func update(_ paths: Set<NotePath>) async {
        guard let vaultStore = vault.store, let index = store, rootURL == vaultStore.rootURL else {
            return
        }

        let notes = paths.filter(\.isNote)
        guard notes.isEmpty == false else {
            return
        }

        let read = await Self.read(Array(notes), from: vaultStore)
        let gone = notes.subtracting(read.map(\.path))
        do {
            try await index.upsert(read)
            try await index.remove(Array(gone))
            revision += 1
        } catch {
            fail(error)
        }
    }

    // MARK: - Private

    private func openIndex(for root: URL) -> (any IndexStoring)? {
        if rootURL == root, let store {
            return store
        }

        close()
        do {
            let index = try makeIndex(root)
            store = index
            rootURL = root
            return index
        } catch {
            fail(error)
            return nil
        }
    }

    private func close() {
        store = nil
        rootURL = nil
        loadState = .closed
    }

    private func fail(_ error: IndexError) {
        AppLog.error("The Index failed: \(error)")
        loadState = .failed(error)
    }

    @concurrent
    private nonisolated static func read(_ paths: [NotePath], from store: any VaultFileStoring) async -> [IndexedNote] {
        var notes: [IndexedNote] = []
        for path in paths {
            do {
                guard let stamp = await store.stamp(of: path), let text = try await store.readNote(at: path) else {
                    continue
                }
                notes.append(IndexedNote(path: path, stamp: stamp, parsed: MarkdownNoteParser.parse(text), text: text))
            } catch {
                AppLog.error("Indexing \(path) failed: \(error)")
            }
        }
        return notes
    }
}
