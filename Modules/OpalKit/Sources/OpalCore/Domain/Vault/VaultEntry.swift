//
//  VaultEntry.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct VaultEntry: Hashable, Sendable {
    // MARK: - Stored

    public let path: NotePath
    public let kind: VaultItemKind

    // MARK: - Init

    public init(path: NotePath, kind: VaultItemKind) {
        self.path = path
        self.kind = kind
    }

    public init(path: NotePath, isFolder: Bool) {
        self.path = path
        kind = isFolder ? .folder : (path.isNote ? .note : .attachment)
    }
}
