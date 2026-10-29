//
//  FolderPathUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation

public enum FolderPathUseCase {
    // MARK: - Constants

    public static let defaultLimit = 40

    // MARK: - Short

    public static func short(_ path: String, home: String, limit: Int = defaultLimit) -> String {
        let shown = abbreviated(path, home: home)
        let parts = shown.split(separator: "/").map(String.init)
        guard shown.count > limit, parts.count > 2 else {
            return shown
        }

        let head = (shown.hasPrefix("/") ? "/" : "") + parts[0] + "/…/"
        let kept = (1 ... parts.count - 2).reversed().first { head.count + parts.suffix($0).joined(separator: "/").count <= limit } ?? 1
        return head + parts.suffix(kept).joined(separator: "/")
    }

    // MARK: - Private

    private static func abbreviated(_ path: String, home: String) -> String {
        let root = home.count > 1 && home.hasSuffix("/") ? String(home.dropLast()) : home
        guard root.count > 1 else {
            return path
        }

        if path == root {
            return "~"
        }

        return path.hasPrefix(root + "/") ? "~" + path.dropFirst(root.count) : path
    }
}
