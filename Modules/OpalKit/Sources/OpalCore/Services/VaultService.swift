//
//  VaultService.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Observation

@MainActor
@Observable
public final class VaultService: SingleFlightRefreshing {
    // MARK: - State

    public enum LoadState: Hashable, Sendable {
        case closed(VaultError?)
        case opening
        case open(Vault)
    }

    public var loadState: LoadState {
        switch (isOpening, vault) {
        case (true, _):
            .opening
        case (false, let vault?):
            .open(vault)
        case (false, nil):
            .closed(error)
        }
    }

    public var isOpen: Bool {
        vault != nil && isOpening == false
    }

    public private(set) var tree: [VaultTreeNode] = []
    public private(set) var appSettings = ObsidianAppSettings.defaults
    public private(set) var store: (any VaultFileStoring)?

    // MARK: - SingleFlightRefreshing

    public var refreshTask: Task<Void, Never>?

    // MARK: - Private

    private let access: any VaultAccessGranting
    private let locations: any VaultLocationStoring
    private let launchVaultURL: URL?
    private let makeStore: @Sendable (URL) -> any VaultFileStoring

    private var vault: Vault?
    private var entries: [VaultEntry] = []
    private var kinds: [NotePath: VaultItemKind] = [:]
    private var isOpening = false
    private var error: VaultError?
    private var hasStarted = false
    private var accessedURL: URL?

    // MARK: - Init

    public init(
        access: any VaultAccessGranting,
        locations: any VaultLocationStoring,
        launchVaultURL: URL?,
        makeStore: @escaping @Sendable (URL) -> any VaultFileStoring
    ) {
        self.access = access
        self.locations = locations
        self.launchVaultURL = launchVaultURL
        self.makeStore = makeStore
    }

    // MARK: - Intent

    public func start() async {
        guard hasStarted == false else {
            return
        }

        hasStarted = true
        if let launchVaultURL {
            await openVault(at: launchVaultURL, remember: false)
        } else {
            await restoreLastVault()
        }
    }

    public func open(folderURL: URL) async {
        await openVault(at: folderURL, remember: true)
    }

    public func create(folderURL: URL) async {
        do {
            try access.createVaultFolder(at: folderURL)
        } catch {
            closeCurrentVault()
            self.error = error
            return
        }

        await openVault(at: folderURL, remember: true)
    }

    public func kind(of path: NotePath) -> VaultItemKind? {
        kinds[path]
    }

    public func url(for path: NotePath) -> URL? {
        store?.url(for: path)
    }

    public func createNote(openNote: NotePath?) async throws(VaultError) -> NotePath {
        guard let store else {
            throw .noVaultOpen
        }

        let folder = NewItemPlanUseCase.folderForNewNote(settings: appSettings, openNote: openNote)
        let path = NewItemPlanUseCase.newNotePath(in: folder, existing: Set(kinds.keys))
        try await store.createNote(at: path, text: "")
        insert(VaultEntry(path: path, kind: .note))
        return path
    }

    public func createFolder(near selection: NotePath?) async throws(VaultError) -> NotePath {
        guard let store else {
            throw .noVaultOpen
        }

        let parent = NewItemPlanUseCase.containingFolder(of: selection, kind: selection.flatMap { kinds[$0] })
        let path = NewItemPlanUseCase.newFolderPath(in: parent, existing: Set(kinds.keys))
        try await store.createFolder(at: path)
        insert(VaultEntry(path: path, kind: .folder))
        return path
    }

    // MARK: - SingleFlightRefreshing

    public func performRefresh() async {
        guard let store else {
            return
        }

        let listed: [VaultEntry]
        do {
            listed = try await store.listEntries()
        } catch {
            guard Task.isCancelled == false else {
                return
            }

            AppLog.error("Reloading the Vault failed: \(error)")
            return
        }

        guard Task.isCancelled == false else {
            return
        }

        apply(listed)
    }

    // MARK: - Private

    private func restoreLastVault() async {
        guard let bookmark = await locations.lastVaultBookmark() else {
            return
        }

        let resolved: ResolvedVaultBookmark
        do {
            resolved = try access.resolve(bookmark: bookmark)
        } catch {
            self.error = error
            return
        }

        await openVault(at: resolved.folderURL, remember: resolved.isStale)
    }

    private func openVault(at folderURL: URL, remember: Bool) async {
        refreshTask?.cancel()
        closeCurrentVault()
        isOpening = true
        error = nil

        if access.beginAccess(to: folderURL) {
            accessedURL = folderURL
        }

        if remember {
            do {
                try await locations.setLastVaultBookmark(access.bookmark(for: folderURL))
            } catch {
                AppLog.error("Could not remember the Vault: \(error)")
            }
        }

        let newStore = makeStore(folderURL)
        let listed: [VaultEntry]
        do {
            listed = try await newStore.listEntries()
        } catch {
            closeCurrentVault()
            self.error = error
            isOpening = false
            return
        }

        let settings = await ObsidianAppSettingsParser.parse(
            newStore.readObsidianSettings(named: ObsidianAppSettingsParser.fileName)
        )

        store = newStore
        appSettings = settings
        vault = Vault(rootURL: folderURL)
        apply(listed)
        isOpening = false
    }

    private func closeCurrentVault() {
        if let accessedURL {
            access.endAccess(to: accessedURL)
        }

        accessedURL = nil
        vault = nil
        store = nil
        appSettings = .defaults
        apply([])
    }

    private func insert(_ entry: VaultEntry) {
        apply(VaultTreeUseCase.entriesAddingAncestors(of: entry, to: entries))
    }

    private func apply(_ newEntries: [VaultEntry]) {
        entries = newEntries
        kinds = Dictionary(newEntries.map { ($0.path, $0.kind) }) { first, _ in first }
        tree = VaultTreeUseCase.tree(from: newEntries)
    }
}
