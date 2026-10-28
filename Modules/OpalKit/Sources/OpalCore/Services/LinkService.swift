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

    public private(set) var map = LinkMap.empty {
        didSet {
            mapRevision += 1
        }
    }

    public private(set) var mapRevision = 0
    public private(set) var openNote: OpenNoteLinks?

    // MARK: - Constants

    public static let largeNoteLimit = 64 * 1024
    public static let largeNoteDelay = Duration.milliseconds(200)

    // MARK: - Private

    private let vault: VaultService
    private let index: IndexService?

    private var parsed: [NotePath: ParsedNote] = [:]
    private var paths: [NotePath] = []
    private var rootURL: URL?
    private var pendingBuilds = 0
    private var generation = 0
    @ObservationIgnored private var rebuildTask: Task<Void, Never>?
    @ObservationIgnored private var openNoteTask: Task<Void, Never>?
    private var openNoteSource: (path: NotePath, text: String)?

    // MARK: - Init

    public init(vault: VaultService, index: IndexService? = nil) {
        self.vault = vault
        self.index = index
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
        let indexed = await indexedNotes(for: missing)
        let read = await Self.readAndParse(Array(missing.subtracting(indexed.keys)), store: store)
            .merging(indexed) { fromFile, _ in fromFile }
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

    public func update(_ path: NotePath, text: String) async {
        guard path.isNote, rootURL != nil else {
            return
        }

        parsed[path] = await Self.parseConcurrently(text)
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
        let delay = text.utf16.count > Self.largeNoteLimit ? Self.largeNoteDelay : .zero
        openNoteTask = Task { [weak self] in
            if delay > .zero {
                do {
                    try await Task.sleep(for: delay)
                } catch {
                    return
                }
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

    public func readingBlocks(of path: NotePath, text: String) async -> [ReadingBlock] {
        let analysed = openNote.flatMap { $0.path == path && $0.textLength == text.utf16.count ? $0 : nil }
        return await Self.readingConcurrently(path: path, text: text, analysed: analysed, map: map)
    }

    public func embed(_ link: Link, from source: NotePath, chain: [NotePath]) async -> EmbedContent {
        guard let target = map.resolver.resolve(link.target, from: source) else {
            return .unresolved(link.target)
        }

        switch EmbedUseCase.media(of: target) {
        case .image:
            return .image(path: target, width: EmbedUseCase.width(from: link.displayText))
        case .pdf:
            return .pdf(target)
        case .file:
            return .file(target)
        case .note:
            break
        }

        guard chain.contains(target) == false else {
            return .recursive(target)
        }

        guard let store = vault.store, let text = try? await store.readNote(at: target) else {
            return .unresolved(link.target)
        }

        let title = link.subpath.map { _ in ReadingInlineBuilder.display(Link(target: target.name, subpath: link.subpath, span: link.span, line: 0, lineText: "")) } ?? target.name
        return await Self.embedConcurrently(target: target, title: title, subpath: link.subpath, text: text, map: map)
    }

    public func link(at offset: Int, in text: String) -> Link? {
        let parsed = openNote.flatMap { $0.textLength == text.utf16.count ? $0.parsed : nil } ?? MarkdownNoteParser.parse(text)
        return parsed.links.first { $0.span.contains(offset) }
    }

    // MARK: - Private

    private func indexedNotes(for paths: Set<NotePath>) async -> [NotePath: ParsedNote] {
        guard paths.isEmpty == false, let index, index.loadState == .ready, let store = index.store else {
            return [:]
        }

        do {
            return try await store.parsedNotes().filter { paths.contains($0.key) }
        } catch {
            AppLog.error("Reading Links from the Index failed: \(error)")
            return [:]
        }
    }

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
            styles: (map.linkStyles(in: parsed, from: path) + MarkdownStyleParser.runs(in: text, parsed: parsed))
                .sorted { $0.span.location < $1.span.location },
            frontmatter: FrontmatterParser.parse(text)
        )
    }

    @concurrent
    private nonisolated static func parseConcurrently(_ text: String) async -> ParsedNote {
        MarkdownNoteParser.parse(text)
    }

    @concurrent
    private nonisolated static func analyseConcurrently(path: NotePath, text: String, map: LinkMap) async -> OpenNoteLinks {
        analyse(path: path, text: text, map: map)
    }

    @concurrent
    private nonisolated static func readingConcurrently(path: NotePath, text: String, analysed: OpenNoteLinks?, map: LinkMap) async -> [ReadingBlock] {
        let note = analysed ?? analyse(path: path, text: text, map: map)
        return MarkdownReadingParser.blocks(in: text, parsed: note.parsed, styles: note.styles)
    }

    @concurrent
    private nonisolated static func embedConcurrently(target: NotePath, title: String, subpath: LinkSubpath?, text: String, map: LinkMap) async -> EmbedContent {
        let parsed = MarkdownNoteParser.parse(text)
        let lines = TextLineUseCase.lineStartOffsets(in: text)
        let nsText = text as NSString
        let lineRange = { (line: Int) in
            NSRange(location: lines[line], length: (lines.indices.contains(line + 1) ? lines[line + 1] : nsText.length) - lines[line])
        }
        guard let range = EmbedUseCase.lines(for: subpath, in: parsed, lineCount: lines.count, isBlank: {
            nsText.substring(with: lineRange($0)).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) else {
            return .note(path: target, title: title, blocks: [])
        }

        let start = range.lowerBound == 0 ? 0 : lines[range.lowerBound]
        let end = range.upperBound < lines.count ? lines[range.upperBound] : nsText.length
        let section = nsText.substring(with: NSRange(location: start, length: end - start))
        let sectionParsed = MarkdownNoteParser.parse(section)
        let styles = (map.linkStyles(in: sectionParsed, from: target) + MarkdownStyleParser.runs(in: section, parsed: sectionParsed))
            .sorted { $0.span.location < $1.span.location }
        return .note(path: target, title: title, blocks: MarkdownReadingParser.blocks(in: section, parsed: sectionParsed, styles: styles))
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
