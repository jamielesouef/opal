//
//  RecentVault.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation

public struct RecentVault: Hashable, Identifiable, Sendable {
    // MARK: - Stored

    public let record: RecentVaultRecord
    public let folderURL: URL
    public let isMissing: Bool

    // MARK: - Init

    public init(record: RecentVaultRecord, folderURL: URL, isMissing: Bool) {
        self.record = record
        self.folderURL = folderURL
        self.isMissing = isMissing
    }

    // MARK: - Derived

    public var id: String {
        RecentVaultsUseCase.key(for: record.path)
    }

    public var name: String {
        folderURL.lastPathComponent
    }

    public var parentPath: String {
        folderURL.deletingLastPathComponent().path
    }

    public var shortParentPath: String {
        FolderPathUseCase.short(parentPath, home: UserHome.path)
    }
}
