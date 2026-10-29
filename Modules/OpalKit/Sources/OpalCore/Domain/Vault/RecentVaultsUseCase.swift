//
//  RecentVaultsUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation

public enum RecentVaultsUseCase {
    // MARK: - Constants

    public static let limit = 10

    // MARK: - Keys

    public static func key(for path: String) -> String {
        OpenVaultUseCase.normalized(URL(filePath: path, directoryHint: .isDirectory))
    }

    // MARK: - Recording

    public static func recording(_ record: RecentVaultRecord, in records: [RecentVaultRecord]) -> [RecentVaultRecord] {
        let key = key(for: record.path)
        return Array(([record] + records.filter { Self.key(for: $0.path) != key }).prefix(limit))
    }
}
