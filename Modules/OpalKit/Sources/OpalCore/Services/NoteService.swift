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
        switch (path, isLoading, loadError, conflictDiskText) {
        case (nil, _, _, _):
            .noNote
        case (let path?, true, _, _):
            .loading(path)
        case (let path?, false, let error?, _):
            .failed(path, error)
        case (let path?, false, nil, let diskText?):
            .conflict(Note(path: path, text: draft), diskText: diskText)
        case (let path?, false, nil, nil):
            .editing(Note(path: path, text: draft))
        }
    }

    public var saveStatus: SaveStatus {
        switch (saveError, draft == diskText) {
        case (let error?, _):
            .failed(error)
        case (nil, true):
            .saved
        case (nil, false):
            .unsaved
        }
    }

    public private(set) var path: NotePath?

    // MARK: - Private

    private let vault: VaultService
    private let links: LinkService?
    private let index: IndexService?
    private let saveDelay: Duration

    private var draft = "" {
        didSet {
            links?.openNoteChanged(path, text: draft)
        }
    }
    private var diskText = ""
    private var isLoading = false
    private var loadError: VaultError?
    private var conflictDiskText: String?
    private var saveError: VaultError?
    private var scheduledSave: Task<Void, Never>?
    private var runningSave: Task<Void, Never>?

    // MARK: - Init

    public init(
        vault: VaultService,
        links: LinkService? = nil,
        index: IndexService? = nil,
        saveDelay: Duration = .milliseconds(800)
    ) {
        self.vault = vault
        self.links = links
        self.index = index
        self.saveDelay = saveDelay
    }

    // MARK: - Intent

    public func open(_ newPath: NotePath) async {
        guard newPath != path || loadError != nil else {
            return
        }

        await flush()
        reset(to: newPath)
        isLoading = true

        guard let store = vault.store else {
            loadError = .noVaultOpen
            isLoading = false
            return
        }

        do {
            let text = try await store.readNote(at: newPath)
            guard path == newPath else {
                return
            }

            if let text {
                draft = text
                diskText = text
            } else {
                loadError = .notFound(newPath)
            }
        } catch {
            guard path == newPath else {
                return
            }

            loadError = error
        }

        isLoading = false
    }

    public func retry() async {
        guard let path, loadError != nil else {
            return
        }

        await open(path)
    }

    public func edit(_ text: String) {
        guard path != nil, isLoading == false, loadError == nil, text != draft else {
            return
        }

        draft = text
        saveError = nil
        scheduleSave()
    }

    public func flush() async {
        scheduledSave?.cancel()
        scheduledSave = nil
        await saveInOrder()
    }

    public func keepMyVersion() async {
        guard let path, conflictDiskText != nil, let store = vault.store else {
            return
        }

        conflictDiskText = nil
        await write(draft, to: path, store: store)
    }

    public func useVersionOnDisk() {
        guard let diskVersion = conflictDiskText else {
            return
        }

        draft = diskVersion
        diskText = diskVersion
        conflictDiskText = nil
        saveError = nil
    }

    public func reloadIfUnchanged(_ changed: Set<NotePath>) async {
        guard let path, changed.contains(path), isLoading == false, loadError == nil, let store = vault.store else {
            return
        }

        let onDisk: String?
        do {
            onDisk = try await store.readNote(at: path)
        } catch {
            AppLog.error("Reading \(path) after an outside change failed: \(error)")
            return
        }

        guard self.path == path, let onDisk, onDisk != diskText, draft == diskText, conflictDiskText == nil else {
            return
        }

        draft = onDisk
        diskText = onDisk
        saveError = nil
    }

    public func close() async {
        await flush()
        reset(to: nil)
    }

    // MARK: - Private

    private func reset(to newPath: NotePath?) {
        path = newPath
        draft = ""
        diskText = ""
        isLoading = false
        loadError = nil
        conflictDiskText = nil
        saveError = nil
    }

    private func scheduleSave() {
        scheduledSave?.cancel()
        scheduledSave = Task { [weak self, saveDelay] in
            do {
                try await Task.sleep(for: saveDelay)
            } catch {
                return
            }

            await self?.saveInOrder()
        }
    }

    private func saveInOrder() async {
        let previous = runningSave
        let task = Task { [weak self] in
            await previous?.value
            await self?.saveNow()
        }
        runningSave = task
        await task.value
    }

    private func saveNow() async {
        guard let path, let store = vault.store, isLoading == false, loadError == nil, conflictDiskText == nil else {
            return
        }

        let snapshot = draft
        let lastKnownDisk = diskText
        guard snapshot != lastKnownDisk else {
            return
        }

        let onDisk: String?
        do {
            onDisk = try await store.readNote(at: path)
        } catch {
            guard self.path == path else {
                return
            }

            saveError = error
            return
        }

        guard self.path == path else {
            return
        }

        switch NoteSaveDecisionUseCase.decide(lastKnownDisk: lastKnownDisk, draft: snapshot, onDisk: onDisk) {
        case .unchanged:
            return
        case .write,
             .recreate:
            await write(snapshot, to: path, store: store)
        case let .adoptDisk(text):
            diskText = text
        case let .conflict(text):
            conflictDiskText = text
        }
    }

    private func write(_ text: String, to path: NotePath, store: any VaultFileStoring) async {
        do {
            try await store.writeNote(text, at: path)
        } catch {
            guard self.path == path else {
                return
            }

            saveError = error
            return
        }

        guard self.path == path else {
            return
        }

        diskText = text
        saveError = nil
        links?.update(path, text: text)
        await index?.update([path])
    }
}
