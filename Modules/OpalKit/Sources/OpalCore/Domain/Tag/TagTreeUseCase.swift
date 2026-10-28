//
//  TagTreeUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

public enum TagTreeUseCase {
    // MARK: - Tree

    public static func tree(from tagsByNote: [NotePath: [String]]) -> [TagNode] {
        var notesByTag: [String: Set<NotePath>] = [:]
        var spelling: [String: String] = [:]
        for (path, tags) in tagsByNote.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            for tag in tags {
                let parts = tag.split(separator: "/").map(String.init)
                for depth in parts.indices {
                    let full = parts[...depth].joined(separator: "/")
                    let key = full.lowercased()
                    notesByTag[key, default: []].insert(path)
                    spelling[key] = spelling[key] ?? full
                }
            }
        }
        return nodes(under: nil, notesByTag: notesByTag, spelling: spelling)
    }

    // MARK: - Query

    public static func searchQuery(for tag: TagNode) -> String {
        searchQuery(forTag: tag.fullName)
    }

    public static func searchQuery(forTag name: String) -> String {
        "tag:#\(name)"
    }

    // MARK: - Private

    private static func nodes(under parent: String?, notesByTag: [String: Set<NotePath>], spelling: [String: String]) -> [TagNode] {
        let depth = parent.map { $0.split(separator: "/").count + 1 } ?? 1
        return notesByTag.keys
            .filter { key in
                key.split(separator: "/").count == depth && (parent.map { key.hasPrefix($0 + "/") } ?? true)
            }
            .map { key in
                let full = spelling[key] ?? key
                let children = nodes(under: key, notesByTag: notesByTag, spelling: spelling)
                return TagNode(
                    name: full.split(separator: "/").last.map(String.init) ?? full,
                    fullName: full,
                    noteCount: notesByTag[key]?.count ?? 0,
                    children: children.isEmpty ? nil : children
                )
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
