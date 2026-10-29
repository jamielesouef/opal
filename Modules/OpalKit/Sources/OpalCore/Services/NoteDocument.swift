//
//  NoteDocument.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation
import Observation

@MainActor
@Observable
public final class NoteDocument {
    // MARK: - State

    public let path: NotePath

    public var loadState: NoteService.LoadState {
        switch (isLoading, loadError, conflictDiskText) {
        case (true, _, _):
            .loading(path)
        case (false, let error?, _):
            .failed(path, error)
        case (false, nil, let diskText?):
            .conflict(Note(path: path, text: draft), diskText: diskText)
        case (false, nil, nil):
            .editing(Note(path: path, text: draft))
        }
    }

    public var saveStatus: NoteService.SaveStatus {
        switch (saveError, isUnsaved == false) {
        case (let error?, _):
            .failed(error)
        case (nil, true):
            .saved
        case (nil, false):
            .unsaved
        }
    }

    public var isReady: Bool {
        isLoading == false && loadError == nil
    }

    public private(set) var revision = 0
    public private(set) var vaultPropertyTypes: [String: PropertyType]?

    // MARK: - Private

    private let vault: VaultService
    private let links: LinkService?
    private let index: IndexService?
    private let clock: any Clocking
    private let saveDelay: Duration

    private var draft = "" {
        didSet {
            revision += 1
            isUnsaved = draft != diskText
            links?.noteChanged(path, text: draft)
        }
    }

    private var diskText = "" {
        didSet {
            isUnsaved = draft != diskText
        }
    }

    private var isUnsaved = false
    private var isLoading = true
    private var loadError: VaultError?
    private var conflictDiskText: String?
    private var saveError: VaultError?
    private var scheduledSave: Task<Void, Never>?
    private var runningSave: Task<Void, Never>?

    // MARK: - Init

    init(path: NotePath, vault: VaultService, links: LinkService?, index: IndexService?, clock: any Clocking, saveDelay: Duration) {
        self.path = path
        self.vault = vault
        self.links = links
        self.index = index
        self.clock = clock
        self.saveDelay = saveDelay
    }

    // MARK: - Intent

    public func load() async {
        isLoading = true
        loadError = nil
        conflictDiskText = nil
        saveError = nil

        guard let store = vault.store else {
            loadError = .noVaultOpen
            isLoading = false
            return
        }

        do {
            if let text = try await store.readNote(at: path) {
                draft = text
                diskText = text
            } else {
                loadError = .notFound(path)
            }
        } catch {
            loadError = error
        }

        isLoading = false
    }

    public func retry() async {
        guard loadError != nil else {
            return
        }

        await load()
    }

    public func edit(_ text: String) {
        guard isReady, text != draft else {
            return
        }

        draft = text
        saveError = nil
        scheduleSave()
    }

    // MARK: - Properties

    public var frontmatter: Frontmatter? {
        guard let analysed = links?.analysis(of: path), analysed.textLength == draft.utf16.count else {
            return nil
        }

        return analysed.frontmatter
    }

    public func type(of property: Property) -> PropertyType {
        PropertyTypeUseCase.type(of: property, declared: vaultPropertyTypes ?? vault.propertyTypes)
    }

    public func refreshPropertyTypes() async {
        guard let index, index.loadState == .ready, let store = index.store else {
            vaultPropertyTypes = nil
            return
        }

        do {
            vaultPropertyTypes = try await store.propertyTypes(declared: vault.propertyTypes)
        } catch {
            AppLog.error("Reading the Property types failed: \(error)")
        }
    }

    public func setProperty(_ property: Property, to value: PropertyValue) {
        guard let current = currentProperty(property.key) else {
            return
        }

        edit(PropertyEditUseCase.set(current, to: value, type: type(of: current), in: draft))
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

        edit(PropertyEditUseCase.add(key: name, type: (vaultPropertyTypes ?? vault.propertyTypes)[name] ?? .text, to: draft, frontmatter: current))
    }

    // MARK: - Body

    public func attach(_ data: Data, named fileName: String?) async -> String? {
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

    // MARK: - Saving

    public func flush() async {
        scheduledSave?.cancel()
        scheduledSave = nil
        await saveInOrder()
    }

    public func keepMyVersion() async {
        guard conflictDiskText != nil, let store = vault.store else {
            return
        }

        conflictDiskText = nil
        await write(draft, store: store)
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

    public func reloadIfUnchanged() async {
        guard isReady, let store = vault.store else {
            return
        }

        let onDisk: String?
        do {
            onDisk = try await store.readNote(at: path)
        } catch {
            AppLog.error("Reading \(path) after an outside change failed: \(error)")
            return
        }

        guard let onDisk, onDisk != diskText, draft == diskText, conflictDiskText == nil else {
            return
        }

        draft = onDisk
        diskText = onDisk
        saveError = nil
    }

    // MARK: - Private

    private func currentProperty(_ key: String) -> Property? {
        FrontmatterParser.parse(draft)?.properties.first { $0.key == key }
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
        guard isReady, let store = vault.store, conflictDiskText == nil else {
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
            saveError = error
            return
        }

        switch NoteSaveDecisionUseCase.decide(lastKnownDisk: lastKnownDisk, draft: snapshot, onDisk: onDisk) {
        case .unchanged:
            return
        case .write,
             .recreate:
            await write(snapshot, store: store)
        case let .adoptDisk(text):
            diskText = text
        case let .conflict(text):
            conflictDiskText = text
        }
    }

    private func write(_ text: String, store: any VaultFileStoring) async {
        do {
            try await store.writeNote(text, at: path)
        } catch {
            saveError = error
            return
        }

        diskText = text
        saveError = nil
        await links?.update(path, text: text)
        await index?.update([path])
    }
}
