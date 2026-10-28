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
        switch (saveError, isUnsaved == false) {
        case (let error?, _):
            .failed(error)
        case (nil, true):
            .saved
        case (nil, false):
            .unsaved
        }
    }

    public private(set) var path: NotePath?

    public var isReady: Bool {
        path != nil && isLoading == false && loadError == nil
    }

    // MARK: - Private

    private let vault: VaultService
    private let links: LinkService?
    private let index: IndexService?
    private let saveDelay: Duration

    public private(set) var revision = 0

    private var draft = "" {
        didSet {
            revision += 1
            isUnsaved = draft != diskText
            links?.openNoteChanged(path, text: draft)
        }
    }
    private var diskText = "" {
        didSet {
            isUnsaved = draft != diskText
        }
    }

    private var isUnsaved = false
    private var isLoading = false
    private var loadError: VaultError?
    private var conflictDiskText: String?
    private var saveError: VaultError?
    private var scheduledSave: Task<Void, Never>?
    private var runningSave: Task<Void, Never>?
    private let clock: any Clocking

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

    // MARK: - Properties

    public var frontmatter: Frontmatter? {
        guard let open = links?.openNote, open.path == path, open.textLength == draft.utf16.count else {
            return nil
        }

        return open.frontmatter
    }

    public func type(of property: Property) -> PropertyType {
        PropertyTypeUseCase.type(of: property, declared: vault.propertyTypes)
    }

    public func setProperty(_ property: Property, to value: PropertyValue) {
        guard let current = currentProperty(property.key) else {
            return
        }

        edit(PropertyEditUseCase.set(current, to: value, type: type(of: current), in: draft))
    }

    public func attach(_ data: Data, named fileName: String?) async -> String? {
        guard let path else {
            return nil
        }

        let name = fileName ?? AttachmentUseCase.pastedName(at: clock.now, timeZone: clock.timeZone)
        do {
            let attachment = try await vault.createAttachment(data, named: name, for: path)
            return AttachmentUseCase.embedText(for: attachment, from: path, existing: Set(vault.entries.map(\.path)), settings: vault.appSettings)
        } catch {
            AppLog.error("Saving the Attachment \(name) failed: \(error)")
            return nil
        }
    }

    public func toggleCheckbox(onLine line: Int) {
        guard let toggle = CheckboxToggleUseCase.toggle(onLine: line, in: draft) else {
            return
        }

        edit((draft as NSString).replacingCharacters(in: NSRange(location: toggle.span.location, length: toggle.span.length), with: toggle.replacement))
    }

    public func removeProperty(_ property: Property) {
        guard let current = currentProperty(property.key) else {
            return
        }

        edit(PropertyEditUseCase.remove(current, from: draft))
    }

    public func addProperty(named key: String) {
        let name = key.trimmingCharacters(in: .whitespaces)
        guard name.isEmpty == false else {
            return
        }

        let current = FrontmatterParser.parse(draft)
        guard current?.properties.contains(where: { $0.key == name }) != true else {
            return
        }

        edit(PropertyEditUseCase.add(key: name, type: vault.propertyTypes[name] ?? .text, to: draft, frontmatter: current))
    }

    private func currentProperty(_ key: String) -> Property? {
        FrontmatterParser.parse(draft)?.properties.first { $0.key == key }
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
        await links?.update(path, text: text)
        await index?.update([path])
    }
}
