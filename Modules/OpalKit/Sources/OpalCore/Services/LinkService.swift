//
//  LinkService.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Observation

@MainActor
@Observable
public final class LinkService {
    // MARK: - State

    public enum LoadState: Hashable, Sendable {
        case empty
        case building
        case ready
    }

    public var loadState: LoadState {
        switch (pendingBuilds > 0, rootURL) {
        case (true, _):
            .building
        case (false, nil):
            .empty
        case (false, .some):
            .ready
        }
    }

    public private(set) var map = LinkMap.empty
    public private(set) var openNote: OpenNoteLinks?

    // MARK: - Constants

    public static let mainActorParseLimit = 64 * 1024
    public static let largeNoteDelay = Duration.milliseconds(200)

    // MARK: - Private

    private let vault: VaultService

    private var parsed: [NotePath: ParsedNote] = [:]
    private var paths: [NotePath] = []
    private var rootURL: URL?
    private var pendingBuilds = 0
    private var generation = 0
    @ObservationIgnored private var rebuildTask: Task<Void, Never>?
    @ObservationIgnored private var openNoteTask: Task<Void, Never>?
    private var openNoteSource: (path: NotePath, text: String)?

    // MARK: - Init

    public init(vault: VaultService) {
        self.vault = vault
    }

    // MARK: - Intent

    public func sync() async {
        guard let store = vault.store else {
            reset()
            return
        }

        if rootURL != store.rootURL {
            reset()
            rootURL = store.rootURL
        }

        let entries = vault.entries
        let notes = Set(entries.filter { $0.kind == .note }.map(\.path))
        paths = entries.filter { $0.kind != .folder }.map(\.path)
        parsed = parsed.filter { notes.contains($0.key) }

        let missing = notes.filter { parsed[$0] == nil }
        pendingBuilds += 1
        let read = await Self.readAndParse(Array(missing), store: store)
        pendingBuilds -= 1
        guard rootURL == store.rootURL else {
            return
        }

        for (path, note) in read where notes.contains(path) {
            parsed[path] = note
        }
        scheduleRebuild()
        await rebuildTask?.value
    }

    public func update(_ path: NotePath, text: String) {
        guard path.isNote, rootURL != nil else {
            return
        }

        parsed[path] = MarkdownNoteParser.parse(text)
        scheduleRebuild()
    }

    public func refresh(_ changed: Set<NotePath>) async {
        guard let store = vault.store, rootURL == store.rootURL else {
            return
        }

        let notes = changed.filter(\.isNote)
        let read = await Self.readAndParse(Array(notes), store: store)
        for path in notes {
            parsed[path] = read[path]
        }
        scheduleRebuild()
        await rebuildTask?.value
    }

    public func waitForRebuild() async {
        await rebuildTask?.value
    }

    public func openNoteChanged(_ path: NotePath?, text: String) {
        openNoteTask?.cancel()
        guard let path else {
            openNoteSource = nil
            openNote = nil
            return
        }

        openNoteSource = (path, text)
        let map = map
        guard text.utf16.count > Self.mainActorParseLimit else {
            openNote = Self.analyse(path: path, text: text, map: map)
            return
        }

        openNoteTask = Task { [weak self] in
            do {
                try await Task.sleep(for: Self.largeNoteDelay)
            } catch {
                return
            }

            let analysed = await Self.analyseConcurrently(path: path, text: text, map: map)
            guard Task.isCancelled == false, let self else {
                return
            }
            openNote = analysed
        }
    }

    public func waitForOpenNote() async {
        await openNoteTask?.value
    }

    // MARK: - Reads

    public func link(at offset: Int, in text: String) -> Link? {
        let parsed = openNote.flatMap { $0.textLength == text.utf16.count ? $0.parsed : nil } ?? MarkdownNoteParser.parse(text)
        return parsed.links.first { $0.span.contains(offset) }
    }

    // MARK: - Private

    private func refreshOpenNote() {
        guard let source = openNoteSource else {
            return
        }

        openNoteChanged(source.path, text: source.text)
    }

    private nonisolated static func analyse(path: NotePath, text: String, map: LinkMap) -> OpenNoteLinks {
        let parsed = MarkdownNoteParser.parse(text)
        return OpenNoteLinks(
            path: path,
            textLength: text.utf16.count,
            parsed: parsed,
            highlights: map.highlights(in: parsed, from: path)
        )
    }

    @concurrent
    private nonisolated static func analyseConcurrently(path: NotePath, text: String, map: LinkMap) async -> OpenNoteLinks {
        analyse(path: path, text: text, map: map)
    }

    private func reset() {
        generation += 1
        rebuildTask?.cancel()
        rebuildTask = nil
        parsed = [:]
        paths = []
        rootURL = nil
        map = .empty
    }

    private func scheduleRebuild() {
        generation += 1
        let current = generation
        let paths = paths
        let parsed = parsed
        pendingBuilds += 1
        rebuildTask = Task { [weak self] in
            let built = await Self.buildMap(paths: paths, parsed: parsed)
            guard let self else {
                return
            }

            pendingBuilds -= 1
            if current == generation {
                map = built
                refreshOpenNote()
            }
        }
    }

    @concurrent
    private nonisolated static func readAndParse(_ paths: [NotePath], store: any VaultFileStoring) async -> [NotePath: ParsedNote] {
        var result: [NotePath: ParsedNote] = [:]
        for path in paths {
            do {
                guard let text = try await store.readNote(at: path) else {
                    continue
                }
                result[path] = MarkdownNoteParser.parse(text)
            } catch {
                AppLog.error("Reading Links from \(path) failed: \(error)")
            }
        }
        return result
    }

    @concurrent
    private nonisolated static func buildMap(paths: [NotePath], parsed: [NotePath: ParsedNote]) async -> LinkMap {
        LinkMap(paths: paths, parsed: parsed)
    }
}
