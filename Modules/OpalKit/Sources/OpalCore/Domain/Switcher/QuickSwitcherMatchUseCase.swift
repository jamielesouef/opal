//
//  QuickSwitcherMatchUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

public enum QuickSwitcherMatchUseCase {
    // MARK: - Constants

    public static let defaultLimit = 50
    public static let recentLimit = 20

    private enum Weight {
        static let match = 1
        static let consecutive = 5
        static let wordStart = 8
        static let namePrefix = 20
        static let exactName = 50
        static let nameFactor = 2
        static let aliasPenalty = 1
    }

    private static let separators: Set<Character> = [" ", "/", "-", "_", "."]

    // MARK: - Matches

    public static func matches(
        query: String,
        candidates: [SwitcherCandidate],
        recent: [NotePath],
        limit: Int = defaultLimit
    ) -> [SwitcherMatch] {
        let needle = Array(query.lowercased().filter { $0.isWhitespace == false })
        guard needle.isEmpty == false else {
            return recentFirst(candidates: candidates, recent: recent, limit: limit)
        }

        let recentRank = Dictionary(recent.enumerated().map { ($1, $0) }) { first, _ in first }
        return candidates
            .compactMap { match(needle, query: query.lowercased(), candidate: $0) }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score {
                    return lhs.score > rhs.score
                }
                let lhsRecent = recentRank[lhs.path] ?? Int.max
                let rhsRecent = recentRank[rhs.path] ?? Int.max
                if lhsRecent != rhsRecent {
                    return lhsRecent < rhsRecent
                }
                return lhs.path.name.localizedStandardCompare(rhs.path.name) == .orderedAscending
            }
            .prefix(limit)
            .map(\.self)
    }

    public static func recording(_ path: NotePath, in recent: [NotePath]) -> [NotePath] {
        Array(([path] + recent.filter { $0 != path }).prefix(recentLimit))
    }

    // MARK: - Fuzzy

    public static func fuzzyScore(_ needle: [Character], in text: String) -> Int? {
        let characters = Array(text.lowercased())
        var index = 0
        var score = 0
        var last = -2
        for (position, character) in characters.enumerated() where index < needle.count {
            guard character == needle[index] else {
                continue
            }

            score += Weight.match
            if position == last + 1 {
                score += Weight.consecutive
            }
            if position == 0 || separators.contains(characters[position - 1]) {
                score += Weight.wordStart
            }
            last = position
            index += 1
        }
        return index == needle.count ? score : nil
    }

    // MARK: - Private

    private static func match(_ needle: [Character], query: String, candidate: SwitcherCandidate) -> SwitcherMatch? {
        let path = candidate.path
        var best = fuzzyScore(needle, in: path.rawValue).map { SwitcherMatch(path: path, score: $0) }

        if let name = nameScore(needle, query: query, name: path.name), name > (best?.score ?? Int.min) {
            best = SwitcherMatch(path: path, score: name)
        }

        for alias in candidate.aliases {
            guard let score = nameScore(needle, query: query, name: alias).map({ $0 - Weight.aliasPenalty }),
                  score > (best?.score ?? Int.min)
            else {
                continue
            }
            best = SwitcherMatch(path: path, matchedAlias: alias, score: score)
        }
        return best
    }

    private static func nameScore(_ needle: [Character], query: String, name: String) -> Int? {
        guard let fuzzy = fuzzyScore(needle, in: name) else {
            return nil
        }

        let lower = name.lowercased()
        var score = fuzzy * Weight.nameFactor
        if lower.hasPrefix(query) {
            score += Weight.namePrefix
        }
        if lower == query {
            score += Weight.exactName
        }
        return score
    }

    private static func recentFirst(candidates: [SwitcherCandidate], recent: [NotePath], limit: Int) -> [SwitcherMatch] {
        let available = Set(candidates.map(\.path))
        let recentMatches = recent.filter(available.contains).map { SwitcherMatch(path: $0) }
        let recentSet = Set(recent)
        let rest = candidates
            .map(\.path)
            .filter { recentSet.contains($0) == false }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .map { SwitcherMatch(path: $0) }
        return Array((recentMatches + rest).prefix(limit))
    }
}
