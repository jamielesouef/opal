//
//  VaultTreeNode.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct VaultTreeNode: Identifiable, Hashable, Sendable {
    // MARK: - Stored

    public let path: NotePath
    public let kind: VaultItemKind
    public let children: [VaultTreeNode]?

    // MARK: - Init

    public init(path: NotePath, kind: VaultItemKind, children: [VaultTreeNode]?) {
        self.path = path
        self.kind = kind
        self.children = children
    }

    // MARK: - Identifiable

    public var id: NotePath {
        path
    }

    // MARK: - Derived

    public var displayName: String {
        switch kind {
        case .note:
            path.name
        case .folder,
             .attachment:
            path.fileName
        }
    }
}
