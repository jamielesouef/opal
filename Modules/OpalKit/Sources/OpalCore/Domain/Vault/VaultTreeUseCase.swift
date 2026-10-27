//
//  VaultTreeUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

public enum VaultTreeUseCase {
    // MARK: - Tree

    public static func tree(from entries: [VaultEntry]) -> [VaultTreeNode] {
        let visible = entries.filter { $0.path.isRoot == false && $0.path.isHidden == false }
        let byFolder = Dictionary(grouping: visible) { $0.path.parent }
        return nodes(in: .root, byFolder: byFolder)
    }

    // MARK: - Order

    public static func isOrderedBefore(_ lhs: VaultEntry, _ rhs: VaultEntry) -> Bool {
        switch (lhs.kind, rhs.kind) {
        case (.folder, .note),
             (.folder, .attachment):
            return true
        case (.note, .folder),
             (.attachment, .folder):
            return false
        case (.folder, .folder),
             (.note, .note),
             (.note, .attachment),
             (.attachment, .note),
             (.attachment, .attachment):
            return isNameOrderedBefore(lhs, rhs)
        }
    }

    // MARK: - Lookup

    public static func entriesAddingAncestors(of entry: VaultEntry, to entries: [VaultEntry]) -> [VaultEntry] {
        let known = Set(entries.map(\.path))
        var added: [VaultEntry] = []
        var folder = entry.path.parent
        while folder.isRoot == false {
            if known.contains(folder) == false {
                added.append(VaultEntry(path: folder, kind: .folder))
            }
            folder = folder.parent
        }

        guard known.contains(entry.path) == false else {
            return entries + added.reversed()
        }

        return entries + added.reversed() + [entry]
    }

    // MARK: - Private

    private static func nodes(in folder: NotePath, byFolder: [NotePath: [VaultEntry]]) -> [VaultTreeNode] {
        let entries = byFolder[folder] ?? []
        return entries.sorted(by: isOrderedBefore).map { entry in
            switch entry.kind {
            case .folder:
                VaultTreeNode(path: entry.path, kind: .folder, children: nodes(in: entry.path, byFolder: byFolder))
            case .note,
                 .attachment:
                VaultTreeNode(path: entry.path, kind: entry.kind, children: nil)
            }
        }
    }

    private static func isNameOrderedBefore(_ lhs: VaultEntry, _ rhs: VaultEntry) -> Bool {
        let options: String.CompareOptions = [.caseInsensitive, .numeric]
        switch displayName(of: lhs).compare(displayName(of: rhs), options: options, range: nil, locale: nil) {
        case .orderedAscending:
            return true
        case .orderedDescending:
            return false
        case .orderedSame:
            return lhs.path.rawValue < rhs.path.rawValue
        }
    }

    private static func displayName(of entry: VaultEntry) -> String {
        VaultTreeNode(path: entry.path, kind: entry.kind, children: nil).displayName
    }
}
