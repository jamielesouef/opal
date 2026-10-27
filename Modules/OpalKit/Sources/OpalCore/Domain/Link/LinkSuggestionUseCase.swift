//
//  LinkSuggestionUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

public enum LinkSuggestionUseCase {
    // MARK: - Constants

    public static let limit = 30

    private enum Constants {
        static let opener = "[["
        static let closer = "]]"
        static let stoppers: [Character] = ["|", "#", "^", "]", "\n"]
        static let noteSuffix = ".\(NotePath.noteExtension)"
    }

    // MARK: - Query

    public static func openQuery(in text: String, cursor: Int) -> LinkQuery? {
        let nsText = text as NSString
        guard cursor >= 0, cursor <= nsText.length else {
            return nil
        }

        let lineStart = nsText.lineRange(for: NSRange(location: cursor, length: 0)).location
        let before = nsText.substring(with: NSRange(location: lineStart, length: cursor - lineStart)) as NSString
        let opener = before.range(of: Constants.opener, options: .backwards)
        guard opener.location != NSNotFound else {
            return nil
        }

        let query = before.substring(from: opener.location + opener.length)
        guard query.contains(where: Constants.stoppers.contains) == false, query.hasPrefix(" ") == false else {
            return nil
        }

        return LinkQuery(
            bracketLocation: lineStart + opener.location,
            queryLocation: lineStart + opener.location + opener.length,
            text: query
        )
    }

    // MARK: - Suggestions

    public static func suggestions(
        for query: String,
        candidates: [SwitcherCandidate],
        unresolved: [String],
        recent: [NotePath],
        limit: Int = limit
    ) -> [LinkSuggestion] {
        let notes = QuickSwitcherMatchUseCase.matches(query: query, candidates: candidates, recent: recent, limit: limit)
            .map { LinkSuggestion.note($0.path, alias: $0.matchedAlias) }
        let needle = Array(query.lowercased().filter { $0.isWhitespace == false })
        let missing = unresolved
            .compactMap { name in QuickSwitcherMatchUseCase.fuzzyScore(needle, in: name).map { (name, $0) } }
            .sorted { $0.1 > $1.1 }
            .map { LinkSuggestion.unresolved($0.0) }
        return Array((notes + missing).prefix(limit))
    }

    // MARK: - Insertion

    public static func insertion(
        for suggestion: LinkSuggestion,
        from source: NotePath,
        resolver: LinkResolver,
        useMarkdownLinks: Bool
    ) -> String {
        switch suggestion {
        case let .note(path, alias):
            let target = shortestTarget(for: path, from: source, resolver: resolver)
            guard useMarkdownLinks else {
                let display = alias.map { "|\($0)" } ?? ""
                return Constants.opener + target + display + Constants.closer
            }
            return markdownLink(text: alias ?? path.name, target: path.isNote ? target + Constants.noteSuffix : target)
        case let .unresolved(name):
            guard useMarkdownLinks else {
                return Constants.opener + name + Constants.closer
            }
            return markdownLink(text: name, target: name + Constants.noteSuffix)
        }
    }

    public static func shortestTarget(for path: NotePath, from source: NotePath, resolver: LinkResolver) -> String {
        let name = path.isNote ? path.name : path.fileName
        if resolver.resolve(name, from: source) == path {
            return name
        }

        let raw = path.rawValue
        return path.isNote ? String(raw.dropLast(Constants.noteSuffix.count)) : raw
    }

    // MARK: - Private

    private static func markdownLink(text: String, target: String) -> String {
        let encoded = target.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed.subtracting(CharacterSet(charactersIn: "()"))) ?? target
        return "[\(text)](\(encoded))"
    }
}
