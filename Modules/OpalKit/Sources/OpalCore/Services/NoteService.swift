//
//  NoteService.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Observation

@MainActor
@Observable
public final class NoteService {
    // MARK: - State

    public enum LoadState: Hashable, Sendable {
        case noNote
        case loading(NotePath)
        case failed(NotePath, VaultError)
        case editing(Note)
        case conflict(Note, diskText: String)

        public var note: Note? {
            switch self {
            case let .editing(note),
                 let .conflict(note, _):
                note
            case .noNote,
                 .loading,
                 .failed:
                nil
            }
        }
    }

    public enum SaveStatus: Hashable, Sendable {
        case saved
        case unsaved
        case failed(VaultError)
    }

    public var loadState: LoadState {
        switch (path, focused) {
        case (nil, _):
            .noNote
        case let (path?, nil):
            .loading(path)
        case let (_, document?):
            document.loadState
        }
    }

    public var saveStatus: SaveStatus {
        focused?.saveStatus ?? .saved
    }

    public private(set) var path: NotePath?
    public private(set) var documents: [NotePath: NoteDocument] = [:]

    public var focused: NoteDocument? {
        path.flatMap { documents[$0] }
    }

    public var isReady: Bool {
        focused?.isReady == true
    }

    public var revision: Int {
        focused?.revision ?? 0
    }

    // MARK: - Private

    private let vault: VaultService
    private let links: LinkService?
    private let index: IndexService?
    private let clock: any Clocking
    private let saveDelay: Duration
    private var alsoShown: Set<NotePath> = []

    // MARK: - Init

    public init(
        vault: VaultService,
        links: LinkService? = nil,
        index: IndexService? = nil,
        clock: any Clocking,
        saveDelay: Duration = .milliseconds(800)
    ) {
        self.vault = vault
        self.clock = clock
        self.links = links
        self.index = index
        self.saveDelay = saveDelay
    }

    // MARK: - Intent

    public func document(for path: NotePath) -> NoteDocument? {
        documents[path]
    }

    public func show(_ focusedPath: NotePath?, alsoShowing others: Set<NotePath>) async {
        let wanted = others.union(focusedPath.map { [$0] } ?? [])
        for (shown, document) in documents where wanted.contains(shown) == false {
            await document.flush()
            documents[shown] = nil
        }

        path = focusedPath
        alsoShown = others
        links?.showNotes(wanted, focused: focusedPath)

        var loading: [NoteDocument] = []
        for shown in wanted.sorted(by: { $0.rawValue < $1.rawValue }) where documents[shown] == nil {
            let document = NoteDocument(path: shown, vault: vault, links: links, index: index, clock: clock, saveDelay: saveDelay)
            documents[shown] = document
            loading.append(document)
        }
        for document in loading {
            await document.load()
        }
    }

    public func open(_ newPath: NotePath) async {
        if newPath == path, let focused, focused.isReady == false {
            await focused.retry()
            return
        }

        await show(newPath, alsoShowing: alsoShown)
    }

    public func close() async {
        await show(nil, alsoShowing: alsoShown)
    }

    public func close(_ paths: Set<NotePath>) async {
        await show(path.flatMap { paths.contains($0) ? nil : $0 }, alsoShowing: alsoShown.subtracting(paths))
    }

    public func retry() async {
        await focused?.retry()
    }

    public func edit(_ text: String) {
        focused?.edit(text)
    }

    // MARK: - Properties

    public var frontmatter: Frontmatter? {
        focused?.frontmatter
    }

    public func type(of property: Property) -> PropertyType {
        PropertyTypeUseCase.type(of: property, declared: vault.propertyTypes)
    }

    public func setProperty(_ property: Property, to value: PropertyValue) {
        focused?.setProperty(property, to: value)
    }

    public func removeProperty(_ property: Property) {
        focused?.removeProperty(property)
    }

    public func addProperty(named key: String) {
        focused?.addProperty(named: key)
    }

    // MARK: - Body

    public func attach(_ data: Data, named fileName: String?) async -> String? {
        await focused?.attach(data, named: fileName)
    }

    public func toggleCheckbox(onLine line: Int) {
        focused?.toggleCheckbox(onLine: line)
    }

    // MARK: - Saving

    public func flush() async {
        for document in documents.values {
            await document.flush()
        }
    }

    public func keepMyVersion() async {
        await focused?.keepMyVersion()
    }

    public func useVersionOnDisk() {
        focused?.useVersionOnDisk()
    }

    public func reloadIfUnchanged(_ changed: Set<NotePath>) async {
        for (shown, document) in documents where changed.contains(shown) {
            await document.reloadIfUnchanged()
        }
    }
}
