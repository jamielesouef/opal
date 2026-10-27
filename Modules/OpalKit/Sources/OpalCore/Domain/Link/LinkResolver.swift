//
//  LinkResolver.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

public struct LinkResolver: Sendable, Equatable {
    // MARK: - Constants

    private static let noteSuffix = ".\(NotePath.noteExtension)"

    // MARK: - Stored

    private let byPath: [String: NotePath]
    private let byName: [String: [NotePath]]
    private let byAlias: [String: [NotePath]]

    // MARK: - Init

    public init(paths: [NotePath], aliases: [NotePath: [String]]) {
        var byPath: [String: NotePath] = [:]
        var byName: [String: [NotePath]] = [:]
        var byAlias: [String: [NotePath]] = [:]
        for path in paths where path.isRoot == false {
            byPath[path.rawValue.lowercased()] = path
            byName[path.name.lowercased(), default: []].append(path)
        }

        for (path, names) in aliases {
            for alias in names {
                byAlias[alias.lowercased(), default: []].append(path)
            }
        }

        self.byPath = byPath
        self.byName = byName.mapValues(Self.preferredOrder)
        self.byAlias = byAlias.mapValues(Self.preferredOrder)
    }

    // MARK: - Resolve

    public func resolve(_ target: String, from source: NotePath) -> NotePath? {
        let trimmed = String(target.trimmingCharacters(in: .whitespaces).drop { $0 == "/" })
        guard trimmed.isEmpty == false else {
            return source
        }

        let lower = trimmed.lowercased()
        let withoutSuffix = lower.hasSuffix(Self.noteSuffix) ? String(lower.dropLast(Self.noteSuffix.count)) : lower

        if let exact = lookUpPath(lower) {
            return exact
        }

        if let relative = Self.relativePath(lower, from: source), let match = lookUpPath(relative) {
            return match
        }

        if let byName = nameMatch(lower, withoutSuffix: withoutSuffix) {
            return byName
        }

        guard lower.contains("/") == false else {
            return nil
        }

        return byAlias[lower]?.first
    }

    public func isResolved(_ link: Link, from source: NotePath) -> Bool {
        resolve(link.target, from: source) != nil
    }

    // MARK: - Private

    private func lookUpPath(_ lower: String) -> NotePath? {
        byPath[lower] ?? byPath[lower + Self.noteSuffix]
    }

    private func nameMatch(_ lower: String, withoutSuffix: String) -> NotePath? {
        let name = withoutSuffix.split(separator: "/").last.map(String.init) ?? withoutSuffix
        let fileName = lower.split(separator: "/").last.map(String.init) ?? lower
        let candidates = (byName[name] ?? []) + (name == fileName ? [] : byName[fileName] ?? [])
        guard withoutSuffix.contains("/") else {
            return candidates.first
        }

        return candidates.first { path in
            let raw = path.rawValue.lowercased()
            let rawWithoutSuffix = path.isNote ? String(raw.dropLast(Self.noteSuffix.count)) : raw
            return rawWithoutSuffix.hasSuffix("/" + withoutSuffix) || raw.hasSuffix("/" + lower)
        }
    }

    private static func relativePath(_ lower: String, from source: NotePath) -> String? {
        var components = source.parent.components.map { $0.lowercased() }
        for component in lower.split(separator: "/") {
            switch component {
            case ".":
                continue
            case "..":
                guard components.isEmpty == false else {
                    return nil
                }
                components.removeLast()
            default:
                components.append(String(component))
            }
        }
        return components.joined(separator: "/")
    }

    private static func preferredOrder(_ paths: [NotePath]) -> [NotePath] {
        paths.sorted { lhs, rhs in
            if lhs.components.count != rhs.components.count {
                return lhs.components.count < rhs.components.count
            }
            return lhs.rawValue.lowercased() < rhs.rawValue.lowercased()
        }
    }
}
