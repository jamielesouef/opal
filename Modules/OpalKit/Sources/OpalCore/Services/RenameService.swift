//
//  RenameService.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation
import Observation

@MainActor
@Observable
public final class RenameService {
    // MARK: - Private

    private let vault: VaultService
    private let links: LinkService
    private let notes: NoteService
    private let navigation: NavigationService

    // MARK: - Init

    public init(vault: VaultService, links: LinkService, notes: NoteService, navigation: NavigationService) {
        self.vault = vault
        self.links = links
        self.notes = notes
        self.navigation = navigation
    }

    // MARK: - Plan

    public func plan(renaming path: NotePath, to name: String) -> Result<RenamePlan, RenameProblem> {
        guard let kind = vault.kind(of: path) else {
            return .failure(.unchanged)
        }

        let existing = Set(vault.entries.map(\.path))
        return RenameUseCase.newPath(renaming: path, to: name, kind: kind, existing: existing).map { target in
            plan(moving: path, to: target)
        }
    }

    public func plan(moving path: NotePath, to target: NotePath) -> RenamePlan {
        var moves: [NotePath: NotePath] = [path: target]
        if vault.kind(of: path) == .folder {
            for entry in vault.entries where entry.kind != .folder && entry.path.components.starts(with: path.components) {
                moves[entry.path] = entry.path.replacingPrefix(path, with: target)
            }
        }

        let linking = Set(moves.keys.flatMap { links.map.backlinks(to: $0).map(\.source) })
        let sorted = linking.sorted { $0.rawValue.localizedStandardCompare($1.rawValue) == .orderedAscending }
        return RenamePlan(moves: moves, linkingNotes: sorted)
    }

    // MARK: - Perform

    @discardableResult
    public func perform(_ plan: RenamePlan, from path: NotePath, updatingLinks: Bool) async throws(VaultError) -> NotePath {
        guard let store = vault.store, let target = plan.moves[path] else {
            throw .noVaultOpen
        }

        await notes.flush()
        let resolver = links.map.resolver
        let openPath = notes.path
        try await store.moveItem(from: path, to: target)

        var changed = Set(plan.moves.keys).union(plan.moves.values)
        if updatingLinks {
            let finalPaths = Set(vault.entries.map(\.path)).subtracting(plan.moves.keys).union(plan.moves.values)
            for source in plan.linkingNotes {
                let current = plan.moves[source] ?? source
                do {
                    guard let text = try await store.readNote(at: current) else {
                        continue
                    }

                    let parsed = await Self.parse(text)
                    let rewritten = LinkRewriteUseCase.rewrite(text, links: parsed.links, source: source, moves: plan.moves, resolver: resolver) { new in
                        finalPaths.filter { $0.fileName.lowercased() == new.fileName.lowercased() }.count == 1
                    }
                    if let rewritten {
                        try await store.writeNote(rewritten, at: current)
                        changed.insert(current)
                    }
                } catch {
                    AppLog.error("Updating Links in \(current) failed: \(error)")
                }
            }
        }

        for (old, new) in plan.moves {
            navigation.move(from: old, to: new)
        }
        if let openPath, let moved = plan.moves[openPath] {
            await notes.open(moved)
        }
        await vault.handleExternalChanges(changed)
        return target
    }

    // MARK: - Private

    @concurrent
    private nonisolated static func parse(_ text: String) async -> ParsedNote {
        MarkdownNoteParser.parse(text)
    }
}
