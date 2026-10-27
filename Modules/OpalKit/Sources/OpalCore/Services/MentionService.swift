//
//  MentionService.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Observation

@MainActor
@Observable
public final class MentionService {
    // MARK: - State

    public private(set) var target: NotePath?
    public private(set) var mentions: [UnlinkedMention] = []

    // MARK: - Constants

    public static let candidateLimit = 200

    // MARK: - Private

    private let vault: VaultService
    private let index: IndexService
    private let links: LinkService
    private let notes: NoteService

    // MARK: - Init

    public init(vault: VaultService, index: IndexService, links: LinkService, notes: NoteService) {
        self.vault = vault
        self.index = index
        self.links = links
        self.notes = notes
    }

    // MARK: - Intent

    public func load(for path: NotePath?) async {
        target = path
        guard let path, let store = index.store else {
            mentions = []
            return
        }

        let names = [path.name] + (links.map.parsed[path]?.aliases ?? [])
        var hits: [NotePath: SearchHit] = [:]
        for name in names {
            do {
                for hit in try await store.search(SearchQuery(phrases: [name]), limit: Self.candidateLimit) where hit.path != path {
                    hits[hit.path] = hit
                }
            } catch {
                AppLog.error("Finding mentions of \(name) failed: \(error)")
            }
        }

        let found = await Self.mentions(of: names, in: Array(hits.values))
        guard target == path else {
            return
        }
        mentions = found
    }

    public func link(_ mention: UnlinkedMention) async -> Bool {
        guard let target, let store = vault.store else {
            return false
        }

        let targetText = LinkSuggestionUseCase.shortestTarget(for: target, from: mention.source, resolver: links.map.resolver)
        if notes.path == mention.source, let text = notes.loadState.note?.text {
            guard let linked = UnlinkedMentionUseCase.linking(mention, in: text, target: targetText, targetName: target.name) else {
                return false
            }
            notes.edit(linked)
            await notes.flush()
        } else {
            do {
                guard let text = try await store.readNote(at: mention.source),
                      let linked = UnlinkedMentionUseCase.linking(mention, in: text, target: targetText, targetName: target.name)
                else {
                    return false
                }
                try await store.writeNote(linked, at: mention.source)
                await links.update(mention.source, text: linked)
                await index.update([mention.source])
            } catch {
                AppLog.error("Linking a mention in \(mention.source) failed: \(error)")
                return false
            }
        }

        await links.waitForRebuild()
        await load(for: target)
        return true
    }

    // MARK: - Private

    @concurrent
    private nonisolated static func mentions(of names: [String], in hits: [SearchHit]) async -> [UnlinkedMention] {
        hits
            .sorted { $0.path.name.localizedStandardCompare($1.path.name) == .orderedAscending }
            .flatMap { hit in
                UnlinkedMentionUseCase.mentions(of: names, in: hit.text, parsed: MarkdownNoteParser.parse(hit.text), source: hit.path)
            }
    }
}
