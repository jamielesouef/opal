//
//  CommandMatchUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

public enum CommandMatchUseCase {
    // MARK: - Constants

    public static let recentLimit = 5

    // MARK: - Match

    public static func ordered(ids: [String], names: [String: String], query: String, recent: [String]) -> [String] {
        let needle = Array(query.lowercased().filter { $0.isWhitespace == false })
        let recentRank = Dictionary(recent.enumerated().map { ($1, $0) }) { first, _ in first }
        guard needle.isEmpty == false else {
            return ids.sorted { lhs, rhs in
                switch (recentRank[lhs], recentRank[rhs]) {
                case let (left?, right?):
                    left < right
                case (.some, nil):
                    true
                case (nil, .some):
                    false
                case (nil, nil):
                    ids.firstIndex(of: lhs) ?? 0 < ids.firstIndex(of: rhs) ?? 0
                }
            }
        }

        let scored = ids.compactMap { id -> (String, Int)? in
            guard let name = names[id], let score = QuickSwitcherMatchUseCase.fuzzyScore(needle, in: name) else {
                return nil
            }
            return (id, score + (recentRank[id].map { (recentLimit - $0) * 2 } ?? 0))
        }
        return scored.sorted { $0.1 > $1.1 }.map(\.0)
    }

    public static func recording(_ id: String, in recent: [String]) -> [String] {
        Array(([id] + recent.filter { $0 != id }).prefix(recentLimit))
    }
}
