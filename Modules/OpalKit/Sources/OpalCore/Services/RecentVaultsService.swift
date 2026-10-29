//
//  RecentVaultsService.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation
import Observation

@MainActor
@Observable
public final class RecentVaultsService {
    // MARK: - State

    public private(set) var vaults: [RecentVault] = []

    // MARK: - Private

    private let access: any VaultAccessGranting
    private let locations: any VaultLocationStoring

    // MARK: - Init

    public init(access: any VaultAccessGranting, locations: any VaultLocationStoring) {
        self.access = access
        self.locations = locations
    }

    // MARK: - Intent

    public func load() async {
        let stored = await locations.recentVaults()
        var seen = Set<String>()
        let resolved = stored.map(resolve).filter { seen.insert($0.id).inserted }
        let records = resolved.map(\.record)
        if records != stored {
            await locations.setRecentVaults(records)
        }

        vaults = resolved
    }

    public func record(_ folderURL: URL) async {
        let bookmark: Data
        do {
            bookmark = try access.bookmark(for: folderURL)
        } catch {
            AppLog.error("Could not remember the Vault in the recent list: \(error)")
            return
        }

        await load()
        let record = RecentVaultRecord(bookmark: bookmark, path: folderURL.path(percentEncoded: false))
        await locations.setRecentVaults(RecentVaultsUseCase.recording(record, in: vaults.map(\.record)))
        await load()
    }

    public func remove(_ vault: RecentVault) async {
        await locations.setRecentVaults(vaults.filter { $0.id != vault.id }.map(\.record))
        await load()
    }

    public func clear() async {
        await locations.setRecentVaults([])
        await load()
    }

    // MARK: - Private

    private func resolve(_ record: RecentVaultRecord) -> RecentVault {
        guard let resolved = try? access.resolve(bookmark: record.bookmark) else {
            return RecentVault(record: record, folderURL: URL(filePath: record.path, directoryHint: .isDirectory), isMissing: true)
        }

        var isFolder: ObjCBool = false
        let exists = FileManager().fileExists(atPath: resolved.folderURL.path(percentEncoded: false), isDirectory: &isFolder)
        let updated = RecentVaultRecord(bookmark: record.bookmark, path: resolved.folderURL.path(percentEncoded: false))
        return RecentVault(record: updated, folderURL: resolved.folderURL, isMissing: exists == false || isFolder.boolValue == false)
    }
}
